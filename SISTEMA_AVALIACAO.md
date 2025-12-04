# ⭐ Sistema de Avaliação de Atendimento

## 📋 Visão Geral

Sistema completo de avaliação de atendimento para a Saúde Bucal de Japeri, permitindo que pacientes avaliem o serviço recebido e forneçam feedback valioso para melhoria contínua.

---

## ✨ Funcionalidades

### **1. Botão Flutuante (Estilo "Spam")**

- 🎯 **Localização:** Canto inferior direito
- 📱 **Páginas:** `cadastro.html` e `consulta-fila.html`
- 🎨 **Estilo:** Botão redondo com gradiente verde/azul
- ✨ **Animação:** Pulse e bounce para chamar atenção
- 💬 **Tooltip:** "Avalie seu atendimento!" ao passar o mouse

### **2. Card de Destaque**

- 📍 **Localização:** Após o card de gestantes
- 📱 **Páginas:** `index.html` e `unidades.html`
- 🎨 **Estilo:** Card verde claro com borda verde
- 📝 **Texto:** "Já foi atendido? Sua opinião é muito importante!"

### **3. Modal de Avaliação Completo**

- ✅ Formulário com validação
- ⭐ Sistema de avaliação por estrelas (1-5)
- 📊 NPS (Net Promoter Score) de 0-10
- 📝 Campos de feedback textual
- 🔒 Máscaras automáticas para CPF e celular

---

## 🗄️ Estrutura do Banco de Dados

### **Tabela: `avaliacoes`**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid | Identificador único |
| `created_at` | timestamp | Data/hora do envio |
| `nome_completo` | text | Nome do paciente |
| `cpf` | text | CPF (sem formatação) |
| `celular` | text | Celular (sem formatação) |
| `email` | text | E-mail (opcional) |
| `unidade_atendimento` | text | Unidade onde foi atendido |
| `data_atendimento` | date | Data do atendimento |
| `tipo_atendimento` | text | Tipo (Consulta, Procedimento, etc.) |
| `nota_atendimento` | integer | Nota geral (1-5) |
| `nota_profissional` | integer | Nota do profissional (1-5) |
| `nota_instalacoes` | integer | Nota das instalações (1-5) |
| `nota_tempo_espera` | integer | Nota do tempo de espera (1-5) |
| `pontos_positivos` | text | Feedback positivo |
| `pontos_negativos` | text | Feedback negativo |
| `sugestoes` | text | Sugestões de melhoria |
| `recomendaria_servico` | integer | NPS (0-10) |
| `autoriza_contato` | boolean | Autoriza contato |

### **Índices Criados:**

- `idx_avaliacoes_cpf` - Busca por CPF
- `idx_avaliacoes_unidade` - Filtro por unidade
- `idx_avaliacoes_data` - Ordenação por data
- `idx_avaliacoes_nota` - Filtro por nota
- `idx_avaliacoes_created` - Ordenação por criação

---

## 🔒 Políticas de Segurança (RLS)

### **Permissões:**

| Operação | Quem Pode |
|----------|-----------|
| **INSERT** | 🌐 Qualquer pessoa (público) |
| **SELECT** | 🔒 Apenas administradores autenticados |
| **UPDATE** | 🔒 Apenas administradores autenticados |
| **DELETE** | 🔒 Apenas administradores autenticados |

**Justificativa:**
- Pacientes podem enviar avaliações livremente
- Apenas administradores podem visualizar e gerenciar avaliações
- Protege a privacidade dos dados dos pacientes

---

## 📊 Função de Análise

### **`calcular_media_avaliacoes_unidade(nome_unidade)`**

Calcula estatísticas de avaliação para uma unidade específica:

```sql
SELECT * FROM calcular_media_avaliacoes_unidade('Marabá');
```

**Retorna:**
- Total de avaliações
- Média de cada categoria (atendimento, profissional, instalações, tempo)
- Média geral
- NPS Score

---

## 📁 Arquivos do Sistema

### **1. `sql_tabela_avaliacoes.sql`**
- Script completo para criar a tabela
- Políticas RLS
- Função de análise
- Comentários e documentação

### **2. `avaliacao-component.html`**
- Componente completo (HTML + CSS + JS)
- Botão flutuante
- Modal de avaliação
- Integração com Supabase

### **3. `avaliacao-card-component.html`**
- Card de destaque para index e unidades
- Versão não-flutuante

---

## 🚀 Como Implementar

### **Passo 1: Criar a Tabela no Supabase**

1. Acesse: https://supabase.com/dashboard/project/uakhmgoxgyklggsvtwdf
2. Vá em **SQL Editor** → **New Query**
3. Copie e cole o conteúdo de `sql_tabela_avaliacoes.sql`
4. Clique em **Run**

### **Passo 2: Verificar Implementação**

Os arquivos já foram modificados:

- ✅ `cadastro.html` - Botão flutuante adicionado
- ✅ `consulta-fila.html` - Botão flutuante adicionado
- ✅ `index.html` - Card adicionado
- ✅ `unidades.html` - Card adicionado

### **Passo 3: Testar**

1. Acesse qualquer página modificada
2. Veja o botão flutuante ou card
3. Clique para abrir o modal
4. Preencha e envie uma avaliação de teste

---

## 🎨 Personalização

### **Cores do Sistema:**

- **Verde Claro:** `#e8f5e9` (fundo do card)
- **Verde Médio:** `#c8e6c9` (gradiente)
- **Verde Escuro:** `#1DC56F` (borda e botões)
- **Verde Texto:** `#2e7d32` (títulos)
- **Azul:** `#0F8BD6` (gradiente do botão flutuante)

### **Animações:**

- **Pulse:** Pulsação contínua do botão flutuante
- **Bounce:** Movimento de "pulo" do ícone
- **FadeIn:** Entrada suave do modal
- **SlideUp:** Deslizamento do modal de baixo para cima

---

## 📊 Consultas Úteis

### **Ver todas as avaliações (mais recentes primeiro):**

```sql
SELECT * FROM avaliacoes 
ORDER BY created_at DESC;
```

### **Ver avaliações de uma unidade específica:**

```sql
SELECT * FROM avaliacoes 
WHERE unidade_atendimento = 'Marabá'
ORDER BY created_at DESC;
```

### **Ver média de avaliações por unidade:**

```sql
SELECT 
    unidade_atendimento,
    COUNT(*) as total,
    ROUND(AVG(nota_atendimento), 2) as media_atendimento,
    ROUND(AVG(nota_profissional), 2) as media_profissional,
    ROUND(AVG(recomendaria_servico), 2) as nps
FROM avaliacoes
GROUP BY unidade_atendimento
ORDER BY media_atendimento DESC;
```

### **Ver avaliações com nota baixa (1 ou 2):**

```sql
SELECT 
    nome_completo,
    unidade_atendimento,
    nota_atendimento,
    pontos_negativos,
    sugestoes
FROM avaliacoes
WHERE nota_atendimento <= 2
ORDER BY created_at DESC;
```

### **Calcular NPS (Net Promoter Score):**

```sql
SELECT 
    unidade_atendimento,
    COUNT(*) as total_avaliacoes,
    COUNT(CASE WHEN recomendaria_servico >= 9 THEN 1 END) as promotores,
    COUNT(CASE WHEN recomendaria_servico <= 6 THEN 1 END) as detratores,
    ROUND(
        (COUNT(CASE WHEN recomendaria_servico >= 9 THEN 1 END)::numeric - 
         COUNT(CASE WHEN recomendaria_servico <= 6 THEN 1 END)::numeric) / 
        COUNT(*)::numeric * 100, 
        2
    ) as nps_score
FROM avaliacoes
GROUP BY unidade_atendimento;
```

---

## 🔍 Interpretação do NPS

| Score | Classificação | Significado |
|-------|---------------|-------------|
| **75-100** | 🌟 Excelente | Clientes extremamente satisfeitos |
| **50-74** | ✅ Muito Bom | Boa satisfação geral |
| **0-49** | ⚠️ Razoável | Precisa melhorar |
| **< 0** | ❌ Crítico | Urgente necessidade de melhoria |

---

## 📱 Responsividade

### **Mobile:**
- Botão flutuante menor
- Tooltip oculto
- Modal ocupa 100% da largura (com padding)
- Estrelas menores
- NPS em 2 linhas

### **Desktop:**
- Botão flutuante com tooltip
- Modal centralizado (max-width: 600px)
- Layout otimizado para telas grandes

---

## ⚡ Performance

### **Otimizações:**

- ✅ Componente carregado via `fetch()` (não bloqueia página)
- ✅ Máscaras aplicadas apenas quando necessário
- ✅ Validação em tempo real
- ✅ Índices no banco para consultas rápidas
- ✅ Animações com `transform` (GPU-accelerated)

---

## 🐛 Solução de Problemas

### **Botão não aparece:**

1. Verifique se o arquivo `avaliacao-component.html` está na raiz
2. Abra o console (F12) e veja se há erros
3. Verifique se o Supabase está configurado

### **Erro ao enviar avaliação:**

1. Verifique se a tabela `avaliacoes` foi criada
2. Verifique se as políticas RLS foram aplicadas
3. Verifique a conexão com o Supabase

### **Modal não abre:**

1. Verifique se a função `abrirModalAvaliacao()` está definida
2. Verifique se há conflitos com outros modais
3. Abra o console e veja se há erros de JavaScript

---

## 📈 Métricas Recomendadas

### **Acompanhar:**

1. **Taxa de Resposta:** % de pacientes que avaliam
2. **Média Geral:** Média de todas as notas (1-5)
3. **NPS:** Net Promoter Score (0-100)
4. **Distribuição:** Quantas avaliações por estrela
5. **Feedback Qualitativo:** Análise dos textos

### **Metas Sugeridas:**

- **Média Geral:** ≥ 4.0
- **NPS:** ≥ 50
- **Taxa de Resposta:** ≥ 20%

---

## ✅ Checklist de Implementação

- [ ] Executar `sql_tabela_avaliacoes.sql` no Supabase
- [ ] Verificar se as políticas RLS foram criadas
- [ ] Fazer push dos arquivos modificados
- [ ] Testar botão flutuante em cadastro.html
- [ ] Testar botão flutuante em consulta-fila.html
- [ ] Testar card em index.html
- [ ] Testar card em unidades.html
- [ ] Enviar avaliação de teste
- [ ] Verificar se a avaliação foi salva no banco
- [ ] Testar consultas de análise

---

## 🎉 Pronto para Uso!

O sistema está completo e pronto para receber avaliações dos pacientes. Basta executar o SQL no Supabase e fazer o deploy das páginas modificadas!

**Versão:** 1.0.0  
**Data:** Dezembro 2024
