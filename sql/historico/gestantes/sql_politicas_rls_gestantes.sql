-- ========================================
-- POLÍTICAS DE SEGURANÇA (RLS) - TABELA GESTANTES
-- ========================================
-- Row Level Security (RLS) para controlar acesso à tabela gestantes
-- ========================================

-- Habilitar RLS na tabela gestantes
ALTER TABLE public.gestantes ENABLE ROW LEVEL SECURITY;

-- ========================================
-- POLÍTICA 1: Permitir INSERT público
-- ========================================
-- Permite que qualquer pessoa cadastre uma gestante através do formulário
CREATE POLICY "Permitir insert público na tabela gestantes" 
ON public.gestantes
FOR INSERT
TO public
WITH CHECK (true);

-- ========================================
-- POLÍTICA 2: Permitir SELECT público
-- ========================================
-- Permite que qualquer pessoa consulte registros (necessário para validação de CPF)
CREATE POLICY "Permitir select público na tabela gestantes" 
ON public.gestantes
FOR SELECT
TO public
USING (true);

-- ========================================
-- POLÍTICA 3: Permitir UPDATE apenas para administradores (OPCIONAL)
-- ========================================
-- Descomente as linhas abaixo se você quiser permitir que apenas
-- administradores possam atualizar registros de gestantes

-- CREATE POLICY "Permitir update apenas para administradores" 
-- ON public.gestantes
-- FOR UPDATE
-- TO authenticated
-- USING (
--     auth.uid() IN (
--         SELECT id FROM public.administradores
--     )
-- );

-- ========================================
-- POLÍTICA 4: Permitir DELETE apenas para administradores (OPCIONAL)
-- ========================================
-- Descomente as linhas abaixo se você quiser permitir que apenas
-- administradores possam deletar registros de gestantes

-- CREATE POLICY "Permitir delete apenas para administradores" 
-- ON public.gestantes
-- FOR DELETE
-- TO authenticated
-- USING (
--     auth.uid() IN (
--         SELECT id FROM public.administradores
--     )
-- );

-- ========================================
-- VERIFICAR POLÍTICAS CRIADAS
-- ========================================
-- Execute a query abaixo para verificar se as políticas foram criadas corretamente

-- SELECT 
--     schemaname,
--     tablename,
--     policyname,
--     permissive,
--     roles,
--     cmd,
--     qual,
--     with_check
-- FROM pg_policies
-- WHERE tablename = 'gestantes';

-- ========================================
-- OBSERVAÇÕES IMPORTANTES:
-- ========================================
-- 1. As políticas de INSERT e SELECT são PÚBLICAS (não requerem autenticação)
-- 2. Isso permite que o formulário funcione sem login
-- 3. Se você quiser restringir UPDATE e DELETE, descomente as políticas 3 e 4
-- 4. Certifique-se de que a tabela 'administradores' existe e está populada
-- ========================================
