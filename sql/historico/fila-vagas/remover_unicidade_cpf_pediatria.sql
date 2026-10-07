-- ============================================================
-- CORREÇÃO: PERMITIR CPF REPETIDO NA ODONTOPEDIATRIA
-- Projeto: Saúde Bucal de Japeri
-- Objetivo:
--   Remover restrição/índice UNIQUE do campo cpf SOMENTE na tabela
--   public.pacientes_pediatria, permitindo que o mesmo responsável
--   cadastre mais de uma criança.
--
-- IMPORTANTE:
--   Execute este script no Supabase em SQL Editor > New query > Run.
--   Este script NÃO altera a tabela public.pacientes nem public.gestantes.
-- ============================================================

-- ============================================================
-- 1) CONFERIR RESTRIÇÕES ÚNICAS QUE ENVOLVEM CPF NA PEDIATRIA
-- ============================================================

SELECT
    con.conname AS nome_restricao,
    con.contype AS tipo,
    pg_get_constraintdef(con.oid) AS definicao
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'public'
  AND rel.relname = 'pacientes_pediatria'
  AND con.contype = 'u'
  AND pg_get_constraintdef(con.oid) ILIKE '%cpf%';

-- ============================================================
-- 2) REMOVER RESTRIÇÕES UNIQUE DE CPF NA TABELA pacientes_pediatria
-- ============================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT con.conname
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE nsp.nspname = 'public'
          AND rel.relname = 'pacientes_pediatria'
          AND con.contype = 'u'
          AND pg_get_constraintdef(con.oid) ILIKE '%cpf%'
    LOOP
        EXECUTE format('ALTER TABLE public.pacientes_pediatria DROP CONSTRAINT IF EXISTS %I', r.conname);
        RAISE NOTICE 'Restrição removida: %', r.conname;
    END LOOP;
END $$;

-- ============================================================
-- 3) CONFERIR ÍNDICES ÚNICOS DE CPF NA PEDIATRIA
-- ============================================================

SELECT
    idx.indexname AS nome_indice,
    idx.indexdef AS definicao
FROM pg_indexes idx
WHERE idx.schemaname = 'public'
  AND idx.tablename = 'pacientes_pediatria'
  AND idx.indexdef ILIKE 'CREATE UNIQUE INDEX%'
  AND idx.indexdef ILIKE '%cpf%';

-- ============================================================
-- 4) REMOVER ÍNDICES ÚNICOS DE CPF QUE NÃO SEJAM CONSTRAINTS
-- ============================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT idx.indexname
        FROM pg_indexes idx
        WHERE idx.schemaname = 'public'
          AND idx.tablename = 'pacientes_pediatria'
          AND idx.indexdef ILIKE 'CREATE UNIQUE INDEX%'
          AND idx.indexdef ILIKE '%cpf%'
          AND idx.indexname NOT IN (
              SELECT con.conname
              FROM pg_constraint con
              JOIN pg_class rel ON rel.oid = con.conrelid
              JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
              WHERE nsp.nspname = 'public'
                AND rel.relname = 'pacientes_pediatria'
          )
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS public.%I', r.indexname);
        RAISE NOTICE 'Índice único removido: %', r.indexname;
    END LOOP;
END $$;

-- ============================================================
-- 5) GARANTIR UM ÍNDICE NORMAL PARA BUSCA POR CPF, SEM UNIQUE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_pacientes_pediatria_cpf
ON public.pacientes_pediatria (cpf);

-- ============================================================
-- 6) CONFERÊNCIA FINAL
-- ============================================================

-- Deve retornar ZERO linhas. Se retornar alguma linha, ainda existe
-- alguma restrição/índice UNIQUE envolvendo CPF na odontopediatria.
SELECT
    'constraint_unique_cpf' AS origem,
    con.conname AS nome,
    pg_get_constraintdef(con.oid) AS definicao
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'public'
  AND rel.relname = 'pacientes_pediatria'
  AND con.contype = 'u'
  AND pg_get_constraintdef(con.oid) ILIKE '%cpf%'

UNION ALL

SELECT
    'index_unique_cpf' AS origem,
    idx.indexname AS nome,
    idx.indexdef AS definicao
FROM pg_indexes idx
WHERE idx.schemaname = 'public'
  AND idx.tablename = 'pacientes_pediatria'
  AND idx.indexdef ILIKE 'CREATE UNIQUE INDEX%'
  AND idx.indexdef ILIKE '%cpf%';

-- Conferir se o índice normal de busca por CPF existe.
SELECT
    indexname AS nome_indice,
    indexdef AS definicao
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'pacientes_pediatria'
  AND indexname = 'idx_pacientes_pediatria_cpf';
