-- ============================================================
-- VAGAS POR POSTO — VERSÃO CORRIGIDA E SEGURA
-- ============================================================
-- Foco: impedir que pacientes ultrapassem o limite de um posto.
--
-- Diferenças importantes em relação ao script anterior:
-- 1) A vaga é validada ANTES de gravar o paciente.
-- 2) A linha do posto é bloqueada com FOR UPDATE; duas inscrições
--    simultâneas não conseguem consumir a mesma última vaga.
-- 3) O posto é fechado de forma atómica ao ocupar a última vaga.
-- 4) Posto inactivo, limite zero, posto inexistente e limite atingido
--    são rejeitados sem criar um paciente.
-- 5) Também cobre UPDATE que coloque um paciente em 'aguardando' ou
--    que o mova para outra unidade.
-- 6) A função é SECURITY DEFINER porque o site insere como anon e a
--    política RLS permite apenas SELECT em postos, não UPDATE.
--
-- Execute este ficheiro no SQL Editor do Supabase como proprietário do
-- projecto. Faça backup/export antes de aplicar em produção.
-- ============================================================

-- 1. Coluna de capacidade por posto
ALTER TABLE public.postos
    ADD COLUMN IF NOT EXISTS vagas_limite INTEGER DEFAULT NULL;

-- 2. Regra transaccional de consumo de vaga
CREATE OR REPLACE FUNCTION public.verificar_vagas_posto()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_nome_posto TEXT;
    v_posto_id UUID;
    v_ativo BOOLEAN;
    v_limite INTEGER;
    v_postos_encontrados INTEGER;
    v_inscritos INTEGER;
    v_deve_ocupar_vaga BOOLEAN := false;
BEGIN
    -- A vaga só é consumida quando uma linha nova entra na fila ou
    -- quando uma linha existente passa a ocupar uma vaga.
    IF NEW.status = 'aguardando' THEN
        IF TG_OP = 'INSERT' THEN
            v_deve_ocupar_vaga := true;
        ELSIF TG_OP = 'UPDATE'
              AND (OLD.status IS DISTINCT FROM 'aguardando'
                   OR btrim(COALESCE(OLD.unidade_preferencia, '')) IS DISTINCT FROM v_nome_posto) THEN
            v_deve_ocupar_vaga := true;
        END IF;
    END IF;

    IF NOT v_deve_ocupar_vaga THEN
        RETURN NEW;
    END IF;

    -- Normaliza espaços laterais somente quando a operação vai consumir
    -- uma vaga; actualizações que retiram alguém da fila não precisam de
    -- uma unidade válida para passar por este trigger.
    v_nome_posto := NULLIF(btrim(NEW.unidade_preferencia), '');

    IF v_nome_posto IS NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'POSTO_NAO_INFORMADO',
            DETAIL = 'A unidade de preferência é obrigatória.';
    END IF;

    -- O lock é a parte essencial da correcção: a segunda inscrição
    -- espera a primeira terminar antes de contar os inscritos.
    SELECT COUNT(*)
      INTO v_postos_encontrados
      FROM public.postos
     WHERE btrim(nome) = v_nome_posto;

    IF v_postos_encontrados = 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'POSTO_NAO_ENCONTRADO',
            DETAIL = format('Nenhum posto corresponde a: %s', v_nome_posto);
    ELSIF v_postos_encontrados > 1 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'POSTO_DUPLICADO',
            DETAIL = format('Mais de um posto corresponde a: %s', v_nome_posto);
    END IF;

    SELECT id, ativo, vagas_limite
      INTO v_posto_id, v_ativo, v_limite
      FROM public.postos
     WHERE btrim(nome) = v_nome_posto
     FOR UPDATE;

    -- Guarda o nome normalizado no registo novo/actualizado.
    NEW.unidade_preferencia := v_nome_posto;

    IF v_ativo IS DISTINCT FROM true THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'POSTO_FECHADO',
            DETAIL = format('O posto %s está fechado para novos cadastros.', v_nome_posto);
    END IF;

    IF v_limite IS NOT NULL AND v_limite < 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'LIMITE_INVALIDO',
            DETAIL = format('O posto %s tem vagas_limite negativo.', v_nome_posto);
    END IF;

    -- NULL significa sem limite. Zero significa fechado/sem vagas.
    IF v_limite IS NOT NULL THEN
        SELECT COUNT(*)
          INTO v_inscritos
          FROM public.pacientes
         WHERE btrim(unidade_preferencia) = v_nome_posto
           AND status = 'aguardando';

        IF v_inscritos >= v_limite THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P0001',
                MESSAGE = 'POSTO_SEM_VAGAS',
                DETAIL = format('O posto %s já atingiu o limite de %s vaga(s).', v_nome_posto, v_limite);
        END IF;

        -- Fecha no mesmo transaction em que a última vaga é ocupada.
        -- Se outro campo do insert falhar, esta alteração também sofre
        -- rollback e o posto não fica fechado indevidamente.
        IF v_inscritos + 1 >= v_limite THEN
            UPDATE public.postos
               SET ativo = false
             WHERE id = v_posto_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- 3. Substituir o trigger AFTER INSERT antigo por uma validação BEFORE.
DROP TRIGGER IF EXISTS trg_verificar_vagas_posto ON public.pacientes;

CREATE TRIGGER trg_verificar_vagas_posto
    BEFORE INSERT OR UPDATE OF status, unidade_preferencia
    ON public.pacientes
    FOR EACH ROW
    EXECUTE FUNCTION public.verificar_vagas_posto();

-- 4. Reparar o estado dos postos que já ficaram lotados/ultrapassados
--    enquanto o trigger antigo estava activo. Esta operação só altera
--    postos para false; não apaga nem modifica pacientes.
UPDATE public.postos AS p
   SET ativo = false
 WHERE p.ativo = true
   AND p.vagas_limite IS NOT NULL
   AND p.vagas_limite >= 0
   AND (
       SELECT COUNT(*)
         FROM public.pacientes AS pac
        WHERE btrim(pac.unidade_preferencia) = btrim(p.nome)
          AND pac.status = 'aguardando'
   ) >= p.vagas_limite;

-- 5. View com a mesma contagem usada pela regra de inserção.
-- A coluna vagas_disponiveis é exposta como valor calculado para
-- compatibilidade com o painel do Supabase. Ela não deve ser editada
-- manualmente: a fonte de verdade é vagas_limite menos a contagem real.
CREATE OR REPLACE VIEW public.situacao_postos AS
SELECT
    p.id,
    p.nome,
    p.ativo,
    p.vagas_limite,
    COUNT(pac.id) FILTER (WHERE pac.status = 'aguardando') AS inscritos_aguardando,
    CASE
        WHEN p.vagas_limite IS NULL THEN NULL
        ELSE GREATEST(
            0,
            p.vagas_limite - COUNT(pac.id) FILTER (WHERE pac.status = 'aguardando')
        )
    END AS vagas_restantes,
    CASE
        WHEN p.vagas_limite IS NULL THEN NULL
        ELSE GREATEST(
            0,
            p.vagas_limite - COUNT(pac.id) FILTER (WHERE pac.status = 'aguardando')
        )
    END AS vagas_disponiveis
FROM public.postos AS p
LEFT JOIN public.pacientes AS pac
       ON btrim(pac.unidade_preferencia) = btrim(p.nome)
GROUP BY p.id, p.nome, p.ativo, p.vagas_limite
ORDER BY p.nome;

-- O cadastro público lê apenas esta view agregada, nunca precisa de
-- descarregar todos os pacientes para calcular a disponibilidade.
GRANT SELECT ON public.situacao_postos TO anon, authenticated;

-- 6. Reabrir postos que estão fechados mas têm vagas_disponiveis > 0
--    na coluna manual. Isto actualiza a coluna para reflectir a contagem
--    real e reabre o posto se ainda houver vagas.
UPDATE public.postos AS p
   SET vagas_disponiveis = GREATEST(0, COALESCE(p.vagas_limite, 0) - (
       SELECT COUNT(*)
         FROM public.pacientes AS pac
        WHERE btrim(pac.unidade_preferencia) = btrim(p.nome)
          AND pac.status = 'aguardando'
   )),
       ativo = CASE
           WHEN p.vagas_limite IS NULL THEN true
           WHEN GREATEST(0, COALESCE(p.vagas_limite, 0) - (
               SELECT COUNT(*)
                 FROM public.pacientes AS pac
                WHERE btrim(pac.unidade_preferencia) = btrim(p.nome)
                  AND pac.status = 'aguardando'
           )) > 0 THEN true
           ELSE false
       END
 WHERE p.ativo = false
   AND p.vagas_limite IS NOT NULL
   AND p.vagas_limite > 0;

-- 7. Reabertura administrativa.
--    Esta função reabre o posto e pode substituir o limite. Ela NÃO
--    apaga a fila antiga nem inicia uma rodada sozinha. Para iniciar uma
--    nova rodada, os pacientes antigos devem ser arquivados/encerrados
--    por uma operação administrativa definida para o projecto.
CREATE OR REPLACE FUNCTION public.reabrir_posto(
    p_nome TEXT,
    p_novo_limite INTEGER DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NULLIF(btrim(p_nome), '') IS NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'POSTO_NAO_INFORMADO';
    END IF;

    IF p_novo_limite IS NOT NULL AND p_novo_limite < 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'LIMITE_INVALIDO';
    END IF;

    UPDATE public.postos
       SET ativo = true,
           vagas_limite = COALESCE(p_novo_limite, vagas_limite)
     WHERE btrim(nome) = btrim(p_nome);

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'POSTO_NAO_ENCONTRADO';
    END IF;
END;
$$;

-- Evita que qualquer pessoa reabra postos pela API anon.
REVOKE ALL ON FUNCTION public.reabrir_posto(TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reabrir_posto(TEXT, INTEGER) TO service_role;

-- ============================================================
-- COMO USAR
-- ============================================================
-- 1. Aplicar este script no SQL Editor do Supabase.
-- 2. Configurar limites, por exemplo:
--    UPDATE public.postos SET vagas_limite = 50 WHERE nome = 'Alecrim';
-- 3. Verificar o estado:
--    SELECT * FROM public.situacao_postos;
-- 4. Reabrir administrativamente, mantendo o limite actual:
--    SELECT public.reabrir_posto('Alecrim');
-- 5. Reabrir com novo limite:
--    SELECT public.reabrir_posto('Alecrim', 60);
-- ============================================================
