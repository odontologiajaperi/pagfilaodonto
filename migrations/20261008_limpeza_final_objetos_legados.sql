BEGIN;

-- Os gatilhos de limpeza já estavam desativados; removê-los evita reativação acidental.
DROP TRIGGER IF EXISTS trg_limpeza_geral ON public.pacientes;
DROP TRIGGER IF EXISTS trg_limpeza_pediatria ON public.pacientes_pediatria;

-- O job estava inativo, mas sua definição apontava para uma função destrutiva.
DO $$
DECLARE v_job_id bigint;
BEGIN
  SELECT jobid INTO v_job_id
    FROM cron.job
   WHERE jobname = 'limpar-pacientes-agendados-apos-2-dias'
   LIMIT 1;
  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;
END $$;

-- Views antigas calculavam vagas por vagas_limite e pela fila histórica.
-- Mantemos os mesmos nomes, mas a fonte operacional passa a ser a rodada atual.
DROP VIEW IF EXISTS public.situacao_postos;
DROP VIEW IF EXISTS public.situacao_vagas_sem_acs;

CREATE VIEW public.situacao_postos AS
SELECT
  p.id,
  p.nome,
  p.ativo,
  p.vagas_limite,
  COUNT(pac.id) FILTER (
    WHERE pac.status = 'aguardando'
      AND pac.rodada_vaga_id IS NOT DISTINCT FROM p.rodada_id
  ) AS inscritos_aguardando,
  p.vagas_disponiveis AS vagas_restantes,
  p.vagas_disponiveis,
  p.rodada_id,
  p.rodada_capacidade
FROM public.postos p
LEFT JOIN public.pacientes pac
  ON btrim(pac.unidade_preferencia) = btrim(p.nome)
GROUP BY
  p.id, p.nome, p.ativo, p.vagas_limite,
  p.vagas_disponiveis, p.rodada_id, p.rodada_capacidade
ORDER BY p.nome;

CREATE VIEW public.situacao_vagas_sem_acs AS
WITH usados AS (
  SELECT
    p.unidade_preferencia,
    p.rodada_vaga_id,
    COUNT(*) AS total
  FROM public.pacientes p
  WHERE p.sem_acs IS TRUE
    AND p.status = 'aguardando'
  GROUP BY p.unidade_preferencia, p.rodada_vaga_id
)
SELECT
  posto.id,
  posto.nome,
  posto.ativo,
  posto.vagas_limite,
  posto.percentual_sem_acs,
  CASE
    WHEN posto.rodada_capacidade > 0
      THEN GREATEST(1, FLOOR(posto.rodada_capacidade::numeric * posto.percentual_sem_acs / 100)::integer)
    ELSE 0
  END AS max_vagas_sem_acs,
  COALESCE(usados.total, 0) AS inscritos_sem_acs,
  CASE
    WHEN posto.rodada_capacidade > 0
      THEN GREATEST(
        0,
        GREATEST(1, FLOOR(posto.rodada_capacidade::numeric * posto.percentual_sem_acs / 100)::integer)
        - COALESCE(usados.total, 0)
      )
    ELSE 0
  END AS vagas_sem_acs_restantes,
  CASE
    WHEN posto.percentual_sem_acs IS NULL OR posto.percentual_sem_acs NOT BETWEEN 0 AND 100
      THEN 'Sem restrição'
    WHEN COALESCE(usados.total, 0) >= GREATEST(1, FLOOR(posto.rodada_capacidade::numeric * posto.percentual_sem_acs / 100)::integer)
      THEN 'COTA ESGOTADA'
    ELSE 'Disponível'
  END AS status_cota_sem_acs,
  posto.vagas_disponiveis,
  posto.rodada_id,
  posto.rodada_capacidade
FROM public.postos posto
LEFT JOIN usados
  ON usados.unidade_preferencia = posto.nome
 AND usados.rodada_vaga_id IS NOT DISTINCT FROM posto.rodada_id
ORDER BY posto.nome;

GRANT SELECT ON public.situacao_postos TO anon, authenticated;
GRANT SELECT ON public.situacao_vagas_sem_acs TO anon, authenticated;

-- Funções antigas sem trigger ativo, job ativo ou chamada no site.
DROP FUNCTION IF EXISTS public.atribuir_posicao_fila_integrada();
DROP FUNCTION IF EXISTS public.atribuir_posicao_fila_unidade();
DROP FUNCTION IF EXISTS public.atualizar_vagas_disponiveis();
DROP FUNCTION IF EXISTS public.corrigir_fila_unidade(text);
DROP FUNCTION IF EXISTS public.executar_limpeza_automatica();
DROP FUNCTION IF EXISTS public.gerenciar_limite_inscricoes_posto();
DROP FUNCTION IF EXISTS public.gerenciar_vagas_posto();
DROP FUNCTION IF EXISTS public.limpar_agendados_passados();
DROP FUNCTION IF EXISTS public.limpar_agendamentos_passados();
DROP FUNCTION IF EXISTS public.limpar_pacientes_agendados_apos_2_dias();
DROP FUNCTION IF EXISTS public.limpar_pediatria_antigos();
DROP FUNCTION IF EXISTS public.mover_paciente_na_fila(uuid, integer);
DROP FUNCTION IF EXISTS public.processar_agendamento_e_limpeza();
DROP FUNCTION IF EXISTS public.processar_agendamento_e_reorganizar();
DROP FUNCTION IF EXISTS public.reorganizar_fila_ao_agendar();
DROP FUNCTION IF EXISTS public.reorganizar_fila_apos_agendamento();
DROP FUNCTION IF EXISTS public.reorganizar_fila_completa_por_unidade(text);
DROP FUNCTION IF EXISTS public.reparar_fila_pediatria();
DROP FUNCTION IF EXISTS public.reparar_fila_unidade(text);
DROP FUNCTION IF EXISTS public.reabrir_posto(text, integer);
DROP FUNCTION IF EXISTS public.trg_limpar_pacientes_agendados_apos_2_dias();

COMMIT;
