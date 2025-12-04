-- ============================================
-- TABELA: gestantes
-- Descrição: Armazena cadastros de gestantes
-- Sem sistema de fila (atendimento prioritário)
-- ============================================

CREATE TABLE IF NOT EXISTS gestantes (
    -- Identificação única
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Dados pessoais
    nome_completo TEXT NOT NULL,
    data_nascimento DATE NOT NULL,
    cpf TEXT UNIQUE NOT NULL,
    rg TEXT,
    celular TEXT NOT NULL,
    email TEXT,
    
    -- Endereço
    cep TEXT NOT NULL,
    logradouro TEXT NOT NULL,
    numero TEXT NOT NULL,
    complemento TEXT,
    bairro TEXT NOT NULL,
    cidade TEXT NOT NULL,
    estado TEXT NOT NULL,
    
    -- Dados de saúde
    cartao_sus TEXT,
    possui_plano_saude BOOLEAN DEFAULT false,
    nome_plano_saude TEXT,
    
    -- Dados específicos de gestante
    data_prevista_parto DATE NOT NULL,
    deseja_atendimento BOOLEAN NOT NULL,
    termo_gestante_aceito BOOLEAN DEFAULT true,
    
    -- Unidade
    unidade_preferencia TEXT NOT NULL,
    aceita_outra_unidade BOOLEAN DEFAULT false,
    
    -- Avaliação e observações
    probabilidade_recomendacao INTEGER CHECK (probabilidade_recomendacao >= 0 AND probabilidade_recomendacao <= 10),
    observacoes TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Índices para melhor performance
    CONSTRAINT cpf_valido CHECK (LENGTH(cpf) >= 11)
);

-- Criar índices para consultas rápidas
CREATE INDEX IF NOT EXISTS idx_gestantes_cpf ON gestantes(cpf);
CREATE INDEX IF NOT EXISTS idx_gestantes_celular ON gestantes(celular);
CREATE INDEX IF NOT EXISTS idx_gestantes_data_parto ON gestantes(data_prevista_parto);
CREATE INDEX IF NOT EXISTS idx_gestantes_deseja_atendimento ON gestantes(deseja_atendimento);
CREATE INDEX IF NOT EXISTS idx_gestantes_unidade ON gestantes(unidade_preferencia);
CREATE INDEX IF NOT EXISTS idx_gestantes_created_at ON gestantes(created_at DESC);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_gestantes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_gestantes_updated_at
    BEFORE UPDATE ON gestantes
    FOR EACH ROW
    EXECUTE FUNCTION update_gestantes_updated_at();

-- Comentários para documentação
COMMENT ON TABLE gestantes IS 'Cadastro de gestantes para atendimento odontológico prioritário';
COMMENT ON COLUMN gestantes.data_prevista_parto IS 'Data prevista do parto da gestante';
COMMENT ON COLUMN gestantes.deseja_atendimento IS 'Se a gestante deseja ser atendida durante a gestação';
COMMENT ON COLUMN gestantes.termo_gestante_aceito IS 'Confirmação de que a gestante aceitou o termo de declaração';

-- Habilitar RLS (Row Level Security)
ALTER TABLE gestantes ENABLE ROW LEVEL SECURITY;

-- Política: Permitir INSERT para todos (cadastro público)
CREATE POLICY "Permitir cadastro público de gestantes"
    ON gestantes
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Política: Permitir SELECT apenas para usuários autenticados
CREATE POLICY "Permitir leitura apenas para autenticados"
    ON gestantes
    FOR SELECT
    TO authenticated
    USING (true);

-- Política: Permitir UPDATE apenas para usuários autenticados
CREATE POLICY "Permitir atualização apenas para autenticados"
    ON gestantes
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Mensagem de sucesso
SELECT 'Tabela gestantes criada com sucesso!' AS resultado;
