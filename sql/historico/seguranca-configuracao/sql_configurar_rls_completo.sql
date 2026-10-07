-- ========================================
-- CONFIGURAÇÃO COMPLETA DE RLS
-- Row Level Security para todas as tabelas
-- ========================================
-- Sistema de Fila Odontológica - Japeri
-- ========================================

-- ========================================
-- IMPORTANTE: Execute este script no Supabase SQL Editor
-- ========================================

-- ========================================
-- 1. TABELA: pacientes
-- ========================================
-- Permite cadastro público, mas apenas admins podem editar/deletar

-- Habilitar RLS
ALTER TABLE public.pacientes ENABLE ROW LEVEL SECURITY;

-- Permitir INSERT público (cadastro de pacientes)
CREATE POLICY "Permitir insert público em pacientes" 
ON public.pacientes
FOR INSERT
TO public
WITH CHECK (true);

-- Permitir SELECT público (validação de CPF e consulta de fila)
CREATE POLICY "Permitir select público em pacientes" 
ON public.pacientes
FOR SELECT
TO public
USING (true);

-- Permitir UPDATE apenas para administradores autenticados
CREATE POLICY "Permitir update apenas para admins em pacientes" 
ON public.pacientes
FOR UPDATE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
)
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir DELETE apenas para administradores autenticados
CREATE POLICY "Permitir delete apenas para admins em pacientes" 
ON public.pacientes
FOR DELETE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- ========================================
-- 2. TABELA: gestantes
-- ========================================
-- Permite cadastro público, mas apenas admins podem editar/deletar

-- Habilitar RLS
ALTER TABLE public.gestantes ENABLE ROW LEVEL SECURITY;

-- Permitir INSERT público (cadastro de gestantes)
CREATE POLICY "Permitir insert público em gestantes" 
ON public.gestantes
FOR INSERT
TO public
WITH CHECK (true);

-- Permitir SELECT público (validação de CPF)
CREATE POLICY "Permitir select público em gestantes" 
ON public.gestantes
FOR SELECT
TO public
USING (true);

-- Permitir UPDATE apenas para administradores autenticados
CREATE POLICY "Permitir update apenas para admins em gestantes" 
ON public.gestantes
FOR UPDATE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
)
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir DELETE apenas para administradores autenticados
CREATE POLICY "Permitir delete apenas para admins em gestantes" 
ON public.gestantes
FOR DELETE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- ========================================
-- 3. TABELA: postos
-- ========================================
-- Apenas leitura pública, admins podem gerenciar

-- Habilitar RLS
ALTER TABLE public.postos ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT público (listar postos no formulário)
CREATE POLICY "Permitir select público em postos" 
ON public.postos
FOR SELECT
TO public
USING (true);

-- Permitir INSERT apenas para administradores autenticados
CREATE POLICY "Permitir insert apenas para admins em postos" 
ON public.postos
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir UPDATE apenas para administradores autenticados
CREATE POLICY "Permitir update apenas para admins em postos" 
ON public.postos
FOR UPDATE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
)
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir DELETE apenas para administradores autenticados
CREATE POLICY "Permitir delete apenas para admins em postos" 
ON public.postos
FOR DELETE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- ========================================
-- 4. TABELA: configuracoes
-- ========================================
-- Apenas leitura pública, admins podem gerenciar

-- Habilitar RLS
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT público (verificar se cadastros estão abertos)
CREATE POLICY "Permitir select público em configuracoes" 
ON public.configuracoes
FOR SELECT
TO public
USING (true);

-- Permitir INSERT apenas para administradores autenticados
CREATE POLICY "Permitir insert apenas para admins em configuracoes" 
ON public.configuracoes
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir UPDATE apenas para administradores autenticados
CREATE POLICY "Permitir update apenas para admins em configuracoes" 
ON public.configuracoes
FOR UPDATE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
)
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir DELETE apenas para administradores autenticados
CREATE POLICY "Permitir delete apenas para admins em configuracoes" 
ON public.configuracoes
FOR DELETE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- ========================================
-- 5. TABELA: administradores
-- ========================================
-- Acesso restrito apenas para administradores autenticados

-- Habilitar RLS
ALTER TABLE public.administradores ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT apenas para administradores autenticados
CREATE POLICY "Permitir select apenas para admins em administradores" 
ON public.administradores
FOR SELECT
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir INSERT apenas para administradores autenticados
CREATE POLICY "Permitir insert apenas para admins em administradores" 
ON public.administradores
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir UPDATE apenas para administradores autenticados
CREATE POLICY "Permitir update apenas para admins em administradores" 
ON public.administradores
FOR UPDATE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
)
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Permitir DELETE apenas para administradores autenticados
CREATE POLICY "Permitir delete apenas para admins em administradores" 
ON public.administradores
FOR DELETE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- ========================================
-- VERIFICAÇÃO DAS POLÍTICAS CRIADAS
-- ========================================
-- Execute esta query para verificar todas as políticas

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Leitura'
        WHEN cmd = 'INSERT' THEN 'Inserção'
        WHEN cmd = 'UPDATE' THEN 'Atualização'
        WHEN cmd = 'DELETE' THEN 'Exclusão'
        ELSE cmd
    END as operacao
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- ========================================
-- RESUMO DAS POLÍTICAS
-- ========================================
/*

TABELA: pacientes
  ✅ INSERT - Público (formulário de cadastro)
  ✅ SELECT - Público (validação de CPF, consulta de fila)
  🔒 UPDATE - Apenas administradores
  🔒 DELETE - Apenas administradores

TABELA: gestantes
  ✅ INSERT - Público (formulário de cadastro)
  ✅ SELECT - Público (validação de CPF)
  🔒 UPDATE - Apenas administradores
  🔒 DELETE - Apenas administradores

TABELA: postos
  ✅ SELECT - Público (listar postos no formulário)
  🔒 INSERT - Apenas administradores
  🔒 UPDATE - Apenas administradores
  🔒 DELETE - Apenas administradores

TABELA: configuracoes
  ✅ SELECT - Público (verificar se cadastros estão abertos)
  🔒 INSERT - Apenas administradores
  🔒 UPDATE - Apenas administradores
  🔒 DELETE - Apenas administradores

TABELA: administradores
  🔒 SELECT - Apenas administradores
  🔒 INSERT - Apenas administradores
  🔒 UPDATE - Apenas administradores
  🔒 DELETE - Apenas administradores

*/

-- ========================================
-- FIM DO SCRIPT
-- ========================================
