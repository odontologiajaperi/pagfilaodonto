-- ============================================================
-- RECUPERAR ACESSO AO PAINEL DE REMARCAÇÕES (COMPATÍVEL)
-- ============================================================
-- Execute este arquivo inteiro no SQL Editor do Supabase.
-- Não altera nem apaga solicitações de remarcação.
-- Redefine a senha do painel para: japeri2026
-- ============================================================

CREATE TABLE IF NOT EXISTS public.admin_config (
    id SERIAL PRIMARY KEY,
    chave TEXT UNIQUE NOT NULL,
    valor TEXT NOT NULL
);

-- Salva o hash SHA-256 da senha, sem usar crypt/bcrypt.
INSERT INTO public.admin_config (chave, valor)
VALUES (
    'senha_admin_remarcacoes',
    encode(sha256('japeri2026'::bytea), 'hex')
)
ON CONFLICT (chave)
DO UPDATE SET valor = EXCLUDED.valor;

-- Recria a função RPC que o painel chama para validar a senha.
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

    RETURN COALESCE(
        v_hash_salvo = encode(sha256(p_senha::bytea), 'hex'),
        false
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verificar_senha_admin(TEXT) TO anon, authenticated;

-- Verificação: precisa retornar true.
SELECT public.verificar_senha_admin('japeri2026') AS senha_aceita;
