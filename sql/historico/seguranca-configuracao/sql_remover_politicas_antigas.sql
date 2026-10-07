-- ========================================
-- SCRIPT PARA REMOVER POLÍTICAS ANTIGAS
-- ========================================
-- Use este script se você precisar limpar políticas antigas
-- antes de aplicar as novas políticas
-- ========================================

-- ========================================
-- REMOVER TODAS AS POLÍTICAS EXISTENTES
-- ========================================

-- Políticas da tabela pacientes
DROP POLICY IF EXISTS "Permitir insert público em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir select público em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir update apenas para admins em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir insert público na tabela pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir select público na tabela pacientes" ON public.pacientes;

-- Políticas da tabela gestantes
DROP POLICY IF EXISTS "Permitir insert público em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir select público em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir update apenas para admins em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir insert público na tabela gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir select público na tabela gestantes" ON public.gestantes;

-- Políticas da tabela postos
DROP POLICY IF EXISTS "Permitir select público em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir insert apenas para admins em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir update apenas para admins em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em postos" ON public.postos;

-- Políticas da tabela configuracoes
DROP POLICY IF EXISTS "Permitir select público em configuracoes" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir insert apenas para admins em configuracoes" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir update apenas para admins em configuracoes" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em configuracoes" ON public.configuracoes;

-- Políticas da tabela administradores
DROP POLICY IF EXISTS "Permitir select apenas para admins em administradores" ON public.administradores;
DROP POLICY IF EXISTS "Permitir insert apenas para admins em administradores" ON public.administradores;
DROP POLICY IF EXISTS "Permitir update apenas para admins em administradores" ON public.administradores;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em administradores" ON public.administradores;

-- ========================================
-- DESABILITAR RLS (OPCIONAL - CUIDADO!)
-- ========================================
-- Descomente as linhas abaixo APENAS se você quiser
-- desabilitar completamente o RLS (não recomendado)

-- ALTER TABLE public.pacientes DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.gestantes DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.postos DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.configuracoes DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.administradores DISABLE ROW LEVEL SECURITY;

-- ========================================
-- VERIFICAR SE AS POLÍTICAS FORAM REMOVIDAS
-- ========================================

SELECT 
    tablename,
    COUNT(*) as total_politicas
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Se retornar 0 políticas para todas as tabelas, a remoção foi bem-sucedida

-- ========================================
-- PRÓXIMO PASSO
-- ========================================
-- Após executar este script, execute o arquivo:
-- sql_configurar_rls_completo.sql
-- ========================================
