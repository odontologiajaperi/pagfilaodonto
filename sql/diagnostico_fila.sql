-- DIAGNÓSTICO DA FILA (somente leitura). Execute cada SELECT separadamente
-- no SQL Editor, caso queira conferir invariantes. Nenhum dado pessoal sai.
-- Postos e contador público: nunca recalcular vagas pela fila histórica.
SELECT nome, ativo, vagas_disponiveis, vagas_limite, percentual_sem_acs
  FROM public.postos ORDER BY nome LIMIT 100;

-- Normal: posições duplicadas/nulas e unidades com lacunas.
WITH q AS (
 SELECT unidade_preferencia, count(*) AS aguardando,
        count(*) FILTER (WHERE posicao_fila IS NULL OR posicao_fila<=0) AS invalidas,
        count(DISTINCT posicao_fila) AS distintas,
        min(posicao_fila) AS primeira, max(posicao_fila) AS ultima
   FROM public.pacientes WHERE status='aguardando'
  GROUP BY unidade_preferencia
)
SELECT unidade_preferencia, aguardando, invalidas,
       aguardando-invalidas-distintas AS duplicadas, primeira, ultima
  FROM q ORDER BY unidade_preferencia LIMIT 100;

-- Pediatria: fila única, posições independentes das unidades.
SELECT count(*) AS aguardando,
       count(*) FILTER (WHERE posicao_fila IS NULL OR posicao_fila<=0) AS invalidas,
       count(DISTINCT posicao_fila) AS distintas,
       min(posicao_fila) AS primeira, max(posicao_fila) AS ultima
  FROM public.pacientes_pediatria
 WHERE lower(trim(status))='aguardando' LIMIT 1;

-- Triggers ativos/desativados: só os gatilhos operacionais de fila.
SELECT c.relname AS tabela,t.tgname AS trigger,t.tgenabled,
       pg_get_triggerdef(t.oid) AS definicao
  FROM pg_trigger t
  JOIN pg_class c ON c.oid=t.tgrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relname IN ('pacientes','pacientes_pediatria','postos')
   AND NOT t.tgisinternal
 ORDER BY c.relname,t.tgname LIMIT 100;

-- Job de limpeza, que permanece pausado.
SELECT jobname,schedule,active,command FROM cron.job ORDER BY jobname LIMIT 100;

-- Acesso da chave pública à reabertura privilegiada (deve ser false).
SELECT has_function_privilege('anon','public.reabrir_posto(text,integer)','EXECUTE') AS publico_pode_reabrir,
       has_function_privilege('service_role','public.reabrir_posto(text,integer)','EXECUTE') AS servico_pode_reabrir
 LIMIT 1;

-- Unidades históricas cujo nome não coincide literalmente com postos;
-- não renomear pacientes automaticamente.
SELECT pa.unidade_preferencia, count(*) AS aguardando
  FROM public.pacientes pa LEFT JOIN public.postos p ON p.nome=pa.unidade_preferencia
 WHERE pa.status='aguardando' AND p.id IS NULL
 GROUP BY pa.unidade_preferencia ORDER BY pa.unidade_preferencia LIMIT 100;
