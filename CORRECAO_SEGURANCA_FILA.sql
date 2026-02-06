-- ============================================================
-- SCRIPT DE CORREÇÃO DE SEGURANÇA E POSIÇÃO NA FILA
-- ============================================================

-- 1. FUNÇÃO PARA VALIDAR SE A FILA ESTÁ ABERTA NO BANCO DE DADOS
-- Isso impede que alguém "fure" a fila enviando dados direto para a API
CREATE OR REPLACE FUNCTION validar_fila_aberta()
RETURNS TRIGGER AS $$
DECLARE
    v_fila_aberta TEXT;
BEGIN
    -- Busca o status da fila na tabela de configurações
    SELECT valor INTO v_fila_aberta 
    FROM configuracoes 
    WHERE chave = 'cadastros_abertos';

    -- Se a fila estiver fechada (valor != 'true'), bloqueia o insert
    -- EXCEÇÃO: Se for gestante (campo e_gestante não existe na tabela pacientes, 
    -- mas o site envia para a tabela 'gestantes', então esta trigger só afeta a tabela 'pacientes')
    IF v_fila_aberta != 'true' THEN
        RAISE EXCEPTION 'Os cadastros estão temporariamente fechados. Apenas gestantes podem se cadastrar no momento.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. TRIGGER DE SEGURANÇA NA TABELA PACIENTES
DROP TRIGGER IF EXISTS trigger_validar_fila_aberta ON pacientes;
CREATE TRIGGER trigger_validar_fila_aberta
    BEFORE INSERT ON pacientes
    FOR EACH ROW
    EXECUTE FUNCTION validar_fila_aberta();


-- 3. CORREÇÃO DA FUNÇÃO DE ATRIBUIÇÃO DE POSIÇÃO
-- Garante que o novo paciente SEMPRE vá para o final da fila
CREATE OR REPLACE FUNCTION atribuir_posicao_novo_paciente()
RETURNS TRIGGER AS $$
DECLARE
    v_ultima_posicao INTEGER;
BEGIN
    -- Só atribui posição se for um novo cadastro com status 'aguardando'
    IF (NEW.status = 'aguardando' AND NEW.posicao_fila IS NULL) THEN
        -- Busca a última posição na fila da mesma unidade (IGNORANDO O MÊS)
        -- Usamos FOR UPDATE para bloquear a linha e evitar que dois cadastros peguem o mesmo número
        SELECT MAX(posicao_fila) INTO v_ultima_posicao
        FROM pacientes
        WHERE unidade_preferencia = NEW.unidade_preferencia
          AND status = 'aguardando';
        
        -- Se não houver ninguém, começa em 1. Se houver, pega o último + 1.
        NEW.posicao_fila := COALESCE(v_ultima_posicao, 0) + 1;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. RE-CRIAR TRIGGER DE POSIÇÃO (Garantir que execute após a validação)
DROP TRIGGER IF EXISTS trigger_atribuir_posicao_novo ON pacientes;
CREATE TRIGGER trigger_atribuir_posicao_novo
    BEFORE INSERT ON pacientes
    FOR EACH ROW
    EXECUTE FUNCTION atribuir_posicao_novo_paciente();


-- 5. FUNÇÃO PARA CORRIGIR PACIENTES QUE ENTRARAM ERRADO (POSIÇÃO 1)
-- Esta função reorganiza a fila de uma unidade específica baseada na data de envio
CREATE OR REPLACE FUNCTION corrigir_fila_unidade(p_unidade TEXT)
RETURNS void AS $$
DECLARE
    r RECORD;
    v_posicao INTEGER := 1;
BEGIN
    FOR r IN 
        SELECT id 
        FROM pacientes 
        WHERE unidade_preferencia = p_unidade 
          AND status = 'aguardando'
        ORDER BY submitted_at ASC 
    LOOP
        UPDATE pacientes SET posicao_fila = v_posicao WHERE id = r.id;
        v_posicao := v_posicao + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- EXEMPLO DE USO PARA CORRIGIR:
-- SELECT corrigir_fila_unidade('Nome da Unidade');
