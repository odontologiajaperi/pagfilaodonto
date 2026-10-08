# SQL do projeto — por onde começar

**Não execute os arquivos desta pasta em produção em lote.** O diretório `historico/` guarda scripts que documentam versões anteriores; **não é um instalador** e seu conteúdo não é necessariamente o estado atual do Supabase. O estado efetivo é o das tabelas, funções, triggers, permissões e jobs do banco vivo.

## Estrutura

| Pasta | Finalidade |
|---|---|
| [`../migrations/`](../migrations/) | Mudanças pontuais versionadas, com situação de execução e testes descritos no [`README`](../migrations/README.md). |
| [`historico/fila-vagas/`](historico/fila-vagas/) | Rascunhos e versões antigas de posições, limpeza, postos, ACS e CPFs. **Não reaplicar** para “consertar vagas”. |
| [`historico/gestantes/`](historico/gestantes/) | Definições e políticas antigas de gestantes. |
| [`historico/seguranca-configuracao/`](historico/seguranca-configuracao/) | Políticas RLS e abertura/fechamento; executar versões antigas pode mudar permissões do site. |
| [`historico/remarcacao/`](historico/remarcacao/) | Histórico da remarcação; não substituir a migração aditiva atual por esses arquivos. |
| [`historico/avaliacoes/`](historico/avaliacoes/) | Versões da avaliação de atendimento. |
| [`historico/logs-acessos/`](historico/logs-acessos/) | Log de erros e rastreamento de acessos. |
| [`.github/sql/documentos_remarcacao.sql`](../.github/sql/documentos_remarcacao.sql) | Arquivo original fora da raiz, mantido no caminho prévio. Tratar como histórico até revisão específica. |

Os **25 arquivos antes soltos na raiz** foram movidos, sem alteração de conteúdo, para as seis subpastas de `historico/`. Guias que apontavam para eles tiveram apenas os caminhos corrigidos. Essa organização **não executou SQL, não redefiniu vagas nem alterou pacientes**.

O arquivo [`diagnostico_fila.sql`](diagnostico_fila.sql) contém exclusivamente consultas agregadas de leitura para verificar postos, posições, triggers, jobs e permissões, sem listar nomes ou CPFs.

## Fonte de verdade da fila (verificada em 08/10/2026)

- Cadastro normal usa `public.postos.ativo` e `public.postos.vagas_disponiveis`; o trigger canônico `trg_gerenciar_fila_rodada` coordena entrada, saída, reentrada, transferência, posição e saldo. **Não usa `situacao_postos` nem `vagas_limite`** para o contador exibido.
- A rodada canônica registra `postos.rodada_id`/`rodada_capacidade` e marca apenas novos cadastros consumindo vagas com `pacientes.rodada_vaga_id`. Os pacientes anteriores permanecem sem marcador e não são renumerados nem usados para recalcular o saldo.
- O INSERT normal respeita `configuracoes.cadastros_abertos`, e o INSERT pediátrico agora também respeita `configuracoes.cadastros_pediatria_abertos`, inclusive se alguém tentar ignorar o HTML. Os dois interruptores estão `false` neste diagnóstico; **não abrir cadastro por conta própria**.
- A pediatria mantém uma fila global; `processar_agendamento_pediatria` usa o mesmo lock global para saída/reentrada. Os 323 aguardando continuam com posições únicas.
- `trg_limpeza_geral`, `trg_limpeza_pediatria` e o job diário destrutivo estão **desativados**; não religar antes de definir retenção/arquivamento.
- `verificar_cota_sem_acs` usa o máximo da rodada registrada (`20%` ou `25%` de `rodada_capacidade`) e conta apenas cadastros novos marcados nessa rodada. A resposta continua compatível com o cadastro (`disponivel`, `max_sem_acs`, `vagas_restantes_sem_acs`).
- `historico/fila-vagas/vagas_por_posto.sql` calcula pela fila antiga e por `vagas_limite`; **é incompatível com o contador atual. NÃO EXECUTAR**. `INSERT_POSTOS.sql` também contém `DELETE`: não executar como tentativa de ajuste.

Para qualquer correção futura: capturar estado real, definir comportamento desejado de rodada/cota, testar num clone isolado, registrar migração aditiva e conferir posições por unidade antes/depois. Nunca resetar `vagas_disponiveis` a partir de quantidade de pessoas antigas sem decisão de negócio.
