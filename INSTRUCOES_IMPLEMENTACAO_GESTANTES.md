# 📋 Instruções de Implementação - Tabela Gestantes

> **GUIA HISTÓRICO — NÃO EXECUTAR os SQLs indicados diretamente em produção.** A organização atual está em [`sql/README.md`](sql/README.md) e as mudanças aplicadas em [`migrations/README.md`](migrations/README.md). Confirme primeiro o estado do Supabase e teste em ambiente separado.


## 🎯 Objetivo

Criar uma tabela separada `gestantes` no Supabase para armazenar informações de pacientes gestantes, que **não entram na fila regular** e recebem **atendimento prioritário**.

---

## 📊 Estrutura da Tabela

A tabela `gestantes` contém:

### ✅ Campos Comuns (da tabela `pacientes`)
- `id`, `created_at`, `updated_at`, `submitted_at`
- `nome_completo`, `sexo`, `data_nascimento`, `celular`, `email`, `cpf`, `cartao_sus`, `nome_mae`, `endereco`
- `unidade_preferencia`, `aceita_outra_unidade`
- `queixa_principal`, `avaliacao_agendamento`, `sugestoes`, `probabilidade_recomendacao`

### 🤰 Campos Específicos de Gestantes
- `data_prevista_parto` (date) - Data prevista do parto
- `deseja_atendimento` (boolean) - Se deseja ser atendida durante a gestação
- `termo_gestante_aceito` (boolean) - Se aceitou o termo de declaração

### ❌ Campos que NÃO existem (relacionados à fila)
- `posicao_fila`
- `mes_referencia`
- `status`
- `data_agendamento`

---

## 🚀 Passo a Passo de Implementação

### **1. Criar a Tabela no Supabase**

1. Acesse seu projeto no Supabase: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf
2. Vá em **SQL Editor** (no menu lateral)
3. Clique em **New Query**
4. Copie e cole o conteúdo do arquivo `sql/historico/gestantes/sql_tabela_gestantes.sql`
5. Clique em **Run** para executar o SQL
6. Verifique se a tabela foi criada em **Table Editor** > `gestantes`

### **2. Configurar Políticas de Segurança (RLS)**

No Supabase, você precisa configurar as políticas de Row Level Security (RLS) para a tabela `gestantes`:

```sql
-- Habilitar RLS
ALTER TABLE public.gestantes ENABLE ROW LEVEL SECURITY;

-- Permitir INSERT público (para cadastro)
CREATE POLICY "Permitir insert público" ON public.gestantes
FOR INSERT
TO public
WITH CHECK (true);

-- Permitir SELECT público (para consulta)
CREATE POLICY "Permitir select público" ON public.gestantes
FOR SELECT
TO public
USING (true);

-- Permitir UPDATE apenas para administradores (opcional)
-- CREATE POLICY "Permitir update admin" ON public.gestantes
-- FOR UPDATE
-- TO authenticated
-- USING (auth.uid() IN (SELECT id FROM administradores));
```

**Execute essas políticas no SQL Editor do Supabase.**

### **3. Atualizar o Código HTML**

O arquivo `cadastro.html` já foi ajustado automaticamente. Você precisa:

1. **Substituir o arquivo `cadastro.html` do seu repositório** pelo arquivo ajustado que está em `/home/ubuntu/pagfilaodonto/cadastro.html`
2. **Ou aplicar manualmente o ajuste:**
   - Localize a linha 878 no arquivo `cadastro.html`
   - Adicione após `data.termo_gestante_aceito = true;`:
   ```javascript
   // Adicionar campos automáticos
   data.submitted_at = new Date().toISOString();
   ```

### **4. Testar o Sistema**

1. Acesse o formulário de cadastro
2. Marque a opção **"🤰 Você é gestante?"**
3. Preencha os campos adicionais:
   - Data Prevista do Parto
   - Deseja atendimento durante a gestação?
4. Aceite o termo de declaração de gestante
5. Envie o cadastro
6. Verifique no Supabase se o registro foi inserido na tabela `gestantes` (e não em `pacientes`)

---

## 🔍 Verificação de Funcionamento

### ✅ Checklist de Testes

- [ ] Tabela `gestantes` criada no Supabase
- [ ] Políticas RLS configuradas
- [ ] Cadastro de gestante insere na tabela `gestantes`
- [ ] Cadastro normal insere na tabela `pacientes`
- [ ] CPF duplicado na tabela `gestantes` é bloqueado
- [ ] Mensagem de sucesso personalizada para gestantes
- [ ] Campos de fila (`posicao_fila`, etc.) NÃO aparecem na tabela `gestantes`

### 🔎 Consulta SQL para Verificar Registros

```sql
-- Ver todas as gestantes cadastradas
SELECT 
    nome_completo,
    cpf,
    data_prevista_parto,
    deseja_atendimento,
    unidade_preferencia,
    created_at
FROM public.gestantes
ORDER BY created_at DESC;

-- Contar gestantes por unidade
SELECT 
    unidade_preferencia,
    COUNT(*) as total_gestantes,
    SUM(CASE WHEN deseja_atendimento THEN 1 ELSE 0 END) as desejam_atendimento
FROM public.gestantes
GROUP BY unidade_preferencia
ORDER BY total_gestantes DESC;
```

---

## 📝 Diferenças entre `pacientes` e `gestantes`

| Característica | `pacientes` | `gestantes` |
|---|---|---|
| **Sistema de Fila** | ✅ Sim (com `posicao_fila`) | ❌ Não |
| **Atendimento** | Regular | Prioritário |
| **Campos Específicos** | - | `data_prevista_parto`, `deseja_atendimento`, `termo_gestante_aceito` |
| **Triggers** | `trigger_atribuir_posicao_novo`, `trigger_reorganizar_apos_remocao` | Nenhum |
| **Status** | `aguardando`, `agendado`, etc. | Não possui campo `status` |

---

## 🛠️ Manutenção e Administração

### Consultar Gestantes que Desejam Atendimento

```sql
SELECT 
    nome_completo,
    celular,
    data_prevista_parto,
    unidade_preferencia,
    queixa_principal
FROM public.gestantes
WHERE deseja_atendimento = true
ORDER BY data_prevista_parto ASC;
```

### Atualizar Status de Atendimento (se necessário)

Se futuramente você quiser adicionar um campo de status para gestantes:

```sql
-- Adicionar coluna status (opcional)
ALTER TABLE public.gestantes 
ADD COLUMN status_atendimento text DEFAULT 'aguardando';

-- Valores possíveis: 'aguardando', 'em_atendimento', 'concluido'
```

---

## ⚠️ Observações Importantes

1. **CPF Único:** Um CPF não pode estar cadastrado tanto em `pacientes` quanto em `gestantes`. O sistema valida isso no JavaScript.

2. **Sem Fila:** Gestantes **não entram na fila regular**. Elas têm atendimento prioritário e devem ser contatadas diretamente.

3. **Termo de Declaração:** É obrigatório aceitar o termo de declaração de gestante antes de enviar o cadastro.

4. **Data Prevista do Parto:** A data mínima é a data atual (não permite datas passadas).

5. **Backup:** Sempre faça backup da tabela antes de fazer alterações estruturais.

---

## 📞 Suporte

Se houver algum problema na implementação:

1. Verifique os logs de erro no console do navegador (F12)
2. Verifique os logs do Supabase em **Logs** > **Database**
3. Confirme que as políticas RLS estão configuradas corretamente

---

## ✅ Conclusão

Após seguir todos os passos acima, o sistema estará pronto para:

- ✅ Cadastrar gestantes em uma tabela separada
- ✅ Diferenciar gestantes de pacientes regulares
- ✅ Oferecer atendimento prioritário para gestantes
- ✅ Evitar que gestantes entrem na fila regular
- ✅ Validar CPF duplicado em ambas as tabelas

**Boa implementação! 🚀**
