# ⭐ Sistema de Avaliação de Atendimento V2.0

## 📋 Visão Geral

Sistema simplificado e inteligente de avaliação de atendimento para a Saúde Bucal de Japeri, com página dedicada, pop-up automático estilo HQ e formulário otimizado.

---

## ✨ Funcionalidades

### **1. Página Dedicada de Avaliação**

- 📄 **Arquivo:** `avaliacao.html`
- 🎨 **Design:** Gradiente verde/azul com estrela animada
- 📝 **Formulário Simplificado:**
  - CPF (com máscara automática)
  - Data do atendimento
  - Unidade (dropdown)
  - Cirurgião-dentista (dropdown)
  - Avaliação 0-10 (escala visual)
  - Comentário opcional

### **2. Pop-up Inteligente com Balão Estilo HQ**

- 🎪 **Balão de diálogo** estilo história em quadrinhos
- ⭐ **Estrela animada** com bounce
- 📱 **Aparece automaticamente:**
  - Na primeira visita (após 3 segundos)
  - A cada 2 minutos de navegação
- ❌ **Botão X** para fechar
- 🔒 **Não reaparece** na mesma sessão após fechar

### **3. Integração em Todas as Páginas**

- ✅ avisos.html
- ✅ cadastro.html
- ✅ consulta-fila.html
- ✅ fluxograma.html
- ✅ index.html
- ✅ painel.html
- ✅ termos.html
- ✅ unidades.html

---

## 🗄️ Estrutura do Banco de Dados

### **Tabela: `avaliacoes` (Versão Simplificada)**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid | Identificador único |
| `created_at` | timestamp | Data/hora do envio |
| `cpf` | text | CPF do paciente (sem formatação) |
| `data_atendimento` | date | Data do atendimento |
| `unidade` | text | Unidade onde foi atendido |
| `cirurgiao_dentista` | text | Nome do dentista |
| `nota` | integer | Nota de 0 a 10 |
| `comentario` | text | Comentário opcional |

### **Índices:**

- `idx_avaliacoes_cpf` - Busca por CPF
- `idx_avaliacoes_unidade` - Filtro por unidade
- `idx_avaliacoes_data` - Ordenação por data
- `idx_avaliacoes_nota` - Filtro por nota
- `idx_avaliacoes_created` - Ordenação por criação

---

## 🔒 Políticas de Segurança (RLS)

| Operação | Quem Pode |
|----------|-----------|
| **INSERT** | 🌐 Qualquer pessoa (público) |
| **SELECT** | 🔒 Apenas administradores autenticados |
| **UPDATE** | 🔒 Apenas administradores autenticados |
| **DELETE** | 🔒 Apenas administradores autenticados |

---

## 📊 Funções SQL Disponíveis

### **1. Calcular média de uma unidade:**

```sql
SELECT * FROM calcular_media_avaliacoes_unidade('Marabá');
```

**Retorna:**
- Total de avaliações
- Média da nota
- Nota máxima
- Nota mínima

### **2. Calcular média de todas as unidades:**

```sql
SELECT * FROM calcular_media_geral_avaliacoes();
```

**Retorna:**
- Unidade
- Total de avaliações
- Média da nota
- Ordenado por média (maior para menor)

---

## 🚀 Como Implementar

### **Passo 1: Executar SQL no Supabase**

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf
2. Vá em **SQL Editor** → **New Query**
3. Abra o arquivo `sql_nova_tabela_avaliacoes.sql`
4. Copie **TODO** o conteúdo
5. Cole no SQL Editor
6. Clique em **Run**

**⚠️ ATENÇÃO:** Este script vai **DROPAR** a tabela `avaliacoes` antiga e criar uma nova!

### **Passo 2: Aguardar Deploy**

1. Aguarde 1-2 minutos para o GitHub Pages fazer deploy
2. Limpe o cache do navegador (Ctrl + Shift + R)
3. Acesse qualquer página do site
4. ✅ Pop-up aparecerá automaticamente após 3 segundos!

---

## 🧪 Como Testar

### **Teste 1: Pop-up Automático**

1. Acesse qualquer página do site (ex: index.html)
2. Aguarde 3 segundos
3. ✅ Pop-up aparece com balão estilo HQ
4. Clique no X para fechar
5. ✅ Pop-up não reaparece na mesma sessão

### **Teste 2: Página de Avaliação**

1. Clique em "⭐ Avaliar Agora" no pop-up
2. ✅ Abre a página `avaliacao.html`
3. Preencha o formulário
4. Clique em "Enviar Avaliação"
5. ✅ Modal de sucesso aparece
6. ✅ Redireciona para index.html

### **Teste 3: Banco de Dados**

1. No Supabase, vá em **Table Editor**
2. Selecione a tabela `avaliacoes`
3. ✅ Veja a avaliação que você enviou

### **Teste 4: Exibição a Cada 2 Minutos**

1. Acesse o site
2. Feche o pop-up
3. Navegue por 2 minutos
4. ✅ Pop-up reaparece automaticamente

---

## 🎨 Design

### **Cores:**

- **Verde:** `#1DC56F` (principal)
- **Azul:** `#0F8BD6` (secundário)
- **Gradiente:** `linear-gradient(135deg, #1DC56F 0%, #0F8BD6 100%)`

### **Animações:**

- **starBounce:** Estrela pulando (1.5s loop)
- **popIn:** Entrada do pop-up com rotação (0.5s)
- **fadeIn:** Fade do overlay (0.4s)
- **bounce:** Bounce da estrela no header (1s)

### **Balão Estilo HQ:**

- Borda preta de 4px
- Seta apontando para cima
- Texto em negrito e grande
- Sombra para dar profundidade

---

## 📱 Responsividade

### **Mobile:**
- Pop-up ocupa 95% da largura
- Estrela menor (60px)
- Balão com texto menor
- Botões ajustados

### **Desktop:**
- Pop-up com max-width: 450px
- Estrela grande (70px)
- Balão com texto grande
- Centralizado na tela

---

## 🧠 Lógica de Exibição

### **LocalStorage:**

- `avaliacaoPopupLastShown` - Timestamp da última exibição
- Usado para controlar o intervalo de 2 minutos

### **SessionStorage:**

- `avaliacaoPopupDismissed` - Marcador de "dispensado"
- Usado para não reexibir na mesma sessão após fechar

### **Fluxo:**

1. **Primeira visita:**
   - Não há registro no localStorage
   - Pop-up aparece após 3 segundos

2. **Usuário fecha o pop-up:**
   - Marca como "dispensado" no sessionStorage
   - Não reaparece até fechar o navegador

3. **Nova sessão (após fechar navegador):**
   - sessionStorage é limpo
   - Verifica localStorage
   - Se passaram 2 minutos desde a última exibição, mostra novamente

4. **Página de avaliação:**
   - Pop-up **nunca** aparece em `avaliacao.html`

---

## 📊 Consultas Úteis

### **Ver todas as avaliações:**

```sql
SELECT * FROM avaliacoes 
ORDER BY created_at DESC;
```

### **Ver avaliações de uma unidade:**

```sql
SELECT * FROM avaliacoes 
WHERE unidade = 'Marabá' 
ORDER BY created_at DESC;
```

### **Ver avaliações com nota baixa (0-5):**

```sql
SELECT * FROM avaliacoes 
WHERE nota <= 5 
ORDER BY created_at DESC;
```

### **Ver avaliações com nota alta (9-10):**

```sql
SELECT * FROM avaliacoes 
WHERE nota >= 9 
ORDER BY created_at DESC;
```

### **Calcular média por dentista:**

```sql
SELECT 
    cirurgiao_dentista,
    COUNT(*) as total_avaliacoes,
    ROUND(AVG(nota), 2) as media_nota
FROM avaliacoes
GROUP BY cirurgiao_dentista
ORDER BY media_nota DESC;
```

### **Ver comentários mais recentes:**

```sql
SELECT 
    data_atendimento,
    unidade,
    cirurgiao_dentista,
    nota,
    comentario
FROM avaliacoes
WHERE comentario IS NOT NULL AND comentario != ''
ORDER BY created_at DESC
LIMIT 10;
```

---

## 📁 Arquivos do Sistema

| Arquivo | Descrição |
|---------|-----------|
| `sql_nova_tabela_avaliacoes.sql` | Script SQL completo (drop + create + RLS + funções) |
| `avaliacao.html` | Página dedicada de avaliação |
| `avaliacao-popup.html` | Componente de pop-up reutilizável |
| `SISTEMA_AVALIACAO_V2.md` | Esta documentação |

---

## 🔧 Personalização

### **Alterar Dentistas:**

Edite o `<select>` em `avaliacao.html` (linhas 330-342):

```html
<option value="Dr. Nome">Dr. Nome</option>
```

### **Alterar Intervalo do Pop-up:**

Edite `avaliacao-popup.html` (linha 238):

```javascript
const twoMinutes = 120000; // 2 minutos em milissegundos
```

Exemplos:
- 1 minuto: `60000`
- 5 minutos: `300000`
- 10 minutos: `600000`

### **Alterar Delay Inicial:**

Edite `avaliacao-popup.html` (linha 233):

```javascript
setTimeout(mostrarPopupAvaliacao, 3000); // 3 segundos
```

---

## ⚠️ Importante

### **Antes de Executar o SQL:**

- ⚠️ O script vai **DROPAR** a tabela `avaliacoes` antiga
- ⚠️ Todos os dados antigos serão **PERDIDOS**
- ✅ Se quiser manter os dados antigos, faça backup antes

### **Backup da Tabela Antiga:**

```sql
-- Criar backup
CREATE TABLE avaliacoes_backup AS 
SELECT * FROM avaliacoes;

-- Depois de executar o novo script, você pode consultar o backup
SELECT * FROM avaliacoes_backup;
```

---

## 🐛 Solução de Problemas

### **Pop-up não aparece:**

1. Abra o console (F12) e veja se há erros
2. Verifique se o arquivo `avaliacao-popup.html` está na raiz
3. Limpe o cache (Ctrl + Shift + R)
4. Verifique o localStorage: `localStorage.getItem('avaliacaoPopupLastShown')`

### **Erro ao enviar avaliação:**

1. Verifique se a tabela `avaliacoes` foi criada
2. Verifique se as políticas RLS foram aplicadas
3. Abra o console e veja o erro específico
4. Verifique a conexão com o Supabase

### **Pop-up aparece toda hora:**

1. Limpe o localStorage: `localStorage.clear()`
2. Feche e abra o navegador
3. Verifique se o código está correto em `avaliacao-popup.html`

---

## 📈 Métricas Recomendadas

### **Acompanhar:**

1. **Taxa de Resposta:** % de pacientes que avaliam
2. **Média Geral:** Média de todas as notas (0-10)
3. **Distribuição:** Quantas avaliações por nota
4. **Feedback Qualitativo:** Análise dos comentários
5. **Desempenho por Unidade:** Comparar médias
6. **Desempenho por Dentista:** Comparar médias

### **Metas Sugeridas:**

- **Média Geral:** ≥ 8.0
- **Taxa de Resposta:** ≥ 15%
- **Notas 9-10:** ≥ 60%
- **Notas 0-5:** ≤ 10%

---

## ✅ Checklist de Implementação

- [ ] Executar `sql_nova_tabela_avaliacoes.sql` no Supabase
- [ ] Verificar se a tabela foi criada corretamente
- [ ] Verificar se as políticas RLS foram aplicadas
- [ ] Fazer push dos arquivos para o GitHub
- [ ] Aguardar deploy (1-2 minutos)
- [ ] Limpar cache do navegador
- [ ] Testar pop-up em index.html
- [ ] Testar página de avaliação
- [ ] Enviar avaliação de teste
- [ ] Verificar se foi salva no banco
- [ ] Testar consultas SQL
- [ ] Personalizar lista de dentistas (se necessário)

---

## 🎉 Pronto para Uso!

O sistema V2.0 está completo e otimizado! Muito mais simples, rápido e eficiente que a versão anterior.

**Principais Melhorias:**

✅ Formulário simplificado (só o essencial)  
✅ Pop-up inteligente (não é invasivo)  
✅ Balão estilo HQ (chama atenção)  
✅ Página dedicada (melhor UX)  
✅ Lógica de exibição automática (2 em 2 minutos)  
✅ Não reaparece na mesma sessão  

**Versão:** 2.0.0  
**Data:** Dezembro 2024
