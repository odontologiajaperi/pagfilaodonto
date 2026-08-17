-- ============================================================
-- REMARCAÇÕES — VERSÃO 2 (CONTATOS + SOLICITAÇÃO SEM CPF LOCALIZADO)
-- ============================================================
-- Execute este arquivo inteiro no SQL Editor do Supabase.
--
-- O sistema passa a:
-- 1. Salvar TODA solicitação, mesmo se o CPF não for localizado;
-- 2. Exigir e-mail e telefone de contato;
-- 3. Informar ao paciente se o cadastro foi localizado ou não;
-- 4. Manter os dados das solicitações na tabela public.solicitacoes_remarcacao;
-- 5. Manter pacientes agendados/faltosos por 7 dias após a consulta.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. TABELA DE SOLICITAÇÕES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.solicitacoes_remarcacao (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    paciente_id UUID NULL,
    cpf TEXT NOT NULL,
    nome_completo TEXT NULL,
    celular TEXT NULL,
    email_contato TEXT NOT NULL,
    telefone_contato TEXT NOT NULL,
    unidade TEXT NULL,
    tipo_remarcacao TEXT NOT NULL DEFAULT 'cpf_nao_localizado',
    cadastro_localizado BOOLEAN NOT NULL DEFAULT FALSE,
    status_paciente TEXT NULL,
    situacao_prazo TEXT NOT NULL DEFAULT 'nao_verificado',
    data_agendamento_original DATE NULL,
    motivo TEXT NULL,
    status_solicitacao TEXT NOT NULL DEFAULT 'pendente',
    data_nova DATE NULL,
    observacao_admin TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT solicitacoes_remarcacao_status_check
        CHECK (status_solicitacao IN ('pendente', 'aprovada', 'recusada', 'contatado')),
    CONSTRAINT solicitacoes_remarcacao_tipo_check
        CHECK (tipo_remarcacao IN ('preventiva', 'por_falta', 'cadastro_sem_agendamento', 'cpf_nao_localizado'))
);

-- Migração segura caso a tabela tenha sido criada pela versão anterior.
ALTER TABLE public.solicitacoes_remarcacao ADD COLUMN IF NOT EXISTS email_contato TEXT;
ALTER TABLE public.solicitacoes_remarcacao ADD COLUMN IF NOT EXISTS telefone_contato TEXT;
ALTER TABLE public.solicitacoes_remarcacao ADD COLUMN IF NOT EXISTS cadastro_localizado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.solicitacoes_remarcacao ADD COLUMN IF NOT EXISTS status_paciente TEXT;
ALTER TABLE public.solicitacoes_remarcacao ADD COLUMN IF NOT EXISTS situacao_prazo TEXT NOT NULL DEFAULT 'nao_verificado';
ALTER TABLE public.solicitacoes_remarcacao ALTER COLUMN paciente_id DROP NOT NULL;
ALTER TABLE public.solicitacoes_remarcacao ALTER COLUMN nome_completo DROP NOT NULL;
ALTER TABLE public.solicitacoes_remarcacao ALTER COLUMN unidade DROP NOT NULL;

-- Substitui a restrição antiga de tipos, se ela existir.
ALTER TABLE public.solicitacoes_remarcacao
    DROP CONSTRAINT IF EXISTS solicitacoes_remarcacao_tipo_remarcacao_check;
ALTER TABLE public.solicitacoes_remarcacao
    DROP CONSTRAINT IF EXISTS solicitacoes_remarcacao_tipo_check;
ALTER TABLE public.solicitacoes_remarcacao
    ADD CONSTRAINT solicitacoes_remarcacao_tipo_check
    CHECK (tipo_remarcacao IN ('preventiva', 'por_falta', 'cadastro_sem_agendamento', 'cpf_nao_localizado'));

CREATE INDEX IF NOT EXISTS idx_solicitacoes_remarcacao_cpf ON public.solicitacoes_remarcacao (cpf);
CREATE INDEX IF NOT EXISTS idx_solicitacoes_remarcacao_status ON public.solicitacoes_remarcacao (status_solicitacao, created_at DESC);

-- Colunas usadas apenas se houver paciente localizado e a remarcação for aprovada.
ALTER TABLE public.pacientes ADD COLUMN IF NOT EXISTS remarcacoes INTEGER DEFAULT 0;
ALTER TABLE public.pacientes ADD COLUMN IF NOT EXISTS data_agendamento_anterior DATE;

-- ============================================================
-- 2. CONFIGURAÇÃO DE ADMINISTRAÇÃO
-- ============================================================
CREATE TABLE IF NOT EXISTS public.admin_config (
    id SERIAL PRIMARY KEY,
    chave TEXT UNIQUE NOT NULL,
    valor TEXT NOT NULL
);

-- Senha inicial do painel: japeri2026
-- Se ela já existir, este comando NÃO troca a senha atual.
INSERT INTO public.admin_config (chave, valor)
VALUES ('senha_admin_remarcacoes', crypt('japeri2026', gen_salt('bf')))
ON CONFLICT (chave) DO NOTHING;

-- ============================================================
-- 3. CONSULTAR CPF ANTES DE CONFIRMAR O PEDIDO
-- ============================================================
-- Esta função não bloqueia a solicitação: apenas informa se localizou
-- um cadastro e qual situação foi encontrada.
CREATE OR REPLACE FUNCTION public.verificar_cpf_remarcacao(p_cpf TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_paciente RECORD;
    v_cpf TEXT;
    v_tipo TEXT;
    v_prazo TEXT := 'nao_verificado';
BEGIN
    v_cpf := regexp_replace(COALESCE(p_cpf, ''), '[^0-9]', '', 'g');

    SELECT id, nome_completo, celular, unidade_preferencia, data_agendamento, status,
           COALESCE(remarcacoes, 0) AS remarcacoes
    INTO v_paciente
    FROM public.pacientes
    WHERE regexp_replace(COALESCE(cpf, ''), '[^0-9]', '', 'g') = v_cpf
    ORDER BY
        CASE WHEN status = 'agendado' THEN 1 WHEN status = 'faltou' THEN 2 ELSE 3 END,
        data_agendamento DESC NULLS LAST
    LIMIT 1;

    IF v_paciente IS NULL THEN
        RETURN json_build_object(
            'sucesso', true,
            'cadastro_localizado', false,
            'mensagem', 'Não localizamos um cadastro para este CPF. Mesmo assim, você poderá enviar a solicitação e a equipe fará a análise manual.'
        );
    END IF;

    IF v_paciente.status = 'agendado' THEN
        v_tipo := 'preventiva';
        v_prazo := CASE
            WHEN v_paciente.data_agendamento IS NULL THEN 'data_nao_informada'
            WHEN v_paciente.data_agendamento >= CURRENT_DATE + 1 THEN 'dentro_do_prazo'
            ELSE 'menos_de_24_horas'
        END;
    ELSIF v_paciente.status = 'faltou' THEN
        v_tipo := 'por_falta';
        v_prazo := CASE
            WHEN v_paciente.data_agendamento IS NULL THEN 'data_nao_informada'
            WHEN v_paciente.data_agendamento >= CURRENT_DATE - 7 THEN 'dentro_do_prazo'
            ELSE 'fora_do_prazo'
        END;
    ELSE
        v_tipo := 'cadastro_sem_agendamento';
        v_prazo := 'sem_agendamento_ativo';
    END IF;

    RETURN json_build_object(
        'sucesso', true,
        'cadastro_localizado', true,
        'paciente_id', v_paciente.id,
        'nome', v_paciente.nome_completo,
        'unidade', v_paciente.unidade_preferencia,
        'data_agendamento', v_paciente.data_agendamento,
        'status_paciente', v_paciente.status,
        'tipo_remarcacao', v_tipo,
        'situacao_prazo', v_prazo,
        'remarcacoes', v_paciente.remarcacoes,
        'mensagem', CASE
            WHEN v_tipo = 'preventiva' THEN 'Cadastro localizado. Você pode registrar a solicitação de remarcação.'
            WHEN v_tipo = 'por_falta' AND v_prazo = 'dentro_do_prazo' THEN 'Cadastro localizado. A falta está dentro do prazo de análise para remarcação.'
            WHEN v_tipo = 'por_falta' AND v_prazo = 'fora_do_prazo' THEN 'Cadastro localizado. A falta ocorreu há mais de 7 dias; a equipe analisará a solicitação manualmente.'
            ELSE 'Cadastro localizado, mas não foi identificado um agendamento ativo. A solicitação poderá ser enviada para análise manual.'
        END
    );
END;
$$;

-- ============================================================
-- 4. REGISTRAR A SOLICITAÇÃO (NUNCA BLOQUEIA APENAS POR CPF)
-- ============================================================
DROP FUNCTION IF EXISTS public.solicitar_remarcacao(TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.solicitar_remarcacao(
    p_cpf TEXT,
    p_email_contato TEXT,
    p_telefone_contato TEXT,
    p_motivo TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_paciente RECORD;
    v_cpf TEXT;
    v_email TEXT;
    v_telefone TEXT;
    v_tipo TEXT := 'cpf_nao_localizado';
    v_prazo TEXT := 'nao_verificado';
    v_pendente INTEGER;
    v_solicitacao_id UUID;
BEGIN
    v_cpf := regexp_replace(COALESCE(p_cpf, ''), '[^0-9]', '', 'g');
    v_email := lower(trim(COALESCE(p_email_contato, '')));
    v_telefone := regexp_replace(COALESCE(p_telefone_contato, ''), '[^0-9]', '', 'g');

    IF length(v_cpf) <> 11 THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Informe um CPF com 11 dígitos.');
    END IF;

    IF v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Informe um e-mail de contato válido.');
    END IF;

    IF length(v_telefone) < 10 OR length(v_telefone) > 13 THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Informe um telefone de contato válido, com DDD.');
    END IF;

    -- Evita spam sem impedir solicitações de CPF não localizado.
    SELECT COUNT(*) INTO v_pendente
    FROM public.solicitacoes_remarcacao
    WHERE cpf = v_cpf AND status_solicitacao = 'pendente';

    IF v_pendente > 0 THEN
        RETURN json_build_object(
            'sucesso', false,
            'mensagem', 'Já existe uma solicitação em análise para este CPF. Aguarde o contato da equipe.'
        );
    END IF;

    SELECT id, nome_completo, celular, unidade_preferencia, data_agendamento, status
    INTO v_paciente
    FROM public.pacientes
    WHERE regexp_replace(COALESCE(cpf, ''), '[^0-9]', '', 'g') = v_cpf
    ORDER BY
        CASE WHEN status = 'agendado' THEN 1 WHEN status = 'faltou' THEN 2 ELSE 3 END,
        data_agendamento DESC NULLS LAST
    LIMIT 1;

    IF v_paciente IS NOT NULL THEN
        IF v_paciente.status = 'agendado' THEN
            v_tipo := 'preventiva';
            v_prazo := CASE
                WHEN v_paciente.data_agendamento IS NULL THEN 'data_nao_informada'
                WHEN v_paciente.data_agendamento >= CURRENT_DATE + 1 THEN 'dentro_do_prazo'
                ELSE 'menos_de_24_horas'
            END;
        ELSIF v_paciente.status = 'faltou' THEN
            v_tipo := 'por_falta';
            v_prazo := CASE
                WHEN v_paciente.data_agendamento IS NULL THEN 'data_nao_informada'
                WHEN v_paciente.data_agendamento >= CURRENT_DATE - 7 THEN 'dentro_do_prazo'
                ELSE 'fora_do_prazo'
            END;
        ELSE
            v_tipo := 'cadastro_sem_agendamento';
            v_prazo := 'sem_agendamento_ativo';
        END IF;

        INSERT INTO public.solicitacoes_remarcacao (
            paciente_id, cpf, nome_completo, celular, email_contato, telefone_contato,
            unidade, tipo_remarcacao, cadastro_localizado, status_paciente,
            situacao_prazo, data_agendamento_original, motivo
        ) VALUES (
            v_paciente.id, v_cpf, v_paciente.nome_completo, v_paciente.celular,
            v_email, v_telefone, v_paciente.unidade_preferencia, v_tipo, true,
            v_paciente.status, v_prazo, v_paciente.data_agendamento, NULLIF(trim(p_motivo), '')
        ) RETURNING id INTO v_solicitacao_id;

        RETURN json_build_object(
            'sucesso', true,
            'solicitacao_id', v_solicitacao_id,
            'cadastro_localizado', true,
            'mensagem', 'Solicitação registrada. Nossa equipe entrará em contato em até 3 dias úteis.'
        );
    END IF;

    -- CPF não localizado: ainda assim salva a solicitação para análise manual.
    INSERT INTO public.solicitacoes_remarcacao (
        cpf, email_contato, telefone_contato, tipo_remarcacao, cadastro_localizado,
        situacao_prazo, motivo
    ) VALUES (
        v_cpf, v_email, v_telefone, 'cpf_nao_localizado', false,
        'cadastro_nao_localizado', NULLIF(trim(p_motivo), '')
    ) RETURNING id INTO v_solicitacao_id;

    RETURN json_build_object(
        'sucesso', true,
        'solicitacao_id', v_solicitacao_id,
        'cadastro_localizado', false,
        'mensagem', 'Solicitação registrada para análise manual. Nossa equipe entrará em contato em até 3 dias úteis.'
    );
END;
$$;

-- ============================================================
-- 5. ACESSO ADMINISTRATIVO
-- ============================================================
CREATE OR REPLACE FUNCTION public.verificar_senha_admin(p_senha TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hash_salvo TEXT;
BEGIN
    SELECT valor INTO v_hash_salvo
    FROM public.admin_config
    WHERE chave = 'senha_admin_remarcacoes';

    IF v_hash_salvo IS NULL THEN
        RETURN false;
    END IF;

    -- Compatibilidade temporária com o hash SHA-256 da primeira versão;
    -- novos hashes usam bcrypt (crypt/pgcrypto).
    IF v_hash_salvo LIKE '$2%' THEN
        RETURN crypt(p_senha, v_hash_salvo) = v_hash_salvo;
    END IF;

    RETURN encode(digest(p_senha, 'sha256'), 'hex') = v_hash_salvo;
END;
$$;

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
        SELECT id, cpf, nome_completo, celular, email_contato, telefone_contato,
               unidade, tipo_remarcacao, cadastro_localizado, status_paciente,
               situacao_prazo, data_agendamento_original, motivo, status_solicitacao,
               data_nova, observacao_admin, created_at, updated_at,
               (CURRENT_DATE - created_at::date) AS dias_desde_solicitacao
        FROM public.solicitacoes_remarcacao
        WHERE p_status IS NULL OR status_solicitacao = p_status
        ORDER BY
            CASE WHEN status_solicitacao = 'pendente' THEN 0 ELSE 1 END,
            created_at DESC
    ) t;

    RETURN json_build_object('sucesso', true, 'dados', COALESCE(v_resultado, '[]'::json));
END;
$$;

CREATE OR REPLACE FUNCTION public.processar_remarcacao(
    p_senha TEXT,
    p_solicitacao_id UUID,
    p_acao TEXT,
    p_data_nova DATE DEFAULT NULL,
    p_observacao TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_solicitacao RECORD;
BEGIN
    IF NOT public.verificar_senha_admin(p_senha) THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Acesso não autorizado.');
    END IF;

    SELECT * INTO v_solicitacao
    FROM public.solicitacoes_remarcacao
    WHERE id = p_solicitacao_id;

    IF v_solicitacao IS NULL THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Solicitação não encontrada.');
    END IF;

    IF p_acao = 'aprovar' THEN
        IF p_data_nova IS NULL THEN
            RETURN json_build_object('sucesso', false, 'mensagem', 'Informe a nova data para aprovar a solicitação.');
        END IF;

        UPDATE public.solicitacoes_remarcacao
        SET status_solicitacao = 'aprovada',
            data_nova = p_data_nova,
            observacao_admin = NULLIF(trim(p_observacao), ''),
            updated_at = NOW()
        WHERE id = p_solicitacao_id;

        IF v_solicitacao.paciente_id IS NOT NULL THEN
            UPDATE public.pacientes
            SET data_agendamento_anterior = data_agendamento,
                data_agendamento = p_data_nova,
                status = 'agendado',
                remarcacoes = COALESCE(remarcacoes, 0) + 1
            WHERE id = v_solicitacao.paciente_id;

            RETURN json_build_object('sucesso', true, 'mensagem', 'Solicitação aprovada e data do paciente atualizada.');
        END IF;

        RETURN json_build_object('sucesso', true, 'mensagem', 'Solicitação aprovada. Como o CPF não foi localizado, atualize o agendamento manualmente conforme a análise da equipe.');

    ELSIF p_acao IN ('recusar', 'contatado') THEN
        UPDATE public.solicitacoes_remarcacao
        SET status_solicitacao = CASE WHEN p_acao = 'recusar' THEN 'recusada' ELSE 'contatado' END,
            observacao_admin = NULLIF(trim(p_observacao), ''),
            updated_at = NOW()
        WHERE id = p_solicitacao_id;

        RETURN json_build_object('sucesso', true, 'mensagem', 'Solicitação atualizada com sucesso.');
    END IF;

    RETURN json_build_object('sucesso', false, 'mensagem', 'Ação inválida.');
END;
$$;

-- ============================================================
-- 6. LIMPEZA APÓS 7 DIAS
-- ============================================================
CREATE OR REPLACE FUNCTION public.limpar_agendados_passados()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM public.pacientes
    WHERE status IN ('agendado', 'atendido', 'faltou')
      AND data_agendamento < (CURRENT_DATE - INTERVAL '7 days');
    RETURN NULL;
END;
$$;

-- ============================================================
-- 7. PERMISSÕES
-- ============================================================
-- Nenhum acesso direto público à tabela de solicitações.
ALTER TABLE public.solicitacoes_remarcacao ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir select por cpf" ON public.solicitacoes_remarcacao;
REVOKE ALL ON TABLE public.solicitacoes_remarcacao FROM anon, authenticated;

GRANT EXECUTE ON FUNCTION public.verificar_cpf_remarcacao(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.solicitar_remarcacao(TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verificar_senha_admin(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.listar_solicitacoes_remarcacao(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.processar_remarcacao(TEXT, UUID, TEXT, DATE, TEXT) TO anon, authenticated;

-- ============================================================
-- 8. CONSULTAS ADMINISTRATIVAS (SQL Editor)
-- ============================================================
-- Ver solicitações pendentes:
-- SELECT * FROM public.solicitacoes_remarcacao WHERE status_solicitacao = 'pendente' ORDER BY created_at DESC;
--
-- Ver todas as solicitações sem CPF localizado:
-- SELECT * FROM public.solicitacoes_remarcacao WHERE cadastro_localizado = false ORDER BY created_at DESC;
--
-- Alterar a senha do painel para uma senha forte:
-- UPDATE public.admin_config
-- SET valor = crypt('SUA_NOVA_SENHA_FORTE', gen_salt('bf'))
-- WHERE chave = 'senha_admin_remarcacoes';
-- ============================================================
