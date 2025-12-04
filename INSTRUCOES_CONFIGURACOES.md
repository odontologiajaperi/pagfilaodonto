# Instruções: Sistema de Abertura/Fechamento de Cadastros

## 📋 Visão Geral

Este sistema permite que você abra ou feche os cadastros da fila de forma simples, diretamente pelo painel administrativo ou pelo Supabase Table Editor.

## 🔧 Passo 1: Criar a Tabela de Configurações

### No Supabase SQL Editor:

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/sql/new
2. Cole o conteúdo do arquivo `criar_tabela_configuracoes.sql`
3. Clique em **"Run"** ou pressione `Ctrl+Enter`
4. Aguarde a mensagem de sucesso

### O que será criado:

- ✅ Tabela `configuracoes` com as configurações do sistema
- ✅ Configuração `cadastros_abertos` (true/false)
- ✅ Configuração `mensagem_cadastro_fechado` (texto do aviso)
- ✅ Trigger automático para atualizar data de modificação

## 🎛️ Passo 2: Como Usar

### Opção A: Pelo Painel Administrativo (Recomendado)

1. Acesse: https://odontologiajaperi.github.io/pagfilaodonto/painel.html
2. Faça login com suas credenciais
3. Vá até a seção **"Controle de Cadastros"**
4. Use o botão para **Abrir** ou **Fechar** os cadastros
5. Edite a mensagem de aviso se desejar

### Opção B: Pelo Supabase Table Editor

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/editor
2. Selecione a tabela **`configuracoes`**
3. Edite a linha `cadastros_abertos`:
   - **`true`** = Cadastros abertos ✅
   - **`false`** = Cadastros fechados ❌
4. Edite a linha `mensagem_cadastro_fechado` para personalizar o aviso

## 📱 Como Funciona

### Quando os cadastros estão ABERTOS:

**Página Inicial (index.html):**
- Mostra o botão "Faça seu Cadastro" normalmente
- Link funciona e leva para o formulário

**Página de Cadastro (cadastro.html):**
- Formulário funciona normalmente
- Permite enviar cadastros

### Quando os cadastros estão FECHADOS:

**Página Inicial (index.html):**
- Botão "Faça seu Cadastro" é substituído por um aviso
- Mostra mensagem personalizada em destaque
- Cor vermelha/laranja para chamar atenção

**Página de Cadastro (cadastro.html):**
- Formulário fica bloqueado (desabilitado)
- Mostra aviso grande no topo da página
- Não permite enviar cadastros
- Botão de envio fica desabilitado

## 🎨 Personalização

### Mudar a mensagem quando fechado:

No Supabase Table Editor, edite a configuração `mensagem_cadastro_fechado`:

**Exemplos de mensagens:**

```
Os cadastros estão temporariamente fechados. Voltaremos em breve!
```

```
Cadastros fechados para manutenção do sistema. Previsão de reabertura: 15/12/2025.
```

```
No momento não estamos aceitando novos cadastros. Acompanhe nossos avisos nas redes sociais.
```

## 🔄 Cenários de Uso

### Fechar temporariamente:
- Manutenção do sistema
- Fila muito grande
- Período de férias
- Reorganização das unidades

### Reabrir:
- Após processar parte da fila
- Início de novo período
- Após manutenção concluída

## ⚠️ Importante

- As mudanças são **instantâneas** - assim que você altera no Supabase, o site já reflete
- Não precisa reiniciar nada ou fazer deploy
- A configuração é compartilhada entre todas as páginas
- Recomendo testar em uma aba anônima após fazer alterações

## 🧪 Testando

1. Abra o Supabase Table Editor
2. Mude `cadastros_abertos` para `false`
3. Abra o site em uma aba anônima (Ctrl+Shift+N)
4. Veja o aviso na página inicial
5. Tente acessar a página de cadastro - verá o formulário bloqueado
6. Volte ao Supabase e mude para `true`
7. Recarregue o site - tudo volta ao normal

## 📊 Monitoramento

A tabela `configuracoes` registra automaticamente:
- **`atualizado_em`**: Data e hora da última mudança
- **`atualizado_por`**: Quem fez a mudança (se configurado)

Isso ajuda a ter um histórico de quando os cadastros foram abertos/fechados.

---

**Criado em:** 04/12/2025
**Versão:** 1.0
