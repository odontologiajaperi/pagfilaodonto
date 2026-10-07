-- Correção de permissão: a função SECURITY DEFINER reabrir_posto
-- estava executável por anon/authenticated e permitia alterar postos.
-- Não altera nenhuma linha de postos, pacientes, vagas ou posições.
BEGIN;
REVOKE EXECUTE ON FUNCTION public.reabrir_posto(text, integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reabrir_posto(text, integer)
  TO service_role;
COMMIT;

-- Verificação após aplicar (apenas leitura):
-- SELECT has_function_privilege('anon','public.reabrir_posto(text,integer)','EXECUTE') AS publico,
--        has_function_privilege('service_role','public.reabrir_posto(text,integer)','EXECUTE') AS servico;
