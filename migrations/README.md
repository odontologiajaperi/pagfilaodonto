# Manutenção controlada — 07/10/2026

Estes arquivos registram mudanças **já aplicadas** no projeto Supabase `uakhmgoxgyklggsvtwdf`. **Não execute todos os SQLs do repositório em lote.** Os scripts antigos podem ter regras contraditórias de vagas, limpeza e fila. Não disponibilizar dados clínicos, chaves ou backup em texto puro neste repositório público.

| Arquivo | Estado | Efeito |
|---|---|---|
| `20261007_preservar_filas_e_backup.sql` | Aplicado e verificado | Bloqueou acesso público à tabela histórica `pacientes_backup_hoje`; pausou apenas 2 triggers de DELETE de agendamentos antigos e 1 job diário. Posição, status, vagas e linhas não foram editados. |
| `20261007_remarcacao_dados_e_protocolo.sql` | Aplicado e verificado | Acrescentou colunas nullable e índice de pedidos pendentes; nova RPC de solicitação com data/unidade; protocolo no servidor. Os 83 pedidos antigos permaneceram intactos, sem dados inventados. |
| `20261007_fechar_rpcs_antigas_remarcacao.sql` | Aplicado após publicar a página nova | Revogou `EXECUTE` público da busca por CPF e da antiga solicitação que não exigia data/unidade. A nova RPC continua acessível. |

Testes: arquivo criptografado prioritário das tabelas `pacientes` (1.611), `pacientes_backup_hoje` (3.639), `pacientes_pediatria` (323), `gestantes` (44), `postos` (17) validado por hash e armazenado **somente no repositório privado de backup**. Clone local com metadados operacionais comprovou que suspender as limpezas não altera posições; os 83 pedidos antigos foram pseudonimizados para ensaio da migration aditiva. Impressões digitais de ID/status/posição antes e depois das mudanças foram idênticas. A chave de descriptografia fica fora do GitHub.

**Pendências:** não reativar rotinas antigas de DELETE antes de definir retenção com arquivamento; elas poderiam apagar agendamentos passados. O painel administrativo, visualização dos anexos e e-mail automático exigem autenticação individual da equipe, implantação da Edge Function e autorização de uma conta remetente. Nenhuma dessas integrações foi considerada concluída aqui. Os 188 pacientes `aguardando` de Nova Belém estão no backup histórico, não na tabela atual; **não reimportar nem renumerar automaticamente**. Duas unidades da fila atual começam na posição 2; isso foi preservado intencionalmente para não movimentar usuários.
