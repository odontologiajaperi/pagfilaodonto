# Análise de RLS para Todas as Tabelas

## Tabelas do Sistema

### 1. **pacientes**
- **Acesso Público:** Precisa permitir INSERT (cadastro) e SELECT (validação de CPF)
- **Acesso Restrito:** UPDATE e DELETE apenas para administradores
- **Justificativa:** Formulário público precisa cadastrar pacientes e validar CPF duplicado

### 2. **gestantes**
- **Acesso Público:** Precisa permitir INSERT (cadastro) e SELECT (validação de CPF)
- **Acesso Restrito:** UPDATE e DELETE apenas para administradores
- **Justificativa:** Formulário público precisa cadastrar gestantes e validar CPF duplicado

### 3. **postos**
- **Acesso Público:** Apenas SELECT (listar postos no formulário)
- **Acesso Restrito:** INSERT, UPDATE e DELETE apenas para administradores
- **Justificativa:** Usuários precisam ver a lista de postos, mas não podem modificá-los

### 4. **configuracoes**
- **Acesso Público:** Apenas SELECT (verificar se cadastros estão abertos)
- **Acesso Restrito:** INSERT, UPDATE e DELETE apenas para administradores
- **Justificativa:** Formulário precisa verificar se pode aceitar cadastros, mas só admins podem mudar configurações

### 5. **administradores**
- **Acesso Público:** NENHUM
- **Acesso Restrito:** Apenas administradores autenticados podem SELECT, INSERT, UPDATE e DELETE
- **Justificativa:** Dados sensíveis, não devem ser acessíveis publicamente

## Estratégia de Implementação

1. Habilitar RLS em todas as tabelas
2. Criar políticas públicas para operações necessárias no formulário
3. Criar políticas restritas para administradores
4. Testar cada política individualmente
