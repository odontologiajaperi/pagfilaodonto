-- Tabela de configurações do sistema
-- Permite controlar se os cadastros estão abertos ou fechados

CREATE TABLE IF NOT EXISTS configuracoes (
    id SERIAL PRIMARY KEY,
    chave VARCHAR(100) UNIQUE NOT NULL,
    valor TEXT NOT NULL,
    descricao TEXT,
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_por VARCHAR(100)
);

-- Inserir configuração inicial (cadastros abertos por padrão)
INSERT INTO configuracoes (chave, valor, descricao) 
VALUES (
    'cadastros_abertos',
    'true',
    'Define se os cadastros na fila estão abertos (true) ou fechados (false)'
) ON CONFLICT (chave) DO NOTHING;

-- Inserir mensagem personalizada quando fechado
INSERT INTO configuracoes (chave, valor, descricao) 
VALUES (
    'mensagem_cadastro_fechado',
    'Os cadastros estão temporariamente fechados. Em breve abriremos novas vagas. Acompanhe nossos avisos para saber quando os cadastros serão reabertos.',
    'Mensagem exibida quando os cadastros estão fechados'
) ON CONFLICT (chave) DO NOTHING;

-- Criar função para atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION atualizar_timestamp_configuracoes()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger para atualizar timestamp
DROP TRIGGER IF EXISTS trigger_atualizar_timestamp_configuracoes ON configuracoes;
CREATE TRIGGER trigger_atualizar_timestamp_configuracoes
    BEFORE UPDATE ON configuracoes
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp_configuracoes();

-- Comentários na tabela
COMMENT ON TABLE configuracoes IS 'Configurações gerais do sistema de fila';
COMMENT ON COLUMN configuracoes.chave IS 'Identificador único da configuração';
COMMENT ON COLUMN configuracoes.valor IS 'Valor da configuração (pode ser texto, número, boolean como string)';
COMMENT ON COLUMN configuracoes.descricao IS 'Descrição do que a configuração faz';
COMMENT ON COLUMN configuracoes.atualizado_em IS 'Data e hora da última atualização';
COMMENT ON COLUMN configuracoes.atualizado_por IS 'Usuário que fez a última atualização';
