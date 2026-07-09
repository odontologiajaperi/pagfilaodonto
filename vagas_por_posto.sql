-- ============================================================
-- VAGAS POR POSTO - FECHAMENTO AUTOMÁTICO DA FILA
-- ============================================================
-- Execute este script no SQL Editor do Supabase.
-- Ele adiciona a coluna vagas_limite à tabela postos e cria
-- um trigger que desativa automaticamente o posto quando o
-- número de inscritos aguardando atinge o limite configurado.
-- ============================================================

-- 1. Adicionar coluna vagas_limite à tabela postos
--    (NULL = sem limite, 0 = fechado manualmente, >0 = tem limite)
ALTER TABLE public.postos
    ADD COLUMN IF NOT EXISTS vagas_limite INTEGER DEFAULT NULL;

-- 2. FUNÇÃO: Verificar e fechar posto quando atingir o limite
CREATE OR REPLACE FUNCTION public.verificar_vagas_posto()
RETURNS TRIGGER AS $$
DECLARE
    v_limite INTEGER;
    v_inscritos INTEGER;
BEGIN
    -- Só executa quando um novo paciente é inserido com status 'aguardando'
    IF TG_OP = 'INSERT' AND NEW.status = 'aguardando' THEN

        -- Buscar o limite do posto escolhido pelo paciente
        SELECT vagas_limite INTO v_limite
        FROM public.postos
        WHERE nome = NEW.unidade_preferencia
          AND ativo = true;

        -- Se o posto tem limite definido (não é NULL)
        IF v_limite IS NOT NULL THEN

            -- Contar quantos já estão aguardando nesse posto
            SELECT COUNT(*) INTO v_inscritos
            FROM public.pacientes
            WHERE unidade_preferencia = NEW.unidade_preferencia
              AND status = 'aguardando';

            -- Se atingiu ou ultrapassou o limite, desativar o posto
            IF v_inscritos >= v_limite THEN
                UPDATE public.postos
                SET ativo = false
                WHERE nome = NEW.unidade_preferencia;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Remover trigger antigo se existir e recriar
DROP TRIGGER IF EXISTS trg_verificar_vagas_posto ON public.pacientes;

CREATE TRIGGER trg_verificar_vagas_posto
    AFTER INSERT ON public.pacientes
    FOR EACH ROW
    EXECUTE FUNCTION public.verificar_vagas_posto();

-- 4. FUNÇÃO: Reabrir posto e resetar vagas (use quando quiser abrir nova rodada)
--    Exemplo de uso: SELECT public.reabrir_posto('CEMES Engenheiro Pedreira', 50);
CREATE OR REPLACE FUNCTION public.reabrir_posto(p_nome TEXT, p_novo_limite INTEGER DEFAULT NULL)
RETURNS void AS $$
BEGIN
    UPDATE public.postos
    SET ativo = true,
        vagas_limite = COALESCE(p_novo_limite, vagas_limite)
    WHERE nome = p_nome;
END;
$$ LANGUAGE plpgsql;

-- 5. VIEW útil: mostra situação atual de cada posto
CREATE OR REPLACE VIEW public.situacao_postos AS
SELECT
    p.id,
    p.nome,
    p.ativo,
    p.vagas_limite,
    COUNT(pac.id) FILTER (WHERE pac.status = 'aguardando') AS inscritos_aguardando,
    CASE
        WHEN p.vagas_limite IS NULL THEN NULL
        ELSE GREATEST(0, p.vagas_limite - COUNT(pac.id) FILTER (WHERE pac.status = 'aguardando'))
    END AS vagas_restantes
FROM public.postos p
LEFT JOIN public.pacientes pac ON pac.unidade_preferencia = p.nome
GROUP BY p.id, p.nome, p.ativo, p.vagas_limite
ORDER BY p.nome;

-- ============================================================
-- COMO USAR:
-- 1. Execute este script no SQL Editor do Supabase.
-- 2. Defina o limite de vagas de cada posto, por exemplo:
--    UPDATE public.postos SET vagas_limite = 50 WHERE nome = 'CEMES Engenheiro Pedreira';
--    UPDATE public.postos SET vagas_limite = 30 WHERE nome = 'UBS Mucajá';
--    (Deixe NULL para postos sem limite)
-- 3. Para ver a situação atual: SELECT * FROM public.situacao_postos;
-- 4. Para reabrir um posto com novo limite:
--    SELECT public.reabrir_posto('CEMES Engenheiro Pedreira', 60);
-- ============================================================
