# 🎛️ Guia Rápido: Controle de Cadastros

## 📋 O que foi criado?

Um sistema simples para você **abrir** ou **fechar** os cadastros da fila de espera quando precisar.

---

## 🚀 Como Usar (Passo a Passo)

### **Passo 1: Criar a Tabela no Supabase** (FAZER APENAS UMA VEZ)

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/sql/new

2. Copie todo o conteúdo do arquivo **`criar_tabela_configuracoes.sql`**

3. Cole no editor SQL do Supabase

4. Clique em **"Run"** (ou pressione `Ctrl+Enter`)

5. Aguarde a mensagem de sucesso ✅

**Pronto!** A tabela foi criada. Você só precisa fazer isso uma vez.

---

### **Passo 2: Controlar os Cadastros**

#### **Opção A: Pelo Painel Administrativo** (MAIS FÁCIL) ⭐

1. Acesse: https://odontologiajaperi.github.io/pagfilaodonto/painel.html

2. Role até a seção **"🎛️ Controle de Cadastros"**

3. Veja o status atual (ABERTO ou FECHADO)

4. Clique no botão desejado:
   - **✅ Abrir Cadastros** → Libera o formulário
   - **❌ Fechar Cadastros** → Bloqueia o formulário

5. (Opcional) Edite a mensagem que aparece quando fechado

6. Clique em **💾 Salvar Mensagem**

**As mudanças são instantâneas!** Não precisa recarregar nada.

---

#### **Opção B: Pelo Supabase Table Editor**

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/editor

2. Clique na tabela **`configuracoes`**

3. Encontre a linha com `chave` = **`cadastros_abertos`**

4. Edite o campo `valor`:
   - **`true`** = Cadastros ABERTOS ✅
   - **`false`** = Cadastros FECHADOS ❌

5. Salve a alteração

---

## 🎨 O que acontece quando você FECHA os cadastros?

### **Na Página Inicial (index.html):**
- O card roxo "📋 Faça seu Cadastro" vira vermelho
- Muda para "❌ Cadastros Temporariamente Fechados"
- Mostra sua mensagem personalizada
- Não é mais clicável

### **Na Página de Cadastro (cadastro.html):**
- Aparece um aviso vermelho grande no topo
- O formulário fica cinza e bloqueado
- Todos os campos ficam desabilitados
- Não é possível enviar cadastros

---

## ✅ O que acontece quando você ABRE os cadastros?

Tudo volta ao normal:
- Card roxo clicável na página inicial
- Formulário funcionando normalmente
- Pessoas podem se cadastrar

---

## 💡 Quando Usar?

### **Fechar cadastros quando:**
- A fila está muito grande
- Período de férias/manutenção
- Reorganização das unidades
- Falta de profissionais temporária

### **Reabrir cadastros quando:**
- Processar parte da fila
- Voltar do período de férias
- Contratar novos profissionais
- Início de novo período

---

## 🔧 Personalizar a Mensagem

**Exemplos de mensagens:**

```
Os cadastros estão temporariamente fechados. Voltaremos em breve!
```

```
Cadastros fechados para reorganização da fila. 
Previsão de reabertura: 15 de janeiro de 2026.
```

```
No momento não estamos aceitando novos cadastros. 
Acompanhe nossos avisos para saber quando reabriremos.
```

```
Cadastros fechados devido ao grande volume de pacientes. 
Estamos trabalhando para atender todos na fila atual.
```

---

## ⚡ Dicas Importantes

1. **As mudanças são instantâneas** - Assim que você altera no painel ou Supabase, o site já reflete

2. **Teste em aba anônima** - Depois de fazer mudanças, abra o site em modo anônimo (Ctrl+Shift+N) para ver sem cache

3. **Não precisa fazer deploy** - Tudo funciona automaticamente

4. **Histórico de mudanças** - O Supabase registra quando você alterou (campo `atualizado_em`)

---

## 📞 Precisa de Ajuda?

Se tiver dúvidas ou problemas:
- Verifique se a tabela foi criada corretamente no Supabase
- Teste em aba anônima para evitar cache
- Verifique o console do navegador (F12) para erros

---

**Criado em:** 04/12/2025  
**Versão:** 1.0  
**Status:** ✅ Funcionando
