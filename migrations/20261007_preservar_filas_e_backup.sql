-- HISTÓRICO da manutenção de 07/10/2026. Já executado em produção com autorização.
-- NÃO cole todo o repositório SQL no Supabase: scripts legados podem desfazer estas proteções.
-- Estado anterior conferido: 1.611 pacientes, 323 pediátricos, 44 gestantes, 17 postos;
-- tabela pacientes_backup_hoje: 3.639 registros. Todos os dados prioritários já copiados
-- para o repositório de backup PRIVADO, criptografados e com chave separada.
-- Nenhum paciente, posição, agendamento, posto ou vaga foi alterado aqui.

-- Parte A: revogação do acesso público à tabela histórica, aprovada separadamente.
BEGIN;
REVOKE ALL ON TABLE public.pacientes_backup_hoje FROM anon, authenticated;
ALTER TABLE public.pacientes_backup_hoje ENABLE ROW LEVEL SECURITY;
COMMIT;

-- Parte B: pausa reversível de rotinas que apagavam consultas passadas sem arquivamento.
-- NÃO desativar triggers de posição, agendamento, CPF ou vagas.
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE public.pacientes DISABLE TRIGGER trg_limpeza_geral;
ALTER TABLE public.pacientes_pediatria DISABLE TRIGGER trg_limpeza_pediatria;
SELECT cron.alter_job(2, active => false);
COMMIT;

-- Conferência SOMENTE LEITURA (executar isoladamente se necessário):
-- SELECT relname,tgname,tgenabled FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
-- WHERE tgname IN ('trg_limpeza_geral','trg_limpeza_pediatria');
-- SELECT jobid,jobname,active FROM cron.job WHERE jobid=2;
-- SELECT COUNT(*) FROM public.pacientes;
-- SELECT COUNT(*) FROM public.pacientes_pediatria;
-- SELECT COUNT(*) FROM public.pacientes_backup_hoje;

-- REATIVAÇÃO SOMENTE após decisão explícita de retenção e teste: NÃO executar automaticamente.
-- Reativar a lógica antiga causará novamente DELETE de agendamentos passados.
-- ALTER TABLE public.pacientes ENABLE TRIGGER trg_limpeza_geral;
-- ALTER TABLE public.pacientes_pediatria ENABLE TRIGGER trg_limpeza_pediatria;
-- SELECT cron.alter_job(2, active => true);
-- NÃO reabrir a leitura pública da tabela de backup por padrão.
