# Instruções: Sistema de Abertura/Fechamento de Cadastros

## 📋 Visão Geral

Este sistema permite que você abra ou feche os cadastros da fila de espera de forma simples e segura, diretamente pelo Supabase Table Editor.

**Características:**
- ✅ Controle centralizado e seguro (apenas via Supabase)
- ✅ Mudanças instantâneas em todo o site
- ✅ Mensagem personalizada quando fechado
- ✅ Auditoria automática de alterações
- ✅ Sem botões públicos no site (mais seguro)

---

## 🔧 Instalação (Fazer Apenas Uma Vez)

### No Supabase SQL Editor:

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/sql/new

2. Cole o conteúdo do arquivo **`criar_tabela_configuracoes.sql`**

3. Clique em **"Run"** ou pressione `Ctrl+Enter`

4. Aguarde a mensagem de sucesso

### O que será criado:

- ✅ Tabela `configuracoes` com as configurações do sistema
- ✅ Configuração `cadastros_abertos` (true/false)
- ✅ Configuração `mensagem_cadastro_fechado` (texto personalizado)
- ✅ Trigger automático para atualizar data de modificação
- ✅ Função para registrar timestamp das alterações

---

## 🎛️ Como Controlar os Cadastros

### Pelo Supabase Table Editor:

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf/editor

2. Selecione a tabela **`configuracoes`**

3. Edite a linha `cadastros_abertos`:
   - **`true`** = Cadastros abertos ✅
   - **`false`** = Cadastros fechados ❌

4. (Opcional) Edite a linha `mensagem_cadastro_fechado` para personalizar o aviso

5. Salve as alterações

**As mudanças são aplicadas instantaneamente em todo o site.**

---

## 📱 Como Funciona

### Quando os cadastros estão ABERTOS (valor = `true`):

**Página Inicial (index.html):**
- ✅ Mostra o card roxo "📋 Faça seu Cadastro na Fila!"
- ✅ Card é clicável e leva para o formulário
- ✅ Mensagem padrão de incentivo ao cadastro

**Página de Cadastro (cadastro.html):**
- ✅ Formulário funciona normalmente
- ✅ Todos os campos habilitados
- ✅ Permite enviar cadastros
- ✅ Validações e reCAPTCHA ativos

---

### Quando os cadastros estão FECHADOS (valor = `false`):

**Página Inicial (index.html):**
- ❌ Card muda para vermelho
- ❌ Título: "❌ Cadastros Temporariamente Fechados"
- ❌ Mostra a mensagem personalizada
- ❌ Card não é mais clicável
- ❌ Cor de destaque vermelha para chamar atenção

**Página de Cadastro (cadastro.html):**
- ❌ Aviso vermelho grande no topo da página
- ❌ Formulário fica cinza (opacity: 0.5)
- ❌ Todos os campos desabilitados (disabled)
- ❌ Não permite interação (pointer-events: none)
- ❌ Impossível enviar cadastros
- ✅ Botão "Voltar para Início" disponível

---

## 🎨 Personalização da Mensagem

### Mensagem Padrão:

> "No momento, os cadastros para a fila de espera estão temporáriamente suspensos. Em breve, abriremos novas vagas. Agradecemos pela compreensão e pedimos que acompanhe nossos canais de comunicação para informações sobre a reabertura."

### Como Personalizar:

1. Acesse a tabela `configuracoes` no Supabase
2. Edite a linha `mensagem_cadastro_fechado`
3. Altere o campo `valor` com sua mensagem
4. Salve

### Exemplos de Mensagens:

**Curta e direta:**
```
Os cadastros estão temporariamente fechados. Voltaremos em breve!
```

**Com data de reabertura:**
```
Cadastros fechados para reorganização da fila. 
Previsão de reabertura: 15 de janeiro de 2026.
```

**Com orientação:**
```
No momento não estamos aceitando novos cadastros. 
Acompanhe nossos avisos nas redes sociais para saber quando reabriremos.
```

**Formal e detalhada:**
```
Informamos que os cadastros para a fila de espera estão temporariamente suspensos 
devido ao grande volume de pacientes aguardando atendimento. Estamos trabalhando 
para atender todos na fila atual. Agradecemos pela compreensão.
```

---

## 🔄 Cenários de Uso

### Quando Fechar os Cadastros:

1. **Fila muito grande** - Capacidade máxima atingida
2. **Período de férias** - Recesso de fim de ano, carnaval, etc.
3. **Manutenção do sistema** - Atualizações ou correções
4. **Reorganização** - Mudanças nas unidades ou processos
5. **Falta de profissionais** - Temporária ou permanente
6. **Priorização da fila atual** - Focar em atender quem já está cadastrado

### Quando Reabrir os Cadastros:

1. **Fila processada** - Parte significativa da fila foi atendida
2. **Novo período** - Início de mês, trimestre, semestre
3. **Volta das férias** - Retorno das atividades normais
4. **Novos profissionais** - Contratação de dentistas/equipe
5. **Nova capacidade** - Abertura de novas unidades ou horários
6. **Demanda controlada** - Fila em nível gerenciável

---

## 🔒 Segurança

### Vantagens do Controle pelo Supabase:

1. **Acesso Restrito** - Apenas administradores com login no Supabase
2. **Sem Botões Públicos** - Nada no site que qualquer um possa clicar
3. **Auditoria Automática** - Campo `atualizado_em` registra mudanças
4. **Centralizado** - Um único lugar para controlar
5. **Sem Código Exposto** - Lógica de controle não fica no frontend

### Segurança Adicional (Opcional):

Se quiser ainda mais controle, pode configurar:
- **Row Level Security (RLS)** no Supabase
- **Políticas de acesso** específicas para a tabela
- **Logs de auditoria** detalhados
- **Notificações** quando o status muda

---

## 🧪 Testando o Sistema

### Teste Completo:

1. **Criar a tabela** (se ainda não criou)
   - Execute o SQL no Supabase

2. **Verificar valores iniciais**
   - `cadastros_abertos` deve estar como `true`
   - `mensagem_cadastro_fechado` deve ter a mensagem padrão

3. **Testar com cadastros abertos**
   - Acesse: https://odontologiajaperi.github.io/pagfilaodonto/
   - Veja o card roxo de cadastro
   - Clique e acesse o formulário
   - Confirme que está funcionando

4. **Fechar os cadastros**
   - No Supabase, mude `cadastros_abertos` para `false`
   - Salve a alteração

5. **Testar com cadastros fechados**
   - Abra o site em aba anônima (Ctrl+Shift+N)
   - Veja o card vermelho na página inicial
   - Tente acessar o cadastro - verá o formulário bloqueado

6. **Reabrir os cadastros**
   - No Supabase, mude `cadastros_abertos` para `true`
   - Salve a alteração

7. **Confirmar reabertura**
   - Recarregue o site
   - Tudo deve voltar ao normal

---

## 📊 Estrutura da Tabela

```sql
CREATE TABLE configuracoes (
    id SERIAL PRIMARY KEY,
    chave VARCHAR(100) UNIQUE NOT NULL,
    valor TEXT NOT NULL,
    descricao TEXT,
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_por VARCHAR(100)
);
```

### Campos:

- **`id`** - Identificador único (auto-incremento)
- **`chave`** - Nome da configuração (único)
- **`valor`** - Valor da configuração (texto)
- **`descricao`** - Descrição do que a configuração faz
- **`atualizado_em`** - Data/hora da última atualização (automático)
- **`atualizado_por`** - Usuário que fez a alteração (opcional)

---

## ⚡ Dicas e Boas Práticas

1. **Sempre teste em aba anônima** após fazer mudanças (evita cache)

2. **Comunique antes de fechar** - Avise nas redes sociais/site

3. **Use mensagens claras** - Explique o motivo e quando reabrirá

4. **Monitore a fila** - Feche antes de ficar insustentável

5. **Reabertura gradual** - Considere abrir por períodos curtos

6. **Documente as mudanças** - Anote quando e por que fechou/abriu

7. **Backup da mensagem** - Guarde versões de mensagens que funcionaram bem

---

## 🐛 Solução de Problemas

### Problema: Mudanças não aparecem no site

**Solução:**
- Limpe o cache do navegador (Ctrl+Shift+Delete)
- Teste em aba anônima (Ctrl+Shift+N)
- Aguarde 1-2 minutos (propagação do CDN do GitHub Pages)

### Problema: Tabela não foi criada

**Solução:**
- Verifique se executou o SQL completo
- Confirme que não há erros no console do Supabase
- Tente executar novamente

### Problema: Valor não está mudando

**Solução:**
- Confirme que está editando a linha correta
- Use exatamente `true` ou `false` (minúsculas)
- Salve a alteração (ícone ✓ ou Enter)

### Problema: Mensagem não aparece

**Solução:**
- Verifique se a mensagem foi salva corretamente
- Confirme que o campo `valor` não está vazio
- Recarregue a página em aba anônima

---

## 📞 Suporte

Se precisar de ajuda adicional:
1. Verifique os logs do console do navegador (F12)
2. Confirme que a tabela existe no Supabase
3. Teste em diferentes navegadores
4. Verifique se o JavaScript está habilitado

---

**Criado em:** 04/12/2025  
**Versão:** 2.0 (Controle apenas pelo Supabase)  
**Última atualização:** 04/12/2025  
**Status:** ✅ Funcionando
