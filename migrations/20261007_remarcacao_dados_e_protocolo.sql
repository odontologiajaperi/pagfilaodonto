-- APLICADA via migração Supabase em 07/10/2026 após backup prioritário e testes locais; preserva pedidos anteriores.
-- Base histórica: remarcacoes.sql V2 + .github/sql/documentos_remarcacao.sql.
-- Etapa 1: somente schema e NOVA assinatura pública; preserva a antiga durante transição.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE public.solicitacoes_remarcacao
  ADD COLUMN IF NOT EXISTS protocolo text,
  ADD COLUMN IF NOT EXISTS data_consulta_informada date,
  ADD COLUMN IF NOT EXISTS unidade_informada text,
  ADD COLUMN IF NOT EXISTS divergencia_dados boolean,
  ADD COLUMN IF NOT EXISTS motivo_divergencia text,
  ADD COLUMN IF NOT EXISTS unidade_cadastro_encontrada text,
  ADD COLUMN IF NOT EXISTS data_consulta_cadastro_encontrada date,
  ADD COLUMN IF NOT EXISTS status_cadastro_encontrado text;
-- NULL em pedidos legados é intencional: não inventar datas, unidades ou protocolos retroativos.
CREATE UNIQUE INDEX IF NOT EXISTS solicitacoes_remarcacao_protocolo_uq
  ON public.solicitacoes_remarcacao (protocolo);
-- Barrar duplicatas mesmo em CPFs legados formatados. Se já houver pendências
-- duplicadas, criação falha com segurança: resolver caso a caso antes de aplicar.
CREATE UNIQUE INDEX IF NOT EXISTS solicitacoes_remarcacao_cpf_pendente_uq
  ON public.solicitacoes_remarcacao
  ((regexp_replace(coalesce(cpf, ''), '[^0-9]', '', 'g')))
  WHERE status_solicitacao = 'pendente';

CREATE OR REPLACE FUNCTION public.remarcacao_gerar_protocolo()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.id IS NULL THEN NEW.id := gen_random_uuid(); END IF;
  -- UUID inteiro torna o protocolo determinístico/único para cada ID, sem truncamento aleatório.
  NEW.protocolo := 'REM-' || to_char(clock_timestamp() AT TIME ZONE 'America/Sao_Paulo', 'YYYYMMDD')
    || '-' || upper(replace(NEW.id::text, '-', ''));
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_remarcacao_gerar_protocolo ON public.solicitacoes_remarcacao;
CREATE TRIGGER trg_remarcacao_gerar_protocolo BEFORE INSERT ON public.solicitacoes_remarcacao
FOR EACH ROW EXECUTE FUNCTION public.remarcacao_gerar_protocolo();
REVOKE ALL ON FUNCTION public.remarcacao_gerar_protocolo() FROM PUBLIC, anon, authenticated;

-- Assinatura exata do frontend: p_motivo NÃO recebe DEFAULT (evita ambiguidade de overload).
-- SECURITY DEFINER: proprietário deve ser papel confiável com acesso mínimo; revisar RLS e owner.
CREATE OR REPLACE FUNCTION public.solicitar_remarcacao(
  p_cpf text, p_email_contato text, p_telefone_contato text, p_motivo text,
  p_data_consulta_informada date, p_unidade_informada text
) RETURNS json LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' SET timezone = 'America/Sao_Paulo' AS $$
DECLARE
  v_cpf text := regexp_replace(coalesce(p_cpf, ''), '[^0-9]', '', 'g');
  v_email text := lower(btrim(coalesce(p_email_contato, '')));
  v_telefone text := regexp_replace(coalesce(p_telefone_contato, ''), '[^0-9]', '', 'g');
  v_unidade text := btrim(coalesce(p_unidade_informada, ''));
  v_motivo text := btrim(coalesce(p_motivo, ''));
  v_qtd integer;
  v_qtd_matches integer;
  v_p public.pacientes%ROWTYPE;
  v_tipo text := 'cpf_nao_localizado';
  v_prazo text := 'cadastro_nao_localizado';
  v_div boolean := true;
  v_reason text := 'cpf_nao_localizado';
  v_id uuid;
  v_protocolo text;
BEGIN
  IF length(v_cpf) <> 11 OR v_cpf !~ '^[0-9]{11}$' THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Informe um CPF com 11 dígitos.');
  END IF;
  IF length(v_email) > 254 OR v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Informe um e-mail de contato válido.');
  END IF;
  IF length(v_telefone) < 10 OR length(v_telefone) > 13 THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Informe um telefone de contato válido, com DDD.');
  END IF;
  IF p_data_consulta_informada IS NULL OR p_data_consulta_informada NOT BETWEEN DATE '1900-01-01' AND (CURRENT_DATE + 3650) THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Informe uma data de consulta válida.');
  END IF;
  IF length(v_unidade) < 2 OR length(v_unidade) > 160 OR v_unidade ~ '[[:cntrl:]]' THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Informe a unidade agendada (2 a 160 caracteres).');
  END IF;
  IF length(v_motivo) < 3 OR length(v_motivo) > 2000 THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Informe o motivo (3 a 2000 caracteres).');
  END IF;

  -- Advisory lock serializa inclusive CPF não localizado; índice parcial é barreira final
  -- para concorrência e serve também contra a antiga RPC enquanto coexistirem.
  PERFORM pg_advisory_xact_lock(hashtextextended('remarcacao:' || v_cpf, 0));
  IF EXISTS (SELECT 1 FROM public.solicitacoes_remarcacao s
             WHERE regexp_replace(coalesce(s.cpf, ''), '[^0-9]', '', 'g') = v_cpf
               AND s.status_solicitacao = 'pendente') THEN
    RETURN json_build_object('sucesso', false, 'mensagem', 'Já existe uma solicitação em análise para este CPF.');
  END IF;

  SELECT count(*) INTO v_qtd FROM public.pacientes p
  WHERE regexp_replace(coalesce(p.cpf, ''), '[^0-9]', '', 'g') = v_cpf;
  IF v_qtd > 0 THEN
    v_tipo := 'cadastro_sem_agendamento';
    v_prazo := 'nao_verificado';
    v_reason := 'consulta_nao_confere';
    SELECT count(*) INTO v_qtd_matches FROM public.pacientes p
    WHERE regexp_replace(coalesce(p.cpf, ''), '[^0-9]', '', 'g') = v_cpf
      AND lower(regexp_replace(btrim(coalesce(p.unidade_preferencia, '')), '[[:space:]]+', ' ', 'g'))
        = lower(regexp_replace(v_unidade, '[[:space:]]+', ' ', 'g'))
      AND p.data_agendamento::date = p_data_consulta_informada
      AND p.status IN ('agendado', 'faltou');

    IF v_qtd_matches = 1 THEN
      SELECT p.* INTO v_p FROM public.pacientes p
      WHERE regexp_replace(coalesce(p.cpf, ''), '[^0-9]', '', 'g') = v_cpf
        AND lower(regexp_replace(btrim(coalesce(p.unidade_preferencia, '')), '[[:space:]]+', ' ', 'g'))
          = lower(regexp_replace(v_unidade, '[[:space:]]+', ' ', 'g'))
        AND p.data_agendamento::date = p_data_consulta_informada
        AND p.status IN ('agendado', 'faltou') LIMIT 1;
      v_div := false;
      v_reason := NULL;
      IF v_p.status = 'agendado' THEN
        v_tipo := 'preventiva';
        v_prazo := CASE WHEN v_p.data_agendamento::date >= CURRENT_DATE + 1
          THEN 'dentro_do_prazo' ELSE 'menos_de_24_horas' END;
      ELSE
        v_tipo := 'por_falta';
        v_prazo := CASE WHEN v_p.data_agendamento::date >= CURRENT_DATE - 7
          THEN 'dentro_do_prazo' ELSE 'fora_do_prazo' END;
      END IF;
    ELSE
      v_reason := CASE WHEN v_qtd_matches > 1 THEN 'correspondencias_multiplas'
                        WHEN v_qtd > 1 THEN 'cpf_multiplo_sem_correspondencia'
                        ELSE 'consulta_nao_confere' END;
      -- CPF único, consulta divergente: captura snapshot SEM estabelecer vínculo para mutação.
      IF v_qtd = 1 THEN
        SELECT p.* INTO v_p FROM public.pacientes p
        WHERE regexp_replace(coalesce(p.cpf, ''), '[^0-9]', '', 'g') = v_cpf LIMIT 1;
      END IF;
    END IF;
  END IF;

  INSERT INTO public.solicitacoes_remarcacao (
    paciente_id, cpf, nome_completo, celular, email_contato, telefone_contato,
    unidade, tipo_remarcacao, cadastro_localizado, status_paciente, situacao_prazo,
    data_agendamento_original, motivo, data_consulta_informada, unidade_informada,
    divergencia_dados, motivo_divergencia, unidade_cadastro_encontrada,
    data_consulta_cadastro_encontrada, status_cadastro_encontrado
  ) VALUES (
    CASE WHEN v_div = false THEN v_p.id ELSE NULL END, v_cpf,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.nome_completo ELSE NULL END,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.celular ELSE NULL END,
    v_email, v_telefone,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.unidade_preferencia ELSE NULL END,
    v_tipo, v_qtd > 0,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.status ELSE NULL END,
    v_prazo,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.data_agendamento::date ELSE NULL END,
    v_motivo, p_data_consulta_informada, v_unidade, v_div, v_reason,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.unidade_preferencia ELSE NULL END,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.data_agendamento::date ELSE NULL END,
    CASE WHEN v_p.id IS NOT NULL THEN v_p.status ELSE NULL END
  ) RETURNING id, protocolo INTO v_id, v_protocolo;

  -- Não devolver nome/ID de paciente, unidade cadastrada nem data cadastrada a visitantes.
  RETURN json_build_object('sucesso', true, 'solicitacao_id', v_id,
    'protocolo', v_protocolo, 'cadastro_localizado', v_qtd > 0,
    'mensagem', 'Pedido recebido; ainda não aprovado. A equipe verificará os dados informados.');
END;
$$;
-- Postgres concede EXECUTE ao PUBLIC por padrão em função nova: revogar explicitamente.
REVOKE ALL ON FUNCTION public.solicitar_remarcacao(text,text,text,text,date,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.solicitar_remarcacao(text,text,text,text,date,text) TO anon, authenticated;
COMMIT;

-- APÓS implantação frontend e teste: revogar assinatura antiga (4 parâmetros) em transação
-- separada; não executar até confirmar assinatura/grants reais e rollback do frontend.
-- REVOKE EXECUTE ON FUNCTION public.solicitar_remarcacao(text,text,text,text) FROM PUBLIC, anon, authenticated;
-- A antiga RPC verificar_cpf_remarcacao revela dados de paciente: reduzir/revogar
-- após reescrever UX e diagnosticar consumidores. Não alterada nesta etapa.
