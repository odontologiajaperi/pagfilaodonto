-- ============================================================
-- SCRIPT: Campo ACS (Agente Comunitário de Saúde)
-- Controle de vagas para pacientes sem ACS por posto
-- ============================================================
-- Execute este script no SQL Editor do Supabase
-- APÓS executar o vagas_por_posto.sql (se ainda não executou)
-- ============================================================

-- 1. Adicionar coluna 'sem_acs' na tabela pacientes
-- Identifica quem marcou "Não tenho ACS" no cadastro
ALTER TABLE public.pacientes
ADD COLUMN IF NOT EXISTS sem_acs BOOLEAN DEFAULT false;

-- 2. Adicionar coluna 'percentual_sem_acs' na tabela postos
-- Define a porcentagem máxima de vagas sem ACS por posto (padrão 25%)
ALTER TABLE public.postos
ADD COLUMN IF NOT EXISTS percentual_sem_acs INTEGER DEFAULT 25;

-- 3. Criar função RPC para verificar se a cota sem ACS está disponível
-- Retorna true se ainda há vaga, false se a cota foi atingida
CREATE OR REPLACE FUNCTION public.verificar_cota_sem_acs(p_unidade TEXT)
RETURNS JSON AS $$
DECLARE
    v_vagas_limite INTEGER;
    v_percentual INTEGER;
    v_max_sem_acs INTEGER;
    v_atual_sem_acs INTEGER;
    v_disponivel BOOLEAN;
BEGIN
    -- Buscar configuração do posto
    SELECT vagas_limite, percentual_sem_acs
    INTO v_vagas_limite, v_percentual
    FROM public.postos
    WHERE nome = p_unidade AND ativo = true;

    -- Se o posto não existe ou não está ativo
    IF NOT FOUND THEN
        RETURN json_build_object('disponivel', false, 'motivo', 'Posto não encontrado ou inativo');
    END IF;

    -- Se não tem limite de vagas ou percentual definido, liberar sem restrição
    IF v_vagas_limite IS NULL OR v_percentual IS NULL THEN
        RETURN json_build_object('disponivel', true, 'motivo', 'Sem restrição configurada');
    END IF;

    -- Calcular máximo de vagas sem ACS
    v_max_sem_acs := FLOOR(v_vagas_limite * v_percentual::NUMERIC / 100);

    -- Se o máximo calculado for 0, pelo menos 1 vaga sem ACS
    IF v_max_sem_acs < 1 THEN
        v_max_sem_acs := 1;
    END IF;

    -- Contar quantos sem ACS já estão cadastrados nesse posto
    SELECT COUNT(*)
    INTO v_atual_sem_acs
    FROM public.pacientes
    WHERE unidade_preferencia = p_unidade
      AND sem_acs = true
      AND status = 'aguardando';

    -- Verificar disponibilidade
    v_disponivel := v_atual_sem_acs < v_max_sem_acs;

    RETURN json_build_object(
        'disponivel', v_disponivel,
        'max_sem_acs', v_max_sem_acs,
        'atual_sem_acs', v_atual_sem_acs,
        'vagas_restantes_sem_acs', GREATEST(0, v_max_sem_acs - v_atual_sem_acs)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Dar permissão para o site chamar a função
GRANT EXECUTE ON FUNCTION public.verificar_cota_sem_acs(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.verificar_cota_sem_acs(TEXT) TO authenticated;

-- 5. Criar view para monitorar a situação das vagas sem ACS
CREATE OR REPLACE VIEW public.situacao_vagas_sem_acs AS
SELECT
    p.id,
    p.nome,
    p.ativo,
    p.vagas_limite,
    p.percentual_sem_acs,
    CASE
        WHEN p.vagas_limite IS NOT NULL AND p.percentual_sem_acs IS NOT NULL
        THEN FLOOR(p.vagas_limite * p.percentual_sem_acs::NUMERIC / 100)
        ELSE NULL
    END AS max_vagas_sem_acs,
    COALESCE(sem_acs_count.total, 0) AS inscritos_sem_acs,
    CASE
        WHEN p.vagas_limite IS NOT NULL AND p.percentual_sem_acs IS NOT NULL
        THEN GREATEST(0, FLOOR(p.vagas_limite * p.percentual_sem_acs::NUMERIC / 100) - COALESCE(sem_acs_count.total, 0))
        ELSE NULL
    END AS vagas_sem_acs_restantes,
    CASE
        WHEN p.vagas_limite IS NULL OR p.percentual_sem_acs IS NULL THEN 'Sem restrição'
        WHEN COALESCE(sem_acs_count.total, 0) >= FLOOR(p.vagas_limite * p.percentual_sem_acs::NUMERIC / 100) THEN 'COTA ESGOTADA'
        ELSE 'Disponível'
    END AS status_cota_sem_acs
FROM public.postos p
LEFT JOIN (
    SELECT unidade_preferencia, COUNT(*) AS total
    FROM public.pacientes
    WHERE sem_acs = true AND status = 'aguardando'
    GROUP BY unidade_preferencia
) sem_acs_count ON sem_acs_count.unidade_preferencia = p.nome
ORDER BY p.nome;

-- 6. Dar permissão de leitura na view
GRANT SELECT ON public.situacao_vagas_sem_acs TO anon;
GRANT SELECT ON public.situacao_vagas_sem_acs TO authenticated;

-- ============================================================
-- CONFIGURAÇÃO INICIAL
-- Após executar este script, ajuste o percentual por posto:
--
-- UPDATE public.postos SET percentual_sem_acs = 25 WHERE nome = 'Alecrim';
-- UPDATE public.postos SET percentual_sem_acs = 25 WHERE nome = 'Chacrinha';
-- UPDATE public.postos SET percentual_sem_acs = 25 WHERE nome = 'São Jorge';
--
-- Para ver a situação atual:
-- SELECT * FROM public.situacao_vagas_sem_acs;
-- ============================================================
