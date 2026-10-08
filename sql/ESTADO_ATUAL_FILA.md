# Fila odontológica — estado verificado em 08/10/2026

**Escopo:** SQL e funções da fila do projeto Supabase `uakhmgoxgyklggsvtwdf`, comparados com o código do site. Este documento não contém registros pessoais e não é comando para reabrir inscrições.

## O que foi efetivamente corrigido

1. **SQL organizado:** 25 scripts da raiz foram movidos sem modificar conteúdo para `sql/historico/` por assunto. Restaram zero `.sql` na raiz. O histórico não deve ser aplicado em lote; especialmente `vagas_por_posto.sql` é incompatível com o contador atual e `INSERT_POSTOS.sql` contém DELETE.
2. **Segurança de postos:** `reabrir_posto(text,integer)` era `SECURITY DEFINER` e executável por `anon`. Foi revogado para `anon` e `authenticated`, preservado `service_role`; a página pública não chama essa função. Nenhuma vaga foi mudada.
3. **Fila normal canônica:** `trg_gerenciar_fila_rodada` substituiu os três gatilhos anteriores e coordena entrada, saída, reentrada, transferência, posição e contador na mesma transação. A transferência vai para o fim da fila de destino e falha inteira se o destino estiver fechado/sem vaga.
4. **Rodada e contador:** `postos.vagas_disponiveis` continua sendo o saldo operacional. Foram criados `rodada_id` e `rodada_capacidade`; o marco inicial foi o saldo existente de **419 vagas**, sem contar pacientes antigos e sem resetar nenhum saldo. Cadastros novos recebem `pacientes.rodada_vaga_id`; os 1.440 anteriores permanecem sem marcador.
5. **Cota sem ACS:** `verificar_cota_sem_acs` agora usa o máximo de `20%` ou `25%` da capacidade registrada da rodada e retorna `disponivel`, `max_sem_acs` e `vagas_restantes_sem_acs`, compatíveis com o formulário atual. A função não usa `vagas_limite` nem conta a fila histórica.
6. **Posições:** novas entradas recebem posição no banco mesmo que o navegador envie uma posição manual. A pediatria é uma fila global e usa lock global também em saída/reentrada; seus **323 aguardando** continuam com posições únicas.
7. **Integridade do contador:** `postos.vagas_disponiveis` não aceita NULL nem número negativo. Os 17 postos e a soma de 419 vagas permaneceram iguais após a implantação.
8. **Abertura da fila:** inserts normais falham se `cadastros_abertos` não for `true`; pediatria valida `cadastros_pediatria_abertos` no banco, e não apenas no HTML. Ambos os interruptores estão `false`. A tabela `gestantes` não foi modificada.
9. **Limpezas destrutivas:** dois triggers e um job diário permanecem pausados; não houve reordenação, exclusão ou reimportação de pacientes.

Veja a lista exata de migrations **aplicadas** em [`../migrations/README.md`](../migrations/README.md) e as consultas agregadas de acompanhamento em [`diagnostico_fila.sql`](diagnostico_fila.sql).

## Estado preservado

- Normal: **1.440 aguardando em 14 unidades**; pediatria: **323 aguardando**; tabela principal: **1.611 pacientes**; gestantes: **44**; postos: **17**.
- Não havia posições duplicadas, nulas ou inválidas entre os aguardando. Duas unidades normais começam na posição 2: **não foram renumeradas**.
- Há **80 aguardando** em três nomes históricos sem correspondente literal em `postos`; não foram movidos, renumerados nem transformados automaticamente em novos postos.
- Os pacientes antigos não recebem crédito automático quando saem, pois não estão marcados como consumidores da rodada atual. Isso evita devolver vagas de uma rodada cuja origem não pode ser comprovada.

## Como funciona daqui para frente

- `INSERT` aguardando: valida posto ativo e saldo, valida cota sem ACS quando marcada, coloca no fim da fila, debita uma vaga e fecha `ativo` quando o saldo chega a zero.
- Saída de um cadastro da rodada: remove a posição, compacta a fila, devolve uma vaga e reabre o posto.
- Reentrada: exige vaga, recebe novo marcador da rodada e vai para o fim da fila.
- Troca de unidade aguardando: trava as unidades em ordem canônica, remove da origem, exige vaga no destino, coloca no fim do destino e atualiza os dois saldos atomicamente.
- Nova rodada administrativa: deve usar `iniciar_rodada_posto(nome,vagas)`, que está restrita a `service_role`; não usar `reabrir_posto` nem scripts históricos.

## Testes realizados antes da implantação

- 64 inscrições fictícias concorrentes na fila normal e 32 no clone de metadados: posições únicas e registros antigos preservados.
- Cota sem ACS de 20%/25%, saída histórica, saída de cadastro da rodada, reentrada, transferência, destino lotado e nova rodada: todos passaram no banco local.
- Duas transferências simultâneas A↔B: sem deadlock e sem posições duplicadas.
- Clone operacional: hash de status/posição/unidade e contagem de postos/pacientes preservados após a migration.
- Verificação pós-implantação: **1.611 pacientes, 323 pediátricos, 17 postos, 419 vagas**, trigger canônico ativo e inscrições fechadas.

O que continua fora deste escopo: reativar limpeza automática, reimportar os 188 pacientes ausentes de Nova Belém, renumerar legado, painel/e-mail de remarcação e abrir as inscrições. Nenhum desses itens deve ser feito reaplicando SQL histórico.
