-- MIGRAÇÃO DA FILA NORMAL (rodada e cota sem ACS)
-- Pré-requisitos: cadastros_abertos=false; backup/clone verificados;
-- percentual_sem_acs configurado (20/25). Não altera status/posição de ninguém.
-- vagas_disponiveis continua sendo a única fonte do saldo atual.
BEGIN;

ALTER TABLE public.postos
  ADD COLUMN IF NOT EXISTS rodada_id uuid,
  ADD COLUMN IF NOT EXISTS rodada_capacidade integer;
ALTER TABLE public.pacientes
  ADD COLUMN IF NOT EXISTS rodada_vaga_id uuid;
-- Marco conservador: a rodada gerenciada começa AGORA, com as vagas que
-- ainda restam. Não atribuir rodada a pacientes antigos sem evidência.
UPDATE public.postos
   SET rodada_id = COALESCE(rodada_id, gen_random_uuid()),
       rodada_capacidade = COALESCE(rodada_capacidade, vagas_disponiveis)
 WHERE rodada_id IS NULL OR rodada_capacidade IS NULL;
ALTER TABLE public.postos ALTER COLUMN rodada_id SET DEFAULT gen_random_uuid();
ALTER TABLE public.postos ALTER COLUMN rodada_id SET NOT NULL;
ALTER TABLE public.postos ALTER COLUMN rodada_capacidade SET DEFAULT 0;
ALTER TABLE public.postos ALTER COLUMN rodada_capacidade SET NOT NULL;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.postos'::regclass AND conname='postos_rodada_capacidade_nao_negativa') THEN
    ALTER TABLE public.postos ADD CONSTRAINT postos_rodada_capacidade_nao_negativa CHECK (rodada_capacidade >= 0);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_pacientes_rodada_acs
 ON public.pacientes(rodada_vaga_id, unidade_preferencia)
 WHERE status='aguardando' AND sem_acs IS TRUE;

-- A mesma regra de locks serve inserção, saída, reentrada e transferência.
-- Um único trigger substitui os três anteriores; o evento e o contador
-- mudam na MESMA transação. INSERT não aguardando não consome vaga.
CREATE OR REPLACE FUNCTION public.gerenciar_fila_rodada()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
  v_old_unit text;
  v_new_unit text;
  v_old_aguardando boolean := false;
  v_old_id uuid;
  v_old_sem_acs boolean := false;
  v_old_rodada uuid;
  v_new_aguardando boolean;
  v_old_posto_id uuid;
  v_old_posto_rodada uuid;
  v_new_posto record;
  v_houve_saida boolean := false;
  v_houve_entrada boolean := false;
  v_quantidade_sem_acs integer;
  v_max_sem_acs integer;
  v_ultima_posicao integer;
  v_lock record;
BEGIN
  v_new_aguardando := NEW.status = 'aguardando';
  v_new_unit := NEW.unidade_preferencia;
  IF TG_OP = 'UPDATE' THEN
    v_old_unit := OLD.unidade_preferencia;
    v_old_id := OLD.id;
    v_old_sem_acs := COALESCE(OLD.sem_acs,false);
    v_old_rodada := OLD.rodada_vaga_id;
    v_old_aguardando := OLD.status = 'aguardando';
    -- Somente ACS mudou na mesma fila: validar a cota, mas não mover nem
    -- debitar uma vaga novamente.
    IF v_old_aguardando AND v_new_aguardando AND
       v_old_unit IS NOT DISTINCT FROM v_new_unit AND
       OLD.sem_acs IS NOT DISTINCT FROM NEW.sem_acs THEN
      RETURN NEW;
    END IF;
  END IF;

  v_houve_saida := v_old_aguardando AND
      (NOT v_new_aguardando OR v_old_unit IS DISTINCT FROM v_new_unit);
  v_houve_entrada := v_new_aguardando AND
      (TG_OP = 'INSERT' OR NOT v_old_aguardando OR
       v_old_unit IS DISTINCT FROM v_new_unit);

  -- Ordem CANÔNICA, antes de qualquer lock de posto ou UPDATE de posição.
  FOR v_lock IN
    SELECT DISTINCT k FROM (
      SELECT hashtext(v_old_unit) AS k WHERE v_old_aguardando
      UNION ALL
      SELECT hashtext(v_new_unit) AS k WHERE v_new_aguardando
    ) s ORDER BY k
  LOOP
    PERFORM pg_catalog.pg_advisory_xact_lock(104201, v_lock.k);
  END LOOP;

  -- Travar todos os postos relevantes em ordem única. Unidades históricas
  -- sem posto podem ser origem, mas nunca destino de nova inscrição.
  PERFORM 1 FROM public.postos
   WHERE nome IN (v_old_unit, v_new_unit)
   ORDER BY nome FOR UPDATE;
  IF v_old_aguardando THEN
    SELECT id,rodada_id INTO v_old_posto_id,v_old_posto_rodada
      FROM public.postos WHERE nome=v_old_unit;
  END IF;
  IF v_houve_entrada OR
      (v_old_aguardando AND v_new_aguardando AND
       v_old_unit IS NOT DISTINCT FROM v_new_unit AND
       NOT v_old_sem_acs AND COALESCE(NEW.sem_acs,false)) THEN
    SELECT id,nome,ativo,vagas_disponiveis,rodada_id,rodada_capacidade,
           percentual_sem_acs INTO v_new_posto
      FROM public.postos WHERE nome=v_new_unit;
    IF NOT FOUND THEN RAISE EXCEPTION 'POSTO_NAO_ENCONTRADO'; END IF;
  END IF;

  -- Regras do destino ANTES de liberar a origem (erro deve ser atômico).
  IF v_houve_entrada THEN
    IF NOT v_new_posto.ativo THEN RAISE EXCEPTION 'POSTO_FECHADO'; END IF;
    IF v_new_posto.vagas_disponiveis <= 0 THEN RAISE EXCEPTION 'POSTO_SEM_VAGAS'; END IF;
  END IF;
  IF v_new_aguardando AND COALESCE(NEW.sem_acs,false) AND
       (v_houve_entrada OR
        (v_old_aguardando AND v_old_unit IS NOT DISTINCT FROM v_new_unit AND
         NOT v_old_sem_acs AND v_old_rodada IS NOT DISTINCT FROM v_new_posto.rodada_id)) THEN
    IF v_new_posto.percentual_sem_acs IS NULL OR
       v_new_posto.percentual_sem_acs NOT BETWEEN 0 AND 100 THEN
      RAISE EXCEPTION 'COTA_SEM_ACS_NAO_CONFIGURADA';
    END IF;
    v_max_sem_acs := CASE WHEN v_new_posto.rodada_capacidade > 0 THEN
      GREATEST(1,FLOOR(v_new_posto.rodada_capacidade::numeric *
                       v_new_posto.percentual_sem_acs / 100)::integer)
      ELSE 0 END;
    SELECT count(*) INTO v_quantidade_sem_acs FROM public.pacientes p
      WHERE p.unidade_preferencia=v_new_unit
        AND p.rodada_vaga_id=v_new_posto.rodada_id
        AND p.sem_acs IS TRUE AND p.status='aguardando'
        AND (v_old_id IS NULL OR p.id<>v_old_id);
    IF v_quantidade_sem_acs >= v_max_sem_acs THEN
      RAISE EXCEPTION 'COTA_SEM_ACS_ESGOTADA';
    END IF;
  END IF;

  IF v_houve_saida THEN
    IF OLD.posicao_fila IS NOT NULL THEN
      UPDATE public.pacientes
         SET posicao_fila=posicao_fila-1
       WHERE unidade_preferencia=v_old_unit AND status='aguardando'
         AND id<>OLD.id AND posicao_fila>OLD.posicao_fila;
    END IF;
    -- Só devolve uma vaga consumida NA rodada que o posto ainda opera.
    IF v_old_posto_id IS NOT NULL AND
       v_old_rodada IS NOT DISTINCT FROM v_old_posto_rodada AND
       v_old_rodada IS NOT NULL THEN
      UPDATE public.postos SET vagas_disponiveis=vagas_disponiveis+1,
          ativo=true WHERE id=v_old_posto_id;
    END IF;
    NEW.posicao_fila := NULL;
    NEW.rodada_vaga_id := NULL;
  END IF;

  IF v_houve_entrada THEN
    SELECT COALESCE(MAX(posicao_fila),0) INTO v_ultima_posicao
      FROM public.pacientes
     WHERE unidade_preferencia=v_new_unit AND status='aguardando'
       AND (v_old_id IS NULL OR id<>v_old_id);
    NEW.posicao_fila := v_ultima_posicao+1;
    NEW.rodada_vaga_id := v_new_posto.rodada_id;
    NEW.submitted_at := COALESCE(NEW.submitted_at,now());
    UPDATE public.postos SET vagas_disponiveis=vagas_disponiveis-1,
           ativo=(vagas_disponiveis-1>0)
     WHERE id=v_new_posto.id;
  ELSIF TG_OP='INSERT' AND NOT v_new_aguardando THEN
    NEW.rodada_vaga_id:=NULL;
  END IF;
  RETURN NEW;
END;
$$;

-- Antes de trocar triggers, criar a RPC read-only compatível com o frontend.
CREATE OR REPLACE FUNCTION public.verificar_cota_sem_acs(p_unidade text)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE p record; v_usadas integer; v_max integer;
BEGIN
  SELECT nome,ativo,vagas_disponiveis,rodada_id,rodada_capacidade,
         percentual_sem_acs INTO p FROM public.postos WHERE nome=p_unidade;
  IF NOT FOUND OR NOT p.ativo OR p.vagas_disponiveis<=0 THEN
    RETURN json_build_object('disponivel',false,'motivo','Posto não encontrado, inativo ou sem vagas');
  END IF;
  IF p.percentual_sem_acs IS NULL OR p.percentual_sem_acs NOT BETWEEN 0 AND 100 THEN
    RETURN json_build_object('disponivel',false,'motivo','Cota sem ACS não configurada');
  END IF;
  v_max:=CASE WHEN p.rodada_capacidade>0 THEN
    GREATEST(1,FLOOR(p.rodada_capacidade::numeric*p.percentual_sem_acs/100)::integer)
    ELSE 0 END;
  SELECT count(*) INTO v_usadas FROM public.pacientes
    WHERE unidade_preferencia=p_unidade AND rodada_vaga_id=p.rodada_id
      AND sem_acs IS TRUE AND status='aguardando';
  RETURN json_build_object('disponivel',v_usadas<v_max,
     'max_sem_acs',v_max,'atual_sem_acs',v_usadas,
     'vagas_restantes_sem_acs',GREATEST(0,v_max-v_usadas));
END;
$$;

-- Remover os três gatilhos antigos somente depois de criar as funções acima;
-- transação única: nenhum cadastro observa regras parciais.
DROP TRIGGER IF EXISTS trg_atribuir_posicao ON public.pacientes;
DROP TRIGGER IF EXISTS trg_atualizar_vagas_disponiveis ON public.pacientes;
DROP TRIGGER IF EXISTS trg_processar_agendamento ON public.pacientes;
DROP TRIGGER IF EXISTS trg_gerenciar_fila_rodada ON public.pacientes;
CREATE TRIGGER trg_gerenciar_fila_rodada
 BEFORE INSERT OR UPDATE OF status,unidade_preferencia,sem_acs
 ON public.pacientes FOR EACH ROW EXECUTE FUNCTION public.gerenciar_fila_rodada();

-- Iniciar rodada explicitamente quando responsável abrir MAIS vagas. Não
-- usar reabrir_posto (legado: altera vagas_limite e não reinicia rodada).
CREATE OR REPLACE FUNCTION public.iniciar_rodada_posto(
    p_nome text, p_vagas integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
BEGIN
  IF p_vagas IS NULL OR p_vagas<1 THEN RAISE EXCEPTION 'VAGAS_INVALIDAS'; END IF;
  UPDATE public.postos SET vagas_disponiveis=p_vagas,
    rodada_capacidade=p_vagas,rodada_id=gen_random_uuid(),ativo=true
  WHERE nome=p_nome;
  IF NOT FOUND THEN RAISE EXCEPTION 'POSTO_NAO_ENCONTRADO'; END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.iniciar_rodada_posto(text,integer)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iniciar_rodada_posto(text,integer)
 TO service_role;
COMMIT;

-- IMPORTANTES LIMITES: manual UPDATE posicao_fila e edição em lote do mesmo
-- posto exigem testes/operacional separado. A migration não renumera passado.
