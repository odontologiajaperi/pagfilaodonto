# Fila odontológica — estado verificado em 07/10/2026

**Escopo:** SQL e funções da fila do projeto Supabase `uakhmgoxgyklggsvtwdf`, comparados com o código do site. Este documento não contém registros pessoais e não é comando para reabrir inscrições.

## O que foi efetivamente corrigido

1. **SQL organizado:** 25 scripts da raiz foram movidos sem modificar conteúdo para `sql/historico/` por assunto. Restaram zero `.sql` na raiz. O histórico não deve ser aplicado em lote; especialmente `vagas_por_posto.sql` é incompatível com o contador atual e `INSERT_POSTOS.sql` contém DELETE.
2. **Segurança de postos:** `reabrir_posto(text,integer)` era `SECURITY DEFINER` e executável por `anon`. Foi revogado para `anon` e `authenticated`, preservado `service_role`; a página pública não chama essa função. Nenhuma vaga foi mudada.
3. **Posições de novas inscrições:** a fila normal serializa por unidade e a pediatria por fila global via advisory lock transacional. O banco ignora posição positiva enviada no INSERT aguardando. Testes locais de 64 inscrições fictícias e 32 inscrições num clone de metadados do backup produziram posições únicas e preservaram as antigas.
4. **Integridade do contador:** `postos.vagas_disponiveis` não aceita NULL nem número negativo. Os 17 postos e a soma de 419 vagas não mudaram na migração.
5. **Abertura da fila:** inserts normais falham se `cadastros_abertos` não for `true`; os pediátricos passaram a validar `cadastros_pediatria_abertos` no banco, e não apenas no HTML. Ambos os interruptores estão `false`. A tabela `gestantes` não foi modificada.
6. **Limpezas destrutivas:** dois triggers e um job diário permanecem pausados; posição e contador existentes não foram reordenados.

Veja a lista exata de migrations **aplicadas** em [`../migrations/README.md`](../migrations/README.md) e as consultas agregadas de acompanhamento em [`diagnostico_fila.sql`](diagnostico_fila.sql).

## Estado e problemas ainda não resolvidos

- Normal: **1.440 aguardando em 14 unidades**; pediatria: **323 aguardando**. Não havia duplicatas ou posições nulas. Duas unidades normais começam em 2: **não foram renumeradas**. Há 80 aguardando em três nomes históricos sem correspondente literal em `postos`; não foram movidos.
- O contador visível é **`postos.vagas_disponiveis`**. `vagas_limite` permanece em alguns postos por legado; **não serve** para recalcular o contador da rodada. `situacao_postos` também é uma view legada para esse fim.
- `trg_atualizar_vagas_disponiveis` consome em INSERT aguardando e devolve quando sai de aguardando, mas **não trata reentrada ou transferência de unidade**. Se aplicarmos somente uma correção parcial, pode haver crédito indevido, divergência do contador ou deadlock.
- `trg_processar_agendamento` e `trg_processar_agendamento_pediatria` ainda deslocam posições de quem ficou aguardando sem adquirir os mesmos locks dos novos INSERTs. **Não há garantia completa de consistência em saídas/transferências simultâneas**. Adicionar um lock apenas nesses triggers, depois de obter o lock de `postos`, poderia causar deadlock. É necessária uma ordem única de locks e ensaio de concorrência.
- `verificar_cota_sem_acs` calcula percentual sobre `vagas_limite` e conta a fila histórica; em postos com limite nulo, libera sem cota. Não existe tamanho inicial da rodada para todos os postos, de modo que **não há como calcular uma cota fiel da rodada atual só a partir das vagas restantes**.
- O cadastro normal e pediátrico permanecem fechados pela configuração. **Não liguei os interruptores nem alterei HTML do cadastro.**

## Decisões para completar as transições da fila

Para implementar uma função única/compatível de entrada, saída, reentrada e transferência **sem recontar pacientes antigos nem mexer na ordem atual**, precisamos estabelecer:

1. Quando alguém deixa `aguardando` (agendado/atendido/cancelado), **a vaga da rodada volta sempre**, somente se aquele registro consumiu vaga nesta rodada, ou **não volta**? A regra atual devolve em toda saída, inclusive de cadastros históricos da mesma unidade.
2. Se a pessoa muda de unidade enquanto aguarda, recomendamos **ir ao fim da fila de destino**, devolver vaga à origem somente quando apropriado e exigir vaga no destino; se o destino estiver lotado, o UPDATE deve falhar por inteiro. Confirmar essa política.
3. A cota **sem ACS** deve permanecer (20% em alguns postos e 25% em outros), calculada por **total inicial por rodada**? Se sim, é preciso informar/registrar a capacidade de cada nova rodada e quais cadastros a consomem. Alternativa é retirar a cota especial e aplicar somente o contador geral.

Até essas escolhas, as correções de transição serão preparadas e testadas separadamente, **não implantadas em produção**. Nenhum SQL histórico será usado para resetar vagas ou posições.
