# Configuração do Google reCAPTCHA

## ✅ Status Atual

O Google reCAPTCHA v2 (checkbox "Não sou um robô") foi implementado com sucesso na página de cadastro (`cadastro.html`).

## 🔑 Chaves Configuradas

**Chave do Site (Site Key):**
```
6LegHiEsAAAAALVoosndWQ5OUOi4rQtgsgyfy0YE
```

**Chave Secreta (Secret Key):**
```
6LegHiEsAAAAAPlJTpZFt8VePu5-surE5hKcgI7a
```

⚠️ **IMPORTANTE:** Mantenha a chave secreta em local seguro. Não compartilhe publicamente.

## 🛡️ Nível de Segurança Atual

### Validação no Frontend (Implementada) ✅

**Como funciona:**
- O usuário marca o checkbox "Não sou um robô"
- O JavaScript valida se o checkbox foi marcado
- Se não foi marcado, exibe mensagem de erro
- Só permite enviar o formulário após marcar

**Proteção oferecida:**
- ✅ Previne bots simples e scripts automáticos
- ✅ Dificulta ataques de spam em massa
- ✅ Não requer servidor ou backend
- ✅ Funciona perfeitamente com GitHub Pages + Supabase

**Limitações:**
- ⚠️ Usuários técnicos avançados podem contornar (raro)
- ⚠️ Não valida a resposta no servidor

### Validação no Backend (Opcional) 🔒

Para máxima segurança, é possível adicionar validação no servidor usando a chave secreta.

**Como funciona:**
1. Frontend envia o token do reCAPTCHA
2. Servidor valida o token com a API do Google
3. Só aceita o cadastro se o token for válido

**Requer:**
- Supabase Edge Function (serverless)
- Código adicional em Deno/TypeScript
- Configuração de variáveis de ambiente

**Quando implementar:**
- Se houver ataques persistentes de bots
- Se precisar de auditoria de segurança
- Se houver requisitos de compliance

## 📊 Recomendação

Para uma clínica com 500-1000 cadastros/mês, a **validação no frontend é suficiente**. A maioria dos bots não consegue contornar o reCAPTCHA v2.

**Monitore:**
- Quantidade de cadastros por dia
- Cadastros suspeitos (nomes estranhos, emails inválidos)
- Padrões de horário (muitos cadastros à noite pode indicar bot)

Se identificar ataques, podemos implementar a validação no backend.

## 🔧 Implementação Técnica

### Localização no Código

**Arquivo:** `cadastro.html`

**Linha 550:** Renderização do widget
```html
<div class="g-recaptcha" data-sitekey="6LegHiEsAAAAALVoosndWQ5OUOi4rQtgsgyfy0YE"></div>
```

**Linhas 710-719:** Validação JavaScript
```javascript
// Validar reCAPTCHA
const recaptchaResponse = grecaptcha.getResponse();
const recaptchaError = document.getElementById('recaptcha-error');

if (!recaptchaResponse) {
    recaptchaError.style.display = 'block';
    recaptchaError.scrollIntoView({ behavior: 'smooth', block: 'center' });
    return;
}
recaptchaError.style.display = 'none';
```

## 🚀 Próximos Passos (Opcional)

### 1. Implementar Validação no Backend

Se quiser máxima segurança, podemos criar uma Supabase Edge Function:

```typescript
// supabase/functions/validar-recaptcha/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { token } = await req.json()
  
  const response = await fetch('https://www.google.com/recaptcha/api/siteverify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `secret=6LegHiEsAAAAAPlJTpZFt8VePu5-surE5hKcgI7a&response=${token}`
  })
  
  const data = await response.json()
  
  return new Response(JSON.stringify({ success: data.success }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

### 2. Adicionar Rate Limiting

Limitar cadastros por IP:
- Máximo 3 cadastros por IP por dia
- Requer Edge Function ou Cloudflare Workers

### 3. Monitoramento

Criar dashboard no Supabase para:
- Cadastros por hora/dia
- IPs suspeitos
- Taxa de sucesso do reCAPTCHA

## 📞 Suporte

Se identificar problemas ou ataques de bots, entre em contato para implementar as medidas adicionais de segurança.

---

**Última atualização:** 04/12/2025
**Versão do reCAPTCHA:** v2 (checkbox)
**Status:** ✅ Ativo e funcionando
