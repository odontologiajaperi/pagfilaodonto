-- ============================================================
-- ATUALIZAÇÃO DO PAINEL DE REMARCAÇÕES
-- ============================================================
-- Este script atualiza a função de listagem para buscar dados
-- diretamente da tabela pacientes (JOIN) e cria uma função
-- para editar informações pelo painel.
-- Execute no SQL Editor do Supabase.
-- ============================================================

-- 1. ATUALIZA A LISTAGEM PARA BUSCAR DADOS FRESCOS DA TABELA PACIENTES
CREATE OR REPLACE FUNCTION public.listar_solicitacoes_remarcacao(
    p_senha TEXT,
    p_status TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_resultado JSON;
BEGIN
    IF NOT public.verificar_senha_admin(p_senha) THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Acesso não autorizado.');
    END IF;

    SELECT json_agg(row_to_json(t)) INTO v_resultado
    FROM (
        SELECT
            s.id,
            s.cpf,
            -- Prioriza dados frescos da tabela pacientes
            COALESCE(p.nome_completo, s.nome_completo, 'Não localizado') AS nome_completo,
            COALESCE(p.celular, s.celular) AS celular,
            s.email_contato,
            s.telefone_contato,
            COALESCE(p.unidade_preferencia, s.unidade) AS unidade,
            s.tipo_remarcacao,
            CASE WHEN p.id IS NOT NULL THEN true ELSE s.cadastro_localizado END AS cadastro_localizado,
            COALESCE(p.status, s.status_paciente) AS status_paciente,
            s.situacao_prazo,
            COALESCE(p.data_agendamento, s.data_agendamento_original) AS data_agendamento_original,
            s.motivo,
            s.status_solicitacao,
            s.data_nova,
            s.observacao_admin,
            s.documento_path,
            s.documento_nome,
            s.documento_mime,
            s.documento_tamanho,
            s.documento_enviado_em,
            s.created_at,
            s.updated_at,
            (CURRENT_DATE - s.created_at::date) AS dias_desde_solicitacao,
            -- Dados extras do paciente para o admin
            p.endereco AS endereco_paciente,
            p.nome_acs AS acs_paciente,
            p.email AS email_paciente,
            p.posicao_fila AS posicao_fila
        FROM public.solicitacoes_remarcacao s
        LEFT JOIN public.pacientes p
            ON regexp_replace(COALESCE(p.cpf, ''), '[^0-9]', '', 'g') = s.cpf
        WHERE p_status IS NULL OR s.status_solicitacao = p_status
        ORDER BY
            CASE WHEN s.status_solicitacao = 'pendente' THEN 0 ELSE 1 END,
            s.created_at DESC
    ) t;

    RETURN json_build_object('sucesso', true, 'dados', COALESCE(v_resultado, '[]'::json));
END;
$$;

-- 2. FUNÇÃO PARA EDITAR DADOS DE UMA SOLICITAÇÃO PELO PAINEL
CREATE OR REPLACE FUNCTION public.editar_solicitacao_remarcacao(
    p_senha TEXT,
    p_solicitacao_id UUID,
    p_nome_completo TEXT DEFAULT NULL,
    p_telefone_contato TEXT DEFAULT NULL,
    p_email_contato TEXT DEFAULT NULL,
    p_unidade TEXT DEFAULT NULL,
    p_observacao_admin TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sol RECORD;
BEGIN
    IF NOT public.verificar_senha_admin(p_senha) THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Acesso não autorizado.');
    END IF;

    SELECT * INTO v_sol FROM public.solicitacoes_remarcacao WHERE id = p_solicitacao_id;
    IF v_sol IS NULL THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Solicitação não encontrada.');
    END IF;

    -- Atualiza campos na solicitação
    UPDATE public.solicitacoes_remarcacao SET
        nome_completo = COALESCE(NULLIF(trim(p_nome_completo), ''), nome_completo),
        telefone_contato = COALESCE(NULLIF(trim(p_telefone_contato), ''), telefone_contato),
        email_contato = COALESCE(NULLIF(trim(p_email_contato), ''), email_contato),
        unidade = COALESCE(NULLIF(trim(p_unidade), ''), unidade),
        observacao_admin = COALESCE(NULLIF(trim(p_observacao_admin), ''), observacao_admin),
        updated_at = NOW()
    WHERE id = p_solicitacao_id;

    -- Se o paciente existe no banco, atualiza também na tabela pacientes
    IF v_sol.paciente_id IS NOT NULL THEN
        UPDATE public.pacientes SET
            celular = COALESCE(NULLIF(regexp_replace(COALESCE(p_telefone_contato, ''), '[^0-9]', '', 'g'), ''), celular),
            email = COALESCE(NULLIF(trim(p_email_contato), ''), email),
            unidade_preferencia = COALESCE(NULLIF(trim(p_unidade), ''), unidade_preferencia)
        WHERE id = v_sol.paciente_id;
    END IF;

    RETURN json_build_object('sucesso', true, 'mensagem', 'Dados atualizados com sucesso.');
END;
$$;

GRANT EXECUTE ON FUNCTION public.listar_solicitacoes_remarcacao(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.editar_solicitacao_remarcacao(TEXT, UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
