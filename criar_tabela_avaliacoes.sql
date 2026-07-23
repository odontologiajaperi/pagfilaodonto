-- ============================================================
-- TABELA DE AVALIAÇÕES - CRIAÇÃO E CONFIGURAÇÃO
-- ============================================================
-- Execute este script no SQL Editor do Supabase para criar
-- a tabela de avaliações com permissões de inserção pública
-- ============================================================

-- 1. Criar tabela de avaliações
CREATE TABLE IF NOT EXISTS public.avaliacoes (
    id BIGSERIAL PRIMARY KEY,
    cpf TEXT NOT NULL,
    data_atendimento DATE NOT NULL,
    unidade TEXT NOT NULL,
    cirurgiao_dentista TEXT NOT NULL,
    nota INTEGER NOT NULL CHECK (nota >= 0 AND nota <= 10),
    comentario TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_avaliacoes_cpf ON public.avaliacoes(cpf);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_unidade ON public.avaliacoes(unidade);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_dentista ON public.avaliacoes(cirurgiao_dentista);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_data ON public.avaliacoes(created_at);

-- 3. Desativar RLS para permitir inserções anônimas
ALTER TABLE public.avaliacoes DISABLE ROW LEVEL SECURITY;

-- 4. Dar permissões de inserção para usuários anônimos e autenticados
GRANT INSERT ON public.avaliacoes TO anon;
GRANT INSERT ON public.avaliacoes TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.avaliacoes_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.avaliacoes_id_seq TO authenticated;

-- 5. VIEW: Resumo de avaliações por dentista
CREATE OR REPLACE VIEW public.resumo_avaliacoes_dentista AS
SELECT
    cirurgiao_dentista,
    COUNT(*) AS total_avaliacoes,
    ROUND(AVG(nota)::NUMERIC, 2) AS nota_media,
    MIN(nota) AS nota_minima,
    MAX(nota) AS nota_maxima,
    COUNT(CASE WHEN comentario IS NOT NULL THEN 1 END) AS total_comentarios
FROM public.avaliacoes
GROUP BY cirurgiao_dentista
ORDER BY nota_media DESC;

-- 6. VIEW: Resumo de avaliações por unidade
CREATE OR REPLACE VIEW public.resumo_avaliacoes_unidade AS
SELECT
    unidade,
    COUNT(*) AS total_avaliacoes,
    ROUND(AVG(nota)::NUMERIC, 2) AS nota_media,
    MIN(nota) AS nota_minima,
    MAX(nota) AS nota_maxima
FROM public.avaliacoes
GROUP BY unidade
ORDER BY nota_media DESC;

-- ============================================================
-- COMO USAR:
-- 1. Execute este script no SQL Editor do Supabase.
-- 2. A página de avaliação do site agora conseguirá gravar dados.
-- 3. Para ver estatísticas:
--    SELECT * FROM public.resumo_avaliacoes_dentista;
--    SELECT * FROM public.resumo_avaliacoes_unidade;
-- ============================================================
