-- ============================================================
-- TABELA DE LOGS DE ERROS DO SITE
-- Execute no SQL Editor do Supabase
-- ============================================================

-- Criar tabela para armazenar os erros que ocorrem no site
CREATE TABLE IF NOT EXISTS public.logs_erros (
    id BIGSERIAL PRIMARY KEY,
    pagina TEXT NOT NULL,
    contexto TEXT,
    codigo_erro TEXT,
    mensagem_erro TEXT,
    detalhes TEXT,
    hint TEXT,
    dados_extra TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Desativar RLS para permitir inserções anônimas do site
ALTER TABLE public.logs_erros DISABLE ROW LEVEL SECURITY;

-- Dar permissão de inserção para o site (anon)
GRANT INSERT ON public.logs_erros TO anon;
GRANT INSERT ON public.logs_erros TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- View para consultar os erros recentes de forma organizada
CREATE OR REPLACE VIEW public.erros_recentes AS
SELECT 
    id,
    pagina,
    contexto,
    codigo_erro,
    mensagem_erro,
    detalhes,
    dados_extra,
    created_at AT TIME ZONE 'America/Sao_Paulo' AS data_hora_br
FROM public.logs_erros
ORDER BY created_at DESC
LIMIT 100;

-- View para resumo de erros por tipo
CREATE OR REPLACE VIEW public.resumo_erros AS
SELECT 
    pagina,
    codigo_erro,
    mensagem_erro,
    COUNT(*) AS total_ocorrencias,
    MAX(created_at) AT TIME ZONE 'America/Sao_Paulo' AS ultima_ocorrencia
FROM public.logs_erros
GROUP BY pagina, codigo_erro, mensagem_erro
ORDER BY total_ocorrencias DESC;

-- Função para limpar logs antigos (manter apenas os últimos X dias)
CREATE OR REPLACE FUNCTION public.limpar_logs_erros(dias_manter INTEGER DEFAULT 30)
RETURNS TEXT AS $$
DECLARE
    qtd INTEGER;
BEGIN
    DELETE FROM public.logs_erros WHERE created_at < NOW() - (dias_manter || ' days')::INTERVAL;
    GET DIAGNOSTICS qtd = ROW_COUNT;
    RETURN qtd || ' registros de log removidos (anteriores a ' || dias_manter || ' dias).';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
