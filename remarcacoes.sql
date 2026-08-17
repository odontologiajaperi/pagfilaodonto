-- ============================================================
-- SISTEMA DE SOLICITAÇÃO DE REMARCAÇÃO DE CONSULTAS
-- ============================================================
-- Execute este script no SQL Editor do Supabase.
-- Ele cria a tabela de solicitações, funções RPC e ajusta
-- o prazo de limpeza de pacientes agendados para 7 dias.
-- ============================================================

-- 1. CRIAR TABELA DE SOLICITAÇÕES DE REMARCAÇÃO
CREATE TABLE IF NOT EXISTS public.solicitacoes_remarcacao (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    paciente_id UUID,
    cpf TEXT NOT NULL,
    nome_completo TEXT NOT NULL,
    celular TEXT,
    unidade TEXT NOT NULL,
    tipo_remarcacao TEXT NOT NULL CHECK (tipo_remarcacao IN ('preventiva', 'por_falta')),
    data_agendamento_original DATE,
    motivo TEXT,
    status_solicitacao TEXT NOT NULL DEFAULT 'pendente' CHECK (status_solicitacao IN ('pendente', 'aprovada', 'recusada', 'contatado')),
    data_nova DATE,
    observacao_admin TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ADICIONAR COLUNAS NA TABELA PACIENTES (SE NÃO EXISTIREM)
ALTER TABLE public.pacientes ADD COLUMN IF NOT EXISTS remarcacoes INTEGER DEFAULT 0;
ALTER TABLE public.pacientes ADD COLUMN IF NOT EXISTS data_agendamento_anterior DATE;

-- 3. CRIAR TABELA DE SENHA DO ADMIN (para o painel)
CREATE TABLE IF NOT EXISTS public.admin_config (
    id SERIAL PRIMARY KEY,
    chave TEXT UNIQUE NOT NULL,
    valor TEXT NOT NULL
);

-- Inserir senha padrão (SHA-256 de 'japeri2026')
-- IMPORTANTE: Mude essa senha depois executando:
-- UPDATE public.admin_config SET valor = encode(sha256('SUA_NOVA_SENHA'::bytea), 'hex') WHERE chave = 'senha_admin_remarcacoes';
INSERT INTO public.admin_config (chave, valor)
VALUES ('senha_admin_remarcacoes', encode(sha256('japeri2026'::bytea), 'hex'))
ON CONFLICT (chave) DO NOTHING;

-- 4. FUNÇÃO RPC: SOLICITAR REMARCAÇÃO (chamada pelo paciente no site)
CREATE OR REPLACE FUNCTION public.solicitar_remarcacao(
    p_cpf TEXT,
    p_motivo TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_paciente RECORD;
    v_tipo TEXT;
    v_dias_desde_agendamento INTEGER;
    v_solicitacoes_existentes INTEGER;
BEGIN
    -- Limpar CPF (apenas dígitos)
    p_cpf := regexp_replace(p_cpf, '[^0-9]', '', 'g');

    -- Buscar paciente pelo CPF com status 'agendado'
    SELECT id, nome_completo, celular, unidade_preferencia, data_agendamento, status
    INTO v_paciente
    FROM public.pacientes
    WHERE cpf = p_cpf
      AND status IN ('agendado', 'faltou')
    ORDER BY 
        CASE WHEN status = 'agendado' THEN 1 ELSE 2 END,
        data_agendamento DESC NULLS LAST
    LIMIT 1;

    -- Se não encontrou
    IF v_paciente IS NULL THEN
        RETURN json_build_object(
            'sucesso', false,
            'mensagem', 'Nenhum agendamento ou falta encontrado para este CPF. Verifique se digitou corretamente.'
        );
    END IF;

    -- Determinar tipo de remarcação
    IF v_paciente.status = 'agendado' THEN
        v_tipo := 'preventiva';
    ELSIF v_paciente.status = 'faltou' THEN
        v_tipo := 'por_falta';
        
        -- Verificar prazo de 7 dias para falta
        v_dias_desde_agendamento := CURRENT_DATE - COALESCE(v_paciente.data_agendamento, CURRENT_DATE);
        IF v_dias_desde_agendamento > 7 THEN
            RETURN json_build_object(
                'sucesso', false,
                'mensagem', 'O prazo de 7 dias para solicitar remarcação após a falta já expirou. Não é possível processar esta solicitação.'
            );
        END IF;
    END IF;

    -- Verificar duplicidade (já tem solicitação pendente para este agendamento)
    SELECT COUNT(*) INTO v_solicitacoes_existentes
    FROM public.solicitacoes_remarcacao
    WHERE cpf = p_cpf
      AND status_solicitacao = 'pendente';

    IF v_solicitacoes_existentes >= 1 THEN
        RETURN json_build_object(
            'sucesso', false,
            'mensagem', 'Já existe uma solicitação de remarcação em andamento para o seu CPF. Aguarde o contato da equipe.'
        );
    END IF;

    -- Verificar limite de remarcações (máximo 2 aprovadas)
    SELECT COUNT(*) INTO v_solicitacoes_existentes
    FROM public.solicitacoes_remarcacao
    WHERE cpf = p_cpf
      AND status_solicitacao = 'aprovada';

    IF v_solicitacoes_existentes >= 2 THEN
        RETURN json_build_object(
            'sucesso', false,
            'mensagem', 'Você já utilizou o máximo de 2 remarcações permitidas.'
        );
    END IF;

    -- Inserir solicitação
    INSERT INTO public.solicitacoes_remarcacao (
        paciente_id, cpf, nome_completo, celular, unidade,
        tipo_remarcacao, data_agendamento_original, motivo
    ) VALUES (
        v_paciente.id, p_cpf, v_paciente.nome_completo, v_paciente.celular,
        v_paciente.unidade_preferencia, v_tipo, v_paciente.data_agendamento, p_motivo
    );

    RETURN json_build_object(
        'sucesso', true,
        'mensagem', 'Solicitação de remarcação registrada com sucesso! Nossa equipe entrará em contato em até 3 dias úteis.',
        'tipo', v_tipo,
        'nome', v_paciente.nome_completo,
        'unidade', v_paciente.unidade_preferencia,
        'data_original', v_paciente.data_agendamento
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. FUNÇÃO RPC: VERIFICAR SENHA DO ADMIN
CREATE OR REPLACE FUNCTION public.verificar_senha_admin(p_senha TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_hash_salvo TEXT;
    v_hash_informado TEXT;
BEGIN
    SELECT valor INTO v_hash_salvo
    FROM public.admin_config
    WHERE chave = 'senha_admin_remarcacoes';

    IF v_hash_salvo IS NULL THEN
        RETURN false;
    END IF;

    v_hash_informado := encode(sha256(p_senha::bytea), 'hex');
    RETURN v_hash_informado = v_hash_salvo;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. FUNÇÃO RPC: LISTAR SOLICITAÇÕES (para o admin)
CREATE OR REPLACE FUNCTION public.listar_solicitacoes_remarcacao(p_senha TEXT, p_status TEXT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_autenticado BOOLEAN;
    v_resultado JSON;
BEGIN
    v_autenticado := public.verificar_senha_admin(p_senha);
    IF NOT v_autenticado THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Senha incorreta.');
    END IF;

    IF p_status IS NOT NULL THEN
        SELECT json_agg(row_to_json(t)) INTO v_resultado
        FROM (
            SELECT id, cpf, nome_completo, celular, unidade, tipo_remarcacao,
                   data_agendamento_original, motivo, status_solicitacao,
                   data_nova, observacao_admin, created_at, updated_at,
                   (CURRENT_DATE - created_at::date) as dias_desde_solicitacao
            FROM public.solicitacoes_remarcacao
            WHERE status_solicitacao = p_status
            ORDER BY created_at DESC
        ) t;
    ELSE
        SELECT json_agg(row_to_json(t)) INTO v_resultado
        FROM (
            SELECT id, cpf, nome_completo, celular, unidade, tipo_remarcacao,
                   data_agendamento_original, motivo, status_solicitacao,
                   data_nova, observacao_admin, created_at, updated_at,
                   (CURRENT_DATE - created_at::date) as dias_desde_solicitacao
            FROM public.solicitacoes_remarcacao
            ORDER BY 
                CASE WHEN status_solicitacao = 'pendente' THEN 0 ELSE 1 END,
                created_at DESC
        ) t;
    END IF;

    RETURN json_build_object('sucesso', true, 'dados', COALESCE(v_resultado, '[]'::json));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. FUNÇÃO RPC: PROCESSAR SOLICITAÇÃO (admin aprova/recusa)
CREATE OR REPLACE FUNCTION public.processar_remarcacao(
    p_senha TEXT,
    p_solicitacao_id UUID,
    p_acao TEXT,
    p_data_nova DATE DEFAULT NULL,
    p_observacao TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_autenticado BOOLEAN;
    v_solicitacao RECORD;
BEGIN
    v_autenticado := public.verificar_senha_admin(p_senha);
    IF NOT v_autenticado THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Senha incorreta.');
    END IF;

    -- Buscar solicitação
    SELECT * INTO v_solicitacao
    FROM public.solicitacoes_remarcacao
    WHERE id = p_solicitacao_id;

    IF v_solicitacao IS NULL THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Solicitação não encontrada.');
    END IF;

    IF p_acao = 'aprovar' THEN
        -- Atualizar solicitação
        UPDATE public.solicitacoes_remarcacao
        SET status_solicitacao = 'aprovada',
            data_nova = p_data_nova,
            observacao_admin = p_observacao,
            updated_at = NOW()
        WHERE id = p_solicitacao_id;

        -- Atualizar paciente (nova data de agendamento)
        IF p_data_nova IS NOT NULL AND v_solicitacao.paciente_id IS NOT NULL THEN
            UPDATE public.pacientes
            SET data_agendamento_anterior = data_agendamento,
                data_agendamento = p_data_nova,
                status = 'agendado',
                remarcacoes = COALESCE(remarcacoes, 0) + 1
            WHERE id = v_solicitacao.paciente_id;
        END IF;

        RETURN json_build_object('sucesso', true, 'mensagem', 'Solicitação aprovada e paciente remarcado.');

    ELSIF p_acao = 'recusar' THEN
        UPDATE public.solicitacoes_remarcacao
        SET status_solicitacao = 'recusada',
            observacao_admin = p_observacao,
            updated_at = NOW()
        WHERE id = p_solicitacao_id;

        RETURN json_build_object('sucesso', true, 'mensagem', 'Solicitação recusada.');

    ELSIF p_acao = 'contatado' THEN
        UPDATE public.solicitacoes_remarcacao
        SET status_solicitacao = 'contatado',
            observacao_admin = p_observacao,
            updated_at = NOW()
        WHERE id = p_solicitacao_id;

        RETURN json_build_object('sucesso', true, 'mensagem', 'Solicitação marcada como contatado.');
    ELSE
        RETURN json_build_object('sucesso', false, 'mensagem', 'Ação inválida. Use: aprovar, recusar ou contatado.');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. ALTERAR PRAZO DE LIMPEZA DE AGENDADOS PARA 7 DIAS
-- (Substitui a função anterior que usava 2 dias)
CREATE OR REPLACE FUNCTION public.limpar_agendados_passados()
RETURNS TRIGGER AS $$
BEGIN
    -- Deleta registros agendados/atendidos onde a data já passou de 7 dias
    -- Isso dá tempo para o paciente solicitar remarcação por falta
    DELETE FROM public.pacientes 
    WHERE status IN ('agendado', 'atendido', 'faltou') 
    AND data_agendamento < (CURRENT_DATE - INTERVAL '7 days');
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Atualizar também a função de limpeza de pediatria (se existir)
CREATE OR REPLACE FUNCTION public.limpar_pacientes_agendados_apos_2_dias()
RETURNS void AS $$
BEGIN
    -- Alterado para 7 dias para manter consistência com o sistema de remarcação
    DELETE FROM public.pacientes
    WHERE LOWER(TRIM(COALESCE(status, ''))) IN ('agendado', 'atendido', 'faltou')
      AND data_agendamento IS NOT NULL
      AND data_agendamento < (CURRENT_DATE - INTERVAL '7 days');
END;
$$ LANGUAGE plpgsql;

-- 9. PERMISSÕES
GRANT EXECUTE ON FUNCTION public.solicitar_remarcacao(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.solicitar_remarcacao(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verificar_senha_admin(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.verificar_senha_admin(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.listar_solicitacoes_remarcacao(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.listar_solicitacoes_remarcacao(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.processar_remarcacao(TEXT, UUID, TEXT, DATE, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.processar_remarcacao(TEXT, UUID, TEXT, DATE, TEXT) TO authenticated;

-- Permitir SELECT na tabela para consulta de status pelo paciente
ALTER TABLE public.solicitacoes_remarcacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir select por cpf" ON public.solicitacoes_remarcacao
    FOR SELECT TO anon, authenticated
    USING (true);

-- Bloquear INSERT/UPDATE/DELETE direto (apenas via RPC)
-- (RLS habilitada sem política de INSERT/UPDATE/DELETE = bloqueado)

-- 10. VIEW DE MONITORAMENTO PARA O ADMIN
CREATE OR REPLACE VIEW public.resumo_remarcacoes AS
SELECT 
    status_solicitacao,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE tipo_remarcacao = 'preventiva') as preventivas,
    COUNT(*) FILTER (WHERE tipo_remarcacao = 'por_falta') as por_falta
FROM public.solicitacoes_remarcacao
GROUP BY status_solicitacao;

GRANT SELECT ON public.resumo_remarcacoes TO anon;
GRANT SELECT ON public.resumo_remarcacoes TO authenticated;

-- ============================================================
-- INSTRUÇÕES PÓS-EXECUÇÃO:
-- ============================================================
-- 1. A senha padrão do painel admin é: japeri2026
--    Para mudar a senha, execute:
--    UPDATE public.admin_config SET valor = encode(sha256('SUA_NOVA_SENHA'::bytea), 'hex') WHERE chave = 'senha_admin_remarcacoes';
--
-- 2. O prazo de limpeza foi alterado de 2 para 7 dias.
--    Pacientes agendados/faltosos só serão removidos do banco 7 dias após a data da consulta.
--
-- 3. Para ver as solicitações pendentes:
--    SELECT * FROM public.solicitacoes_remarcacao WHERE status_solicitacao = 'pendente';
--
-- 4. Para ver o resumo:
--    SELECT * FROM public.resumo_remarcacoes;
-- ============================================================
