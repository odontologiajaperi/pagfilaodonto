-- ========================================
-- SCRIPT PARA VERIFICAR STATUS DO RLS
-- ========================================
-- Use este script para verificar se o RLS está configurado corretamente
-- ========================================

-- ========================================
-- 1. VERIFICAR SE RLS ESTÁ HABILITADO NAS TABELAS
-- ========================================

SELECT 
    schemaname as "Schema",
    tablename as "Tabela",
    CASE 
        WHEN rowsecurity THEN '✅ HABILITADO'
        ELSE '❌ DESABILITADO'
    END as "Status RLS"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('pacientes', 'gestantes', 'postos', 'configuracoes', 'administradores')
ORDER BY tablename;

-- ========================================
-- 2. LISTAR TODAS AS POLÍTICAS CRIADAS
-- ========================================

SELECT 
    tablename as "Tabela",
    policyname as "Nome da Política",
    CASE 
        WHEN cmd = 'SELECT' THEN '📖 Leitura (SELECT)'
        WHEN cmd = 'INSERT' THEN '➕ Inserção (INSERT)'
        WHEN cmd = 'UPDATE' THEN '✏️ Atualização (UPDATE)'
        WHEN cmd = 'DELETE' THEN '🗑️ Exclusão (DELETE)'
        WHEN cmd = 'ALL' THEN '🔓 Todas as Operações'
        ELSE cmd
    END as "Operação",
    CASE 
        WHEN roles::text LIKE '%public%' THEN '🌐 Público'
        WHEN roles::text LIKE '%authenticated%' THEN '🔒 Autenticado'
        WHEN roles::text LIKE '%anon%' THEN '👤 Anônimo'
        ELSE roles::text
    END as "Quem Pode Acessar",
    permissive as "Permissivo"
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('pacientes', 'gestantes', 'postos', 'configuracoes', 'administradores')
ORDER BY tablename, cmd;

-- ========================================
-- 3. CONTAR POLÍTICAS POR TABELA
-- ========================================

SELECT 
    tablename as "Tabela",
    COUNT(*) as "Total de Políticas",
    COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as "SELECT",
    COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as "INSERT",
    COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as "UPDATE",
    COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as "DELETE"
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('pacientes', 'gestantes', 'postos', 'configuracoes', 'administradores')
GROUP BY tablename
ORDER BY tablename;

-- ========================================
-- 4. VERIFICAR POLÍTICAS PÚBLICAS (MAIS IMPORTANTES)
-- ========================================

SELECT 
    tablename as "Tabela",
    policyname as "Política Pública",
    CASE 
        WHEN cmd = 'SELECT' THEN 'Leitura'
        WHEN cmd = 'INSERT' THEN 'Inserção'
        WHEN cmd = 'UPDATE' THEN 'Atualização'
        WHEN cmd = 'DELETE' THEN 'Exclusão'
        ELSE cmd
    END as "Operação"
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('pacientes', 'gestantes', 'postos', 'configuracoes', 'administradores')
AND roles::text LIKE '%public%'
ORDER BY tablename, cmd;

-- ========================================
-- 5. VERIFICAR SE HÁ TABELAS SEM POLÍTICAS
-- ========================================

SELECT 
    t.tablename as "Tabela",
    CASE 
        WHEN p.tablename IS NULL THEN '⚠️ SEM POLÍTICAS'
        ELSE '✅ COM POLÍTICAS'
    END as "Status"
FROM pg_tables t
LEFT JOIN (
    SELECT DISTINCT tablename 
    FROM pg_policies 
    WHERE schemaname = 'public'
) p ON t.tablename = p.tablename
WHERE t.schemaname = 'public'
AND t.tablename IN ('pacientes', 'gestantes', 'postos', 'configuracoes', 'administradores')
ORDER BY t.tablename;

-- ========================================
-- 6. RESULTADO ESPERADO
-- ========================================
/*

TABELA           | TOTAL POLÍTICAS | SELECT | INSERT | UPDATE | DELETE
-----------------|-----------------|--------|--------|--------|--------
pacientes        |       4         |   1    |   1    |   1    |   1
gestantes        |       4         |   1    |   1    |   1    |   1
postos           |       4         |   1    |   1    |   1    |   1
configuracoes    |       4         |   1    |   1    |   1    |   1
administradores  |       4         |   1    |   1    |   1    |   1

POLÍTICAS PÚBLICAS ESPERADAS:
- pacientes: INSERT, SELECT
- gestantes: INSERT, SELECT
- postos: SELECT
- configuracoes: SELECT
- administradores: NENHUMA (todas restritas)

*/

-- ========================================
-- 7. DIAGNÓSTICO RÁPIDO
-- ========================================

DO $$
DECLARE
    pacientes_count INT;
    gestantes_count INT;
    postos_count INT;
    configuracoes_count INT;
    administradores_count INT;
BEGIN
    SELECT COUNT(*) INTO pacientes_count FROM pg_policies WHERE tablename = 'pacientes';
    SELECT COUNT(*) INTO gestantes_count FROM pg_policies WHERE tablename = 'gestantes';
    SELECT COUNT(*) INTO postos_count FROM pg_policies WHERE tablename = 'postos';
    SELECT COUNT(*) INTO configuracoes_count FROM pg_policies WHERE tablename = 'configuracoes';
    SELECT COUNT(*) INTO administradores_count FROM pg_policies WHERE tablename = 'administradores';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DIAGNÓSTICO DO RLS';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'pacientes: % políticas', pacientes_count;
    RAISE NOTICE 'gestantes: % políticas', gestantes_count;
    RAISE NOTICE 'postos: % políticas', postos_count;
    RAISE NOTICE 'configuracoes: % políticas', configuracoes_count;
    RAISE NOTICE 'administradores: % políticas', administradores_count;
    RAISE NOTICE '========================================';
    
    IF pacientes_count = 4 AND gestantes_count = 4 AND postos_count = 4 
       AND configuracoes_count = 4 AND administradores_count = 4 THEN
        RAISE NOTICE '✅ TODAS AS POLÍTICAS ESTÃO CONFIGURADAS CORRETAMENTE!';
    ELSE
        RAISE NOTICE '⚠️ ALGUMAS POLÍTICAS ESTÃO FALTANDO!';
        RAISE NOTICE 'Execute o script: sql_configurar_rls_completo.sql';
    END IF;
    RAISE NOTICE '========================================';
END $$;
