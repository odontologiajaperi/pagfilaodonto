-- ============================================================
-- RASTREAMENTO DE ACESSOS AO SITE
-- ============================================================
-- Execute este script no SQL Editor do Supabase.
-- Cria uma tabela para registrar cada acesso ao site com
-- informações como página visitada, horário, IP (se disponível)
-- e permite visualizar estatísticas de acesso.
-- ============================================================

-- 1. Criar tabela de acessos
CREATE TABLE IF NOT EXISTS public.acessos_site (
    id BIGSERIAL PRIMARY KEY,
    pagina TEXT NOT NULL,
    referrer TEXT,
    user_agent TEXT,
    ip_address TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_acessos_pagina ON public.acessos_site(pagina);
CREATE INDEX IF NOT EXISTS idx_acessos_timestamp ON public.acessos_site(timestamp);
CREATE INDEX IF NOT EXISTS idx_acessos_data ON public.acessos_site(DATE(timestamp));

-- 3. VIEW: Total de acessos por página
CREATE OR REPLACE VIEW public.acessos_por_pagina AS
SELECT
    pagina,
    COUNT(*) AS total_acessos,
    COUNT(DISTINCT DATE(timestamp)) AS dias_com_acesso,
    MIN(timestamp) AS primeiro_acesso,
    MAX(timestamp) AS ultimo_acesso
FROM public.acessos_site
GROUP BY pagina
ORDER BY total_acessos DESC;

-- 4. VIEW: Acessos por dia
CREATE OR REPLACE VIEW public.acessos_por_dia AS
SELECT
    DATE(timestamp) AS data,
    COUNT(*) AS total_acessos,
    COUNT(DISTINCT pagina) AS paginas_unicas
FROM public.acessos_site
GROUP BY DATE(timestamp)
ORDER BY data DESC;

-- 5. VIEW: Resumo geral
CREATE OR REPLACE VIEW public.resumo_acessos AS
SELECT
    COUNT(*) AS total_acessos,
    COUNT(DISTINCT pagina) AS total_paginas_visitadas,
    COUNT(DISTINCT DATE(timestamp)) AS dias_com_visitas,
    MIN(timestamp) AS primeiro_acesso_geral,
    MAX(timestamp) AS ultimo_acesso_geral
FROM public.acessos_site;

-- 6. FUNÇÃO: Registrar acesso (chamada pelo JavaScript)
CREATE OR REPLACE FUNCTION public.registrar_acesso(
    p_pagina TEXT,
    p_referrer TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.acessos_site (pagina, referrer, user_agent, ip_address)
    VALUES (p_pagina, p_referrer, p_user_agent, NULL);
END;
$$ LANGUAGE plpgsql;

-- 7. FUNÇÃO: Limpar acessos antigos (opcional, para manutenção)
-- Exemplo: DELETE acessos com mais de 90 dias
CREATE OR REPLACE FUNCTION public.limpar_acessos_antigos(p_dias_retencao INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    v_deletados INTEGER;
BEGIN
    DELETE FROM public.acessos_site
    WHERE timestamp < NOW() - INTERVAL '1 day' * p_dias_retencao;
    
    GET DIAGNOSTICS v_deletados = ROW_COUNT;
    RETURN v_deletados;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- COMO USAR:
-- 1. Execute este script no SQL Editor do Supabase.
-- 2. Adicione o código JavaScript em cada página que quer rastrear.
-- 3. Para ver estatísticas:
--    SELECT * FROM public.resumo_acessos;
--    SELECT * FROM public.acessos_por_pagina;
--    SELECT * FROM public.acessos_por_dia;
-- 4. Para limpar acessos com mais de 90 dias:
--    SELECT public.limpar_acessos_antigos(90);
-- ============================================================
