# 🎛️ Guia Rápido: Controle de Cadastros

> **GUIA HISTÓRICO — NÃO EXECUTAR os SQLs indicados diretamente em produção.** A organização atual está em [`sql/README.md`](sql/README.md) e as mudanças aplicadas em [`migrations/README.md`](migrations/README.md). Confirme primeiro o estado do Supabase e teste em ambiente separado.


## 📋 O que é?

Um sistema simples para você **abrir** ou **fechar** os cadastros da fila de espera diretamente pelo Supabase.

---

## 🚀 Como Usar (Passo a Passo)

### **PASSO 1: Criar a Tabela** (FAZER APENAS UMA VEZ)

1. Acesse o SQL Editor do Supabase:
   🔗 https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/sql/new

2. Copie todo o conteúdo do arquivo **`sql/historico/seguranca-configuracao/criar_tabela_configuracoes.sql`**

3. Cole no editor SQL do Supabase

4. Clique em **"Run"** (ou pressione `Ctrl+Enter`)

5. Aguarde a mensagem de sucesso ✅

**Pronto!** A tabela foi criada. Você só precisa fazer isso uma vez.

---

### **PASSO 2: Abrir ou Fechar os Cadastros**

1. Acesse o Table Editor do Supabase:
   🔗 https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/editor

2. Clique na tabela **`configuracoes`**

3. Encontre a linha onde `chave` = **`cadastros_abertos`**

4. Clique para editar o campo **`valor`**:
   - **`true`** = Cadastros ABERTOS ✅ (formulário funcionando)
   - **`false`** = Cadastros FECHADOS ❌ (formulário bloqueado)

5. Salve a alteração (ícone de ✓ ou Enter)

**As mudanças são instantâneas!** O site já reflete imediatamente.

---

### **PASSO 3: Personalizar a Mensagem (Opcional)**

Se quiser mudar a mensagem que aparece quando os cadastros estão fechados:

1. Na mesma tabela **`configuracoes`**

2. Encontre a linha onde `chave` = **`mensagem_cadastro_fechado`**

3. Edite o campo **`valor`** com sua mensagem personalizada

4. Salve a alteração

**Mensagem padrão atual:**
> "No momento, os cadastros para a fila de espera estão temporariamente suspensos. Em breve, abriremos novas vagas. Agradecemos pela compreensão e pedimos que acompanhe nossos canais de comunicação para informações sobre a reabertura."

---

## 🎨 O que Acontece Quando Você Fecha os Cadastros?

### **Na Página Inicial (index.html):**
- ❌ Card muda de roxo para vermelho
- Título: "❌ Cadastros Temporariamente Fechados"
- Mostra sua mensagem personalizada
- Não é mais clicável

### **Na Página de Cadastro (cadastro.html):**
- ❌ Aviso vermelho grande no topo
- Formulário fica cinza e bloqueado
- Todos os campos desabilitados
- Impossível enviar cadastros
- Botão "Voltar para Início" disponível

---

## ✅ O que Acontece Quando Você Abre os Cadastros?

Tudo volta ao normal automaticamente:
- ✅ Card roxo clicável na página inicial
- ✅ Formulário funcionando normalmente
- ✅ Pessoas podem se cadastrar

---

## 💡 Quando Usar?

### **Fechar cadastros quando:**
- A fila está muito grande
- Período de férias/recesso
- Manutenção do sistema
- Reorganização das unidades
- Falta temporária de profissionais
- Capacidade máxima atingida

### **Reabrir cadastros quando:**
- Processar parte da fila
- Voltar do período de férias
- Contratar novos profissionais
- Início de novo período
- Capacidade disponível novamente

---

## 📊 Exemplo Visual do Supabase

Quando você acessar a tabela `configuracoes`, verá algo assim:

| id | chave | valor | descricao | atualizado_em |
|----|-------|-------|-----------|---------------|
| 1 | cadastros_abertos | **true** | Define se os cadastros... | 2025-12-04 10:30:00 |
| 2 | mensagem_cadastro_fechado | No momento, os cadastros... | Mensagem exibida... | 2025-12-04 10:30:00 |

**Para fechar:** Mude `true` para `false` na primeira linha  
**Para abrir:** Mude `false` para `true` na primeira linha

---

## ⚡ Dicas Importantes

1. **Mudanças instantâneas** - Assim que você salva no Supabase, o site já reflete (não precisa esperar)

2. **Teste em aba anônima** - Depois de fazer mudanças, abra o site em modo anônimo (Ctrl+Shift+N) para ver sem cache do navegador

3. **Não precisa fazer deploy** - Tudo funciona automaticamente, sem precisar publicar nada no GitHub

4. **Histórico automático** - O campo `atualizado_em` registra quando você fez a última alteração

5. **Segurança** - Apenas quem tem acesso ao Supabase pode controlar (não aparece no site)

---

## 🔒 Segurança

✅ **Vantagens deste método:**
- Apenas administradores com acesso ao Supabase podem controlar
- Não há botões públicos no site que qualquer um possa clicar
- Controle centralizado e seguro
- Auditoria automática de mudanças (campo `atualizado_em`)

---

## 🧪 Testando

1. **Feche os cadastros** no Supabase (valor = `false`)

2. **Abra o site em aba anônima:**
   - https://odontologiajaperi.github.io/pagfilaodonto/

3. **Veja o card vermelho** na página inicial

4. **Tente acessar a página de cadastro:**
   - https://odontologiajaperi.github.io/pagfilaodonto/cadastro.html
   - Verá o formulário bloqueado

5. **Reabra os cadastros** no Supabase (valor = `true`)

6. **Recarregue o site** - Tudo volta ao normal

---

## 📞 Precisa de Ajuda?

Se tiver dúvidas ou problemas:

1. Verifique se a tabela `configuracoes` foi criada corretamente
2. Confirme que o valor está exatamente como `true` ou `false` (minúsculas)
3. Teste em aba anônima para evitar cache
4. Verifique o console do navegador (F12) para erros

---

**Criado em:** 04/12/2025  
**Versão:** 2.0 (Controle apenas pelo Supabase)  
**Status:** ✅ Funcionando
