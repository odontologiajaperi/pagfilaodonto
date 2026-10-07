-- ========================================
-- CORREÇÃO DOS CPFs IMPORTADOS VIA CSV
-- Problema: CPFs foram importados com tamanho incorreto (12 dígitos ao invés de 11)
-- Solução: Remover o primeiro dígito dos CPFs com 12 dígitos
-- ========================================

-- ========================================
-- IMPORTANTE: Execute este script no Supabase SQL Editor
-- ========================================

-- ========================================
-- 1. VERIFICAR CPFs COM TAMANHO INCORRETO
-- ========================================

-- Ver quantos CPFs têm tamanho diferente de 11
SELECT 
    LENGTH(cpf) as tamanho_cpf,
    COUNT(*) as quantidade,
    CASE 
        WHEN LENGTH(cpf) = 11 THEN '✅ Correto'
        WHEN LENGTH(cpf) = 12 THEN '⚠️ 12 dígitos - Remover primeiro'
        WHEN LENGTH(cpf) > 12 THEN '❌ Muito grande - Verificar manualmente'
        WHEN LENGTH(cpf) < 11 THEN '❌ Muito pequeno - Adicionar zeros'
        ELSE '❓ Verificar'
    END as status
FROM public.pacientes
GROUP BY LENGTH(cpf)
ORDER BY tamanho_cpf;

-- ========================================
-- 2. VER EXEMPLOS DE CPFs PROBLEMÁTICOS
-- ========================================

-- Ver alguns exemplos de CPFs com 12 dígitos
SELECT 
    id,
    nome_completo,
    cpf as cpf_atual,
    LENGTH(cpf) as tamanho,
    SUBSTRING(cpf, 2) as cpf_corrigido,
    celular
FROM public.pacientes
WHERE LENGTH(cpf) = 12
LIMIT 10;

-- ========================================
-- 3. CORRIGIR CPFs COM 12 DÍGITOS
-- ========================================

-- ATENÇÃO: Revise os exemplos acima antes de executar esta correção!
-- Esta query remove o PRIMEIRO dígito dos CPFs com 12 dígitos

UPDATE public.pacientes
SET cpf = SUBSTRING(cpf, 2)
WHERE LENGTH(cpf) = 12;

-- ========================================
-- 4. CORRIGIR CPFs COM 10 DÍGITOS (adicionar zero à esquerda)
-- ========================================

UPDATE public.pacientes
SET cpf = LPAD(cpf, 11, '0')
WHERE LENGTH(cpf) = 10;

-- ========================================
-- 5. VERIFICAR RESULTADO FINAL
-- ========================================

-- Verificar se todos os CPFs agora têm 11 dígitos
SELECT 
    LENGTH(cpf) as tamanho_cpf,
    COUNT(*) as quantidade,
    CASE 
        WHEN LENGTH(cpf) = 11 THEN '✅ Correto'
        ELSE '❌ Ainda com problema'
    END as status
FROM public.pacientes
GROUP BY LENGTH(cpf)
ORDER BY tamanho_cpf;

-- ========================================
-- 6. LISTAR CPFs QUE AINDA PRECISAM DE CORREÇÃO MANUAL
-- ========================================

-- Se ainda houver CPFs com tamanho diferente de 11, liste-os aqui
SELECT 
    id,
    nome_completo,
    cpf,
    LENGTH(cpf) as tamanho,
    celular,
    email
FROM public.pacientes
WHERE LENGTH(cpf) != 11
ORDER BY LENGTH(cpf), nome_completo;

-- ========================================
-- EXPLICAÇÃO DO PROBLEMA
-- ========================================
/*

❌ PROBLEMA IDENTIFICADO:
   Os CPFs foram importados do CSV com 12 dígitos ao invés de 11.
   Exemplo: 205480997740 (12 dígitos) → deveria ser 05480997740 (11 dígitos)
   
   O problema ocorreu porque:
   - O CSV pode ter incluído um dígito extra no início
   - Ou os celulares foram colocados na coluna errada
   
✅ SOLUÇÃO:
   Remover o PRIMEIRO dígito dos CPFs com 12 dígitos usando SUBSTRING(cpf, 2)
   
   Exemplos de correção:
   - 205480997740 → 05480997740
   - 219758577010 → 19758577010
   - 181609697080 → 81609697080

📝 NOTA IMPORTANTE:
   Depois de executar este script, teste a consulta de CPF no site.
   Se ainda não funcionar, pode ser que o CPF correto seja diferente.
   Nesse caso, você precisará verificar manualmente alguns registros.

*/

-- ========================================
-- FIM DO SCRIPT
-- ========================================
