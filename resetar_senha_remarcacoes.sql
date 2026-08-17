-- ============================================================
-- REDEFINIR ACESSO DO PAINEL DE REMARCAÇÕES
-- ============================================================
-- Este script NÃO altera nem apaga solicitações de remarcação.
-- Ele apenas define novamente a senha do painel como: japeri2026
-- Execute uma única vez no SQL Editor do Supabase.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.admin_config (
    id SERIAL PRIMARY KEY,
    chave TEXT UNIQUE NOT NULL,
    valor TEXT NOT NULL
);

-- Redefine a senha, substituindo qualquer hash antigo incompatível.
INSERT INTO public.admin_config (chave, valor)
VALUES ('senha_admin_remarcacoes', crypt('japeri2026', gen_salt('bf')))
ON CONFLICT (chave)
DO UPDATE SET valor = EXCLUDED.valor;

-- Mantém compatibilidade com hashes antigos e valida hashes novos em bcrypt.
CREATE OR REPLACE FUNCTION public.verificar_senha_admin(p_senha TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hash_salvo TEXT;
BEGIN
    SELECT valor INTO v_hash_salvo
    FROM public.admin_config
    WHERE chave = 'senha_admin_remarcacoes';

    IF v_hash_salvo IS NULL THEN
        RETURN false;
    END IF;

    IF v_hash_salvo LIKE '$2%' THEN
        RETURN crypt(p_senha, v_hash_salvo) = v_hash_salvo;
    END IF;

    RETURN encode(digest(p_senha, 'sha256'), 'hex') = v_hash_salvo;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verificar_senha_admin(TEXT) TO anon, authenticated;

-- Confirmação: o resultado precisa ser true.
SELECT public.verificar_senha_admin('japeri2026') AS senha_aceita;
