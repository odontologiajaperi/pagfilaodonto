-- ========================================
-- CORREÇÃO DAS POLÍTICAS RLS
-- Problema: Políticas estavam usando TO public ao invés de TO anon
-- Solução: Recriar políticas para permitir acesso anônimo (não autenticado)
-- ========================================

-- ========================================
-- IMPORTANTE: Execute este script no Supabase SQL Editor
-- ========================================

-- ========================================
-- 1. REMOVER POLÍTICAS ANTIGAS DE SELECT
-- ========================================

DROP POLICY IF EXISTS "Permitir select público em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir select público em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir select público em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir select público em configuracoes" ON public.configuracoes;

-- ========================================
-- 2. REMOVER POLÍTICAS ANTIGAS DE INSERT
-- ========================================

DROP POLICY IF EXISTS "Permitir insert público em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir insert público em gestantes" ON public.gestantes;

-- ========================================
-- 3. RECRIAR POLÍTICAS COM ACESSO ANÔNIMO CORRETO
-- ========================================

-- TABELA: pacientes
-- Permitir SELECT para usuários anônimos (consulta de fila)
CREATE POLICY "Permitir select anônimo em pacientes" 
ON public.pacientes
FOR SELECT
TO anon, authenticated
USING (true);

-- Permitir INSERT para usuários anônimos (cadastro)
CREATE POLICY "Permitir insert anônimo em pacientes" 
ON public.pacientes
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- ========================================

-- TABELA: gestantes
-- Permitir SELECT para usuários anônimos (validação de CPF)
CREATE POLICY "Permitir select anônimo em gestantes" 
ON public.gestantes
FOR SELECT
TO anon, authenticated
USING (true);

-- Permitir INSERT para usuários anônimos (cadastro)
CREATE POLICY "Permitir insert anônimo em gestantes" 
ON public.gestantes
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- ========================================

-- TABELA: postos
-- Permitir SELECT para usuários anônimos (listar postos)
CREATE POLICY "Permitir select anônimo em postos" 
ON public.postos
FOR SELECT
TO anon, authenticated
USING (true);

-- ========================================

-- TABELA: configuracoes
-- Permitir SELECT para usuários anônimos (verificar se cadastros estão abertos)
CREATE POLICY "Permitir select anônimo em configuracoes" 
ON public.configuracoes
FOR SELECT
TO anon, authenticated
USING (true);

-- ========================================
-- 4. VERIFICAR POLÍTICAS CRIADAS
-- ========================================

SELECT 
    tablename,
    policyname,
    cmd as comando,
    roles as aplicado_para,
    CASE 
        WHEN cmd = 'SELECT' THEN '🔍 Leitura'
        WHEN cmd = 'INSERT' THEN '➕ Inserção'
        WHEN cmd = 'UPDATE' THEN '✏️ Atualização'
        WHEN cmd = 'DELETE' THEN '🗑️ Exclusão'
        ELSE cmd
    END as operacao
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN ('pacientes', 'gestantes', 'postos', 'configuracoes')
ORDER BY tablename, cmd;

-- ========================================
-- EXPLICAÇÃO DO PROBLEMA
-- ========================================
/*

❌ PROBLEMA ANTERIOR:
   As políticas usavam "TO public" que não funciona para acesso anônimo
   via API do Supabase. O Supabase usa a role "anon" para usuários
   não autenticados.

✅ SOLUÇÃO:
   Usar "TO anon, authenticated" permite que:
   - anon: Usuários não autenticados (site público)
   - authenticated: Usuários autenticados (painel admin)
   
   Ambos possam acessar os dados conforme necessário.

📝 NOTA:
   As políticas de UPDATE e DELETE para admins não foram alteradas,
   pois já estavam corretas usando "TO authenticated".

*/

-- ========================================
-- FIM DO SCRIPT
-- ========================================
