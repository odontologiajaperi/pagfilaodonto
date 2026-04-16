-- ============================================================
-- AUTOMACAO TOTAL DA FILA E LIMPEZA DE AGENDADOS (V2)
-- ============================================================
-- Este script garante que:
-- 1. Novos pacientes recebam a posição correta automaticamente.
-- 2. Pacientes agendados saiam da fila NA HORA.
-- 3. Pacientes agendados cujo horário já passou sejam DELETADOS.
-- 4. A fila se reorganize sozinha quando alguém sai.

-- 1. LIMPEZA DE GATILHOS ANTIGOS (Para evitar conflitos)
DROP TRIGGER IF EXISTS trg_atribuir_posicao ON public.pacientes;
DROP TRIGGER IF EXISTS trg_processar_agendamento ON public.pacientes;
DROP TRIGGER IF EXISTS trg_limpeza_geral ON public.pacientes;

-- 2. FUNÇÃO: ATRIBUIR POSIÇÃO (Para novos cadastros)
CREATE OR REPLACE FUNCTION public.atribuir_posicao_fila_unidade()
RETURNS TRIGGER AS $$
DECLARE
    v_ultima_posicao INTEGER;
BEGIN
    -- Só atribui posição se o paciente estiver 'aguardando'
    IF (NEW.status = 'aguardando' AND (NEW.posicao_fila IS NULL OR NEW.posicao_fila = 0)) THEN
        SELECT COALESCE(MAX(posicao_fila), 0) INTO v_ultima_posicao
        FROM public.pacientes
        WHERE unidade_preferencia = NEW.unidade_preferencia
        AND status = 'aguardando';

        NEW.posicao_fila := v_ultima_posicao + 1;
        
        -- Garante que a data de submissão esteja preenchida
        IF NEW.submitted_at IS NULL THEN
            NEW.submitted_at := NOW();
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. FUNÇÃO: PROCESSAR AGENDAMENTO E REORGANIZAR FILA
CREATE OR REPLACE FUNCTION public.processar_agendamento_e_reorganizar()
RETURNS TRIGGER AS $$
BEGIN
    -- Se o status mudou de 'aguardando' para 'agendado' ou 'atendido'
    IF (NEW.status IN ('agendado', 'atendido') AND OLD.status = 'aguardando') THEN
        
        -- 1. Tira o paciente da fila (zera a posição)
        NEW.posicao_fila := NULL;
        
        -- 2. Puxa os outros da mesma unidade para frente
        IF OLD.posicao_fila IS NOT NULL THEN
            UPDATE public.pacientes
            SET posicao_fila = posicao_fila - 1
            WHERE unidade_preferencia = OLD.unidade_preferencia
              AND status = 'aguardando'
              AND posicao_fila > OLD.posicao_fila;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. FUNÇÃO: LIMPEZA DE AGENDADOS ANTIGOS
-- Esta função deleta quem já foi agendado e o horário já passou
CREATE OR REPLACE FUNCTION public.limpar_agendados_passados()
RETURNS TRIGGER AS $$
BEGIN
    -- Deleta registros agendados/atendidos onde a data já passou de hoje
    -- Usamos CURRENT_DATE para ser seguro e não deletar quem é para hoje ainda
    DELETE FROM public.pacientes 
    WHERE status IN ('agendado', 'atendido') 
    AND data_agendamento < CURRENT_DATE;
    
    RETURN NULL; -- Trigger AFTER não precisa retornar o registro
END;
$$ LANGUAGE plpgsql;

-- 5. REINSTALAR GATILHOS (TRIGGERS)

-- Gatilho 1: Antes de inserir, coloca na última posição da unidade
CREATE TRIGGER trg_atribuir_posicao
    BEFORE INSERT ON public.pacientes
    FOR EACH ROW
    EXECUTE FUNCTION public.atribuir_posicao_fila_unidade();

-- Gatilho 2: Antes de atualizar, se virou agendado, tira da fila e reorganiza os outros
CREATE TRIGGER trg_processar_agendamento
    BEFORE UPDATE ON public.pacientes
    FOR EACH ROW
    EXECUTE FUNCTION public.processar_agendamento_e_reorganizar();

-- Gatilho 3: Depois de qualquer mudança, limpa os agendados antigos do banco
CREATE TRIGGER trg_limpeza_geral
    AFTER INSERT OR UPDATE ON public.pacientes
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.limpar_agendados_passados();

-- 6. FUNÇÃO DE REPARO MANUAL (Caso precise forçar a ordem um dia)
CREATE OR REPLACE FUNCTION public.reparar_fila_unidade(p_unidade TEXT)
RETURNS void AS $$
DECLARE
    r RECORD;
    v_posicao INTEGER := 1;
BEGIN
    FOR r IN 
        SELECT id FROM public.pacientes 
        WHERE unidade_preferencia = p_unidade AND status = 'aguardando'
        ORDER BY submitted_at ASC 
    LOOP
        UPDATE public.pacientes SET posicao_fila = v_posicao WHERE id = r.id;
        v_posicao := v_posicao + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
