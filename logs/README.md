# Logs de Erros do Site

Os erros que ocorrem no site são registrados automaticamente na tabela `logs_erros` do Supabase, sem expor detalhes técnicos aos pacientes.

## Como consultar os erros

### Ver os últimos 100 erros (mais recentes primeiro):
```sql
SELECT * FROM public.erros_recentes;
```

### Ver resumo agrupado por tipo de erro:
```sql
SELECT * FROM public.resumo_erros;
```

### Ver erros de uma página específica:
```sql
SELECT * FROM public.logs_erros 
WHERE pagina = 'cadastro.html' 
ORDER BY created_at DESC 
LIMIT 20;
```

### Ver erros das últimas 24 horas:
```sql
SELECT * FROM public.logs_erros 
WHERE created_at > NOW() - INTERVAL '24 hours' 
ORDER BY created_at DESC;
```

## Limpeza de logs antigos

Para manter o banco limpo, execute periodicamente:

```sql
-- Remover logs com mais de 30 dias
SELECT public.limpar_logs_erros(30);

-- Remover logs com mais de 7 dias
SELECT public.limpar_logs_erros(7);
```

## O que é registrado

| Campo | Descrição |
|---|---|
| `pagina` | Qual página gerou o erro (ex: `cadastro.html`) |
| `contexto` | Tipo de operação (ex: `geral`, `gestante`, `pediatria`) |
| `codigo_erro` | Código técnico do erro (ex: `23505`, `42501`) |
| `mensagem_erro` | Mensagem técnica completa do erro |
| `detalhes` | Detalhes adicionais retornados pelo banco |
| `hint` | Dica de correção retornada pelo banco |
| `dados_extra` | Informações extras como unidade selecionada |
| `user_agent` | Navegador/dispositivo do paciente |
| `data_hora_br` | Data e hora no fuso de Brasília |

## O que o paciente vê

Em vez de mensagens técnicas como:
> "Could not find the 'nome_acs' column of 'pacientes' in the schema cache"

O paciente agora vê:
> "Ocorreu um erro temporário no sistema. Por favor, tente novamente em alguns instantes. Se o problema persistir, entre em contato com a equipe de saúde bucal pelo e-mail odontologiajaperi@gmail.com."

## Setup inicial

Execute o script `logs_erros.sql` no SQL Editor do Supabase para criar a tabela e as views.
