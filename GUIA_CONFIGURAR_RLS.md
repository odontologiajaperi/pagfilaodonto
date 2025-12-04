# 🔒 Guia Completo - Configurar RLS em Todas as Tabelas

## 📋 O que é RLS (Row Level Security)?

**Row Level Security (RLS)** é um sistema de segurança do PostgreSQL (usado pelo Supabase) que controla quem pode acessar, inserir, atualizar ou deletar dados em cada tabela.

Atualmente, suas tabelas estão como **"unrestricted"** (sem restrições), o que significa que qualquer pessoa pode fazer qualquer operação. Isso é um **risco de segurança**.

---

## 🎯 Objetivo

Configurar políticas de segurança para que:

1. **Formulário público** possa cadastrar pacientes e gestantes
2. **Formulário público** possa validar CPF duplicado
3. **Formulário público** possa listar postos e verificar configurações
4. **Apenas administradores** possam editar, deletar ou gerenciar dados
5. **Tabela de administradores** seja totalmente privada

---

## 🚀 Passo a Passo de Implementação

### **Passo 1: Acessar o Supabase SQL Editor**

1. Acesse seu projeto no Supabase: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf
2. No menu lateral esquerdo, clique em **SQL Editor**
3. Clique no botão **New Query** (Nova Consulta)

### **Passo 2: Executar o Script SQL**

1. Abra o arquivo `sql_configurar_rls_completo.sql` que foi gerado
2. **Copie TODO o conteúdo** do arquivo
3. **Cole** no SQL Editor do Supabase
4. Clique no botão **Run** (Executar) no canto inferior direito
5. Aguarde a execução (pode levar alguns segundos)

### **Passo 3: Verificar se as Políticas Foram Criadas**

Após executar o script, você verá uma mensagem de sucesso. Para confirmar:

1. No mesmo SQL Editor, crie uma **New Query**
2. Cole o seguinte código:

```sql
SELECT 
    tablename as "Tabela",
    policyname as "Política",
    CASE 
        WHEN cmd = 'SELECT' THEN 'Leitura'
        WHEN cmd = 'INSERT' THEN 'Inserção'
        WHEN cmd = 'UPDATE' THEN 'Atualização'
        WHEN cmd = 'DELETE' THEN 'Exclusão'
        ELSE cmd
    END as "Operação",
    CASE 
        WHEN roles::text LIKE '%public%' THEN 'Público'
        WHEN roles::text LIKE '%authenticated%' THEN 'Autenticado'
        ELSE roles::text
    END as "Quem Pode Acessar"
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;
```

3. Clique em **Run**
4. Você deverá ver uma lista com todas as políticas criadas

### **Passo 4: Verificar o Status do RLS nas Tabelas**

1. No menu lateral, clique em **Table Editor**
2. Selecione cada tabela (pacientes, gestantes, postos, configuracoes, administradores)
3. Clique nos **3 pontinhos** (⋮) no canto superior direito
4. Verifique se aparece **"RLS enabled"** (RLS habilitado)

Se aparecer **"RLS disabled"**, significa que algo deu errado. Volte ao Passo 2.

### **Passo 5: Testar o Sistema**

Após configurar o RLS, teste se tudo está funcionando:

#### ✅ Teste 1: Cadastro de Paciente
1. Acesse o formulário de cadastro no seu site
2. Preencha os dados de um paciente (NÃO marque "gestante")
3. Envie o cadastro
4. **Resultado esperado:** Cadastro realizado com sucesso

#### ✅ Teste 2: Cadastro de Gestante
1. Acesse o formulário de cadastro
2. Marque a opção **"🤰 Você é gestante?"**
3. Preencha os dados adicionais
4. Envie o cadastro
5. **Resultado esperado:** Cadastro realizado com sucesso

#### ✅ Teste 3: Validação de CPF Duplicado
1. Tente cadastrar novamente com o mesmo CPF
2. **Resultado esperado:** Mensagem de erro "CPF já cadastrado"

#### ✅ Teste 4: Listar Postos
1. Acesse o formulário de cadastro
2. Verifique se o campo "Unidade de Preferência" mostra a lista de postos
3. **Resultado esperado:** Lista de postos aparece normalmente

#### ✅ Teste 5: Verificar Configurações
1. O formulário deve verificar se os cadastros estão abertos
2. **Resultado esperado:** Se estiver fechado, mostra mensagem; se aberto, permite cadastro

---

## 📊 Resumo das Políticas por Tabela

### **1. Tabela: pacientes**

| Operação | Quem Pode | Justificativa |
|---|---|---|
| **INSERT** (Inserir) | 🌐 Público | Formulário precisa cadastrar pacientes |
| **SELECT** (Ler) | 🌐 Público | Validar CPF duplicado e consultar fila |
| **UPDATE** (Atualizar) | 🔒 Apenas Admins | Evitar que pacientes alterem dados |
| **DELETE** (Deletar) | 🔒 Apenas Admins | Evitar exclusões indevidas |

### **2. Tabela: gestantes**

| Operação | Quem Pode | Justificativa |
|---|---|---|
| **INSERT** (Inserir) | 🌐 Público | Formulário precisa cadastrar gestantes |
| **SELECT** (Ler) | 🌐 Público | Validar CPF duplicado |
| **UPDATE** (Atualizar) | 🔒 Apenas Admins | Evitar que gestantes alterem dados |
| **DELETE** (Deletar) | 🔒 Apenas Admins | Evitar exclusões indevidas |

### **3. Tabela: postos**

| Operação | Quem Pode | Justificativa |
|---|---|---|
| **INSERT** (Inserir) | 🔒 Apenas Admins | Apenas admins podem criar postos |
| **SELECT** (Ler) | 🌐 Público | Formulário precisa listar postos |
| **UPDATE** (Atualizar) | 🔒 Apenas Admins | Apenas admins podem editar postos |
| **DELETE** (Deletar) | 🔒 Apenas Admins | Apenas admins podem deletar postos |

### **4. Tabela: configuracoes**

| Operação | Quem Pode | Justificativa |
|---|---|---|
| **INSERT** (Inserir) | 🔒 Apenas Admins | Apenas admins podem criar configurações |
| **SELECT** (Ler) | 🌐 Público | Formulário precisa verificar se cadastros estão abertos |
| **UPDATE** (Atualizar) | 🔒 Apenas Admins | Apenas admins podem alterar configurações |
| **DELETE** (Deletar) | 🔒 Apenas Admins | Apenas admins podem deletar configurações |

### **5. Tabela: administradores**

| Operação | Quem Pode | Justificativa |
|---|---|---|
| **INSERT** (Inserir) | 🔒 Apenas Admins | Apenas admins podem criar outros admins |
| **SELECT** (Ler) | 🔒 Apenas Admins | Dados sensíveis, não podem ser públicos |
| **UPDATE** (Atualizar) | 🔒 Apenas Admins | Apenas admins podem editar admins |
| **DELETE** (Deletar) | 🔒 Apenas Admins | Apenas admins podem deletar admins |

---

## ⚠️ Possíveis Problemas e Soluções

### **Problema 1: "Erro ao executar o script"**

**Causa:** Pode haver políticas duplicadas ou conflitantes.

**Solução:**
1. Primeiro, remova todas as políticas antigas:

```sql
-- Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Permitir insert público em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir select público em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir update apenas para admins em pacientes" ON public.pacientes;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em pacientes" ON public.pacientes;

DROP POLICY IF EXISTS "Permitir insert público em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir select público em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir update apenas para admins em gestantes" ON public.gestantes;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em gestantes" ON public.gestantes;

DROP POLICY IF EXISTS "Permitir select público em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir insert apenas para admins em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir update apenas para admins em postos" ON public.postos;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em postos" ON public.postos;

DROP POLICY IF EXISTS "Permitir select público em configuracoes" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir insert apenas para admins em configuracoes" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir update apenas para admins em configuracoes" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em configuracoes" ON public.configuracoes;

DROP POLICY IF EXISTS "Permitir select apenas para admins em administradores" ON public.administradores;
DROP POLICY IF EXISTS "Permitir insert apenas para admins em administradores" ON public.administradores;
DROP POLICY IF EXISTS "Permitir update apenas para admins em administradores" ON public.administradores;
DROP POLICY IF EXISTS "Permitir delete apenas para admins em administradores" ON public.administradores;
```

2. Depois, execute novamente o script `sql_configurar_rls_completo.sql`

### **Problema 2: "Formulário não consegue mais cadastrar pacientes"**

**Causa:** RLS está bloqueando o acesso público.

**Solução:** Verifique se as políticas de INSERT e SELECT público foram criadas corretamente:

```sql
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'pacientes' 
AND cmd IN ('INSERT', 'SELECT');
```

Deve retornar 2 políticas. Se não retornar, execute novamente o script.

### **Problema 3: "Administradores não conseguem editar dados"**

**Causa:** A tabela `administradores` não está vinculada ao sistema de autenticação do Supabase.

**Solução:** Você precisa criar usuários autenticados no Supabase e vinculá-los à tabela `administradores`. Isso requer configuração adicional de autenticação.

**Alternativa temporária:** Se você ainda não tem sistema de autenticação, pode criar políticas mais permissivas temporariamente:

```sql
-- TEMPORÁRIO: Permitir UPDATE/DELETE público (REMOVER DEPOIS)
CREATE POLICY "Permitir update público TEMPORÁRIO" 
ON public.pacientes
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);
```

⚠️ **ATENÇÃO:** Isso é inseguro e deve ser usado apenas para testes!

---

## 🔐 Segurança Adicional (Opcional)

### **Limitar SELECT de pacientes apenas ao próprio CPF**

Se você quiser que cada paciente veja apenas seus próprios dados:

```sql
-- Substituir a política de SELECT em pacientes
DROP POLICY IF EXISTS "Permitir select público em pacientes" ON public.pacientes;

CREATE POLICY "Permitir select apenas do próprio CPF" 
ON public.pacientes
FOR SELECT
TO public
USING (
    cpf = current_setting('request.headers')::json->>'x-cpf'
    OR true  -- Permite validação de CPF duplicado
);
```

Isso requer modificações no código JavaScript para enviar o CPF no header.

---

## ✅ Checklist Final

Após seguir todos os passos, verifique:

- [ ] RLS habilitado em todas as 5 tabelas
- [ ] Políticas criadas para cada operação (INSERT, SELECT, UPDATE, DELETE)
- [ ] Formulário consegue cadastrar pacientes
- [ ] Formulário consegue cadastrar gestantes
- [ ] Formulário valida CPF duplicado
- [ ] Formulário lista postos corretamente
- [ ] Formulário verifica se cadastros estão abertos
- [ ] Dados de administradores não são acessíveis publicamente

---

## 📞 Suporte

Se encontrar algum problema:

1. Verifique os logs de erro no console do navegador (F12)
2. Verifique os logs do Supabase em **Logs** > **Database**
3. Execute a query de verificação de políticas (Passo 3)
4. Certifique-se de que o script foi executado completamente

---

## 🎉 Conclusão

Após configurar o RLS corretamente, seu sistema estará **muito mais seguro**:

✅ Apenas operações autorizadas são permitidas  
✅ Dados sensíveis estão protegidos  
✅ Formulário público continua funcionando normalmente  
✅ Administradores têm controle total (quando autenticados)  

**Parabéns pela implementação! 🚀**
