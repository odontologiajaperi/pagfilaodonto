-- Executar SOMENTE após a página nova de remarcação estar no ar e testada.
-- Este arquivo foi aplicado em 07/10/2026; preserva funções e registros, revogando apenas EXECUTE público.
-- O cadastro novo usa solicitar_remarcacao(text,text,text,text,date,text), que continua permitido.
-- Não há referências a verificar_cpf_remarcacao no frontend novo.
BEGIN;
REVOKE EXECUTE ON FUNCTION public.verificar_cpf_remarcacao(text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.solicitar_remarcacao(text,text,text,text) FROM PUBLIC, anon, authenticated;
COMMIT;

-- Se precisar VOLTAR TEMPORARIAMENTE ao HTML antigo, executar a reversão isoladamente:
-- GRANT EXECUTE ON FUNCTION public.verificar_cpf_remarcacao(text) TO anon, authenticated;
-- GRANT EXECUTE ON FUNCTION public.solicitar_remarcacao(text,text,text,text) TO anon, authenticated;
-- A RPC antiga revela dados de cadastro a partir de CPF, portanto mantenha a reversão
-- apenas durante o tempo mínimo e planeje uma alternativa autenticada.
