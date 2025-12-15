-- ========================================
-- SCRIPT PARA INSERIR POSTOS DE SAÚDE
-- ========================================
-- Execute este script no Supabase SQL Editor
-- ========================================

-- Limpar tabela de postos (CUIDADO: Remove todos os registros existentes!)
-- DELETE FROM public.postos;

-- Inserir os postos de saúde
INSERT INTO public.postos (nome, ativo) VALUES
('Unidade Odontológica móvel do Rio D''ouro', true),
('Alecrim', true),
('Vila Central', true),
('Japeri Centro', true),
('Chacrinha', true),
('Unidade Odontológica móvel do Laranjal', true),
('Unidade Odontológica móvel do Marajoara', true),
('Marabá', true);

-- Verificar se os postos foram inseridos corretamente
SELECT * FROM public.postos ORDER BY nome;

-- ========================================
-- NOTAS:
-- ========================================
-- - Todos os postos foram criados como ativos (ativo = true)
-- - O campo 'id' é gerado automaticamente (UUID)
-- - O campo 'created_at' é preenchido automaticamente
-- - Os nomes dos postos foram extraídos da imagem fornecida
-- ========================================
