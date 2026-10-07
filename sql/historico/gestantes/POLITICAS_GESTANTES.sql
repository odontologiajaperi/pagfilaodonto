-- ======================================================
-- POLÍTICAS RLS PARA A TABELA 'gestantes'
-- ======================================================
-- Este script configura a segurança para permitir:
-- 1. Consulta pública de CPF (para evitar duplicados)
-- 2. Inserção pública de novos cadastros
-- ======================================================

-- 1. Habilitar RLS na tabela
ALTER TABLE public.gestantes ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas existentes para evitar conflitos
DROP POLICY IF EXISTS "Permitir select anônimo em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir insert anônimo em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir tudo para administradores em gestantes" ON public.gestantes;

-- 3. Política para SELECT (Consulta de CPF)
-- Permite que o site verifique se um CPF já existe antes de cadastrar
CREATE POLICY "Permitir select anônimo em gestantes" 
ON public.gestantes
FOR SELECT 
TO anon, authenticated
USING (true);

-- 4. Política para INSERT (Novo Cadastro)
-- Permite que qualquer pessoa envie o formulário de cadastro
CREATE POLICY "Permitir insert anônimo em gestantes" 
ON public.gestantes
FOR INSERT 
TO anon, authenticated
WITH CHECK (true);

-- 5. Política para Administradores (Opcional - Ajuste conforme sua role de admin)
-- Se você tiver uma role específica para admins, pode usar aqui
-- Por enquanto, authenticated (logados no dashboard) podem fazer tudo
CREATE POLICY "Permitir tudo para administradores em gestantes" 
ON public.gestantes
FOR ALL 
TO authenticated
USING (true)
WITH CHECK (true);

-- ======================================================
-- VERIFICAÇÃO
-- ======================================================
SELECT 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'gestantes';
