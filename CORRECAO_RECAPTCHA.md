# 🔧 Correção do Erro do reCAPTCHA

## ❌ Problema Identificado

**Erro:** `Could not find the 'g-recaptcha-response' column of 'pacientes' in the schema cache`

### Causa

O formulário estava coletando **todos** os campos do formulário HTML, incluindo o campo oculto `g-recaptcha-response` gerado automaticamente pelo Google reCAPTCHA, e tentando enviar para o banco de dados.

Como a tabela `pacientes` (e `gestantes`) não possui uma coluna chamada `g-recaptcha-response`, o Supabase retornava esse erro.

---

## ✅ Solução Aplicada

Adicionei uma linha de código para **remover** o campo `g-recaptcha-response` antes de enviar os dados para o banco de dados.

### Código Modificado (linha 786)

**Antes:**
```javascript
// Remover campo que não vai para o banco
delete data.aceita_termos;
```

**Depois:**
```javascript
// Remover campos que não vão para o banco
delete data.aceita_termos;
delete data['g-recaptcha-response'];
```

---

## 📝 Explicação

O código agora remove **dois campos** que não devem ser enviados ao banco de dados:

1. **`aceita_termos`** - Checkbox de aceite dos termos (não precisa ser armazenado)
2. **`g-recaptcha-response`** - Token do reCAPTCHA (usado apenas para validação, não para armazenamento)

---

## 🧪 Como Testar

1. Acesse o formulário de cadastro
2. Preencha todos os campos
3. Marque "Aceito os termos"
4. Complete o reCAPTCHA (marque "Não sou um robô")
5. Clique em "Enviar Cadastro"
6. **Resultado esperado:** Cadastro realizado com sucesso, sem erro

---

## 🎯 Próximos Passos

1. ✅ Substitua o arquivo `cadastro.html` no seu repositório
2. ✅ Faça commit e push das mudanças
3. ✅ Teste o formulário no site
4. ✅ Confirme que o erro foi corrigido

---

## 📌 Observação

O reCAPTCHA continua funcionando normalmente. A única mudança foi **não enviar** o token de resposta para o banco de dados, já que ele não é necessário para armazenamento (é usado apenas para validação no momento do envio).

---

## ✨ Correção Aplicada com Sucesso!

O arquivo `cadastro.html` foi corrigido e está pronto para uso.
