-- ============================================================================
-- TABELA DE AVALIAÇÕES DE ATENDIMENTO
-- ============================================================================
-- Esta tabela armazena as avaliações dos pacientes sobre o atendimento
-- recebido nas unidades de saúde bucal de Japeri.
-- ============================================================================

-- Criar tabela avaliacoes
CREATE TABLE IF NOT EXISTS public.avaliacoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamp with time zone DEFAULT now(),
    
    -- Dados do paciente
    nome_completo text NOT NULL,
    cpf text NOT NULL,
    celular text NOT NULL,
    email text,
    
    -- Dados do atendimento
    unidade_atendimento text NOT NULL,
    data_atendimento date NOT NULL,
    tipo_atendimento text NOT NULL, -- Ex: "Consulta", "Procedimento", "Urgência", etc.
    
    -- Avaliação (escala de 1 a 5)
    nota_atendimento integer NOT NULL CHECK (nota_atendimento >= 1 AND nota_atendimento <= 5),
    nota_profissional integer NOT NULL CHECK (nota_profissional >= 1 AND nota_profissional <= 5),
    nota_instalacoes integer NOT NULL CHECK (nota_instalacoes >= 1 AND nota_instalacoes <= 5),
    nota_tempo_espera integer NOT NULL CHECK (nota_tempo_espera >= 1 AND nota_tempo_espera <= 5),
    
    -- Feedback textual
    pontos_positivos text,
    pontos_negativos text,
    sugestoes text,
    
    -- Recomendação (NPS - Net Promoter Score)
    recomendaria_servico integer NOT NULL CHECK (recomendaria_servico >= 0 AND recomendaria_servico <= 10),
    
    -- Permissão para contato
    autoriza_contato boolean DEFAULT false
);

-- Criar índices para consultas rápidas
CREATE INDEX IF NOT EXISTS idx_avaliacoes_cpf ON public.avaliacoes USING btree (cpf);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_unidade ON public.avaliacoes USING btree (unidade_atendimento);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_data ON public.avaliacoes USING btree (data_atendimento DESC);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_nota ON public.avaliacoes USING btree (nota_atendimento);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_created ON public.avaliacoes USING btree (created_at DESC);

-- Adicionar comentários na tabela
COMMENT ON TABLE public.avaliacoes IS 'Avaliações dos pacientes sobre o atendimento recebido';
COMMENT ON COLUMN public.avaliacoes.id IS 'Identificador único da avaliação';
COMMENT ON COLUMN public.avaliacoes.created_at IS 'Data e hora do envio da avaliação';
COMMENT ON COLUMN public.avaliacoes.nome_completo IS 'Nome completo do paciente';
COMMENT ON COLUMN public.avaliacoes.cpf IS 'CPF do paciente (sem formatação)';
COMMENT ON COLUMN public.avaliacoes.celular IS 'Celular do paciente (sem formatação)';
COMMENT ON COLUMN public.avaliacoes.email IS 'E-mail do paciente (opcional)';
COMMENT ON COLUMN public.avaliacoes.unidade_atendimento IS 'Unidade onde foi atendido';
COMMENT ON COLUMN public.avaliacoes.data_atendimento IS 'Data em que foi atendido';
COMMENT ON COLUMN public.avaliacoes.tipo_atendimento IS 'Tipo de atendimento recebido';
COMMENT ON COLUMN public.avaliacoes.nota_atendimento IS 'Nota geral do atendimento (1 a 5)';
COMMENT ON COLUMN public.avaliacoes.nota_profissional IS 'Nota do profissional que atendeu (1 a 5)';
COMMENT ON COLUMN public.avaliacoes.nota_instalacoes IS 'Nota das instalações da unidade (1 a 5)';
COMMENT ON COLUMN public.avaliacoes.nota_tempo_espera IS 'Nota do tempo de espera (1 a 5)';
COMMENT ON COLUMN public.avaliacoes.pontos_positivos IS 'O que o paciente achou positivo';
COMMENT ON COLUMN public.avaliacoes.pontos_negativos IS 'O que o paciente achou negativo';
COMMENT ON COLUMN public.avaliacoes.sugestoes IS 'Sugestões de melhoria';
COMMENT ON COLUMN public.avaliacoes.recomendaria_servico IS 'De 0 a 10, quanto recomendaria o serviço (NPS)';
COMMENT ON COLUMN public.avaliacoes.autoriza_contato IS 'Se autoriza contato para esclarecimentos';

-- ============================================================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- ============================================================================

-- Habilitar Row Level Security
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;

-- Política: Qualquer pessoa pode inserir avaliações (público)
CREATE POLICY "Permitir INSERT público para avaliacoes"
ON public.avaliacoes
FOR INSERT
TO public
WITH CHECK (true);

-- Política: Apenas administradores autenticados podem visualizar avaliações
CREATE POLICY "Permitir SELECT apenas para administradores autenticados"
ON public.avaliacoes
FOR SELECT
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Política: Apenas administradores autenticados podem atualizar avaliações
CREATE POLICY "Permitir UPDATE apenas para administradores autenticados"
ON public.avaliacoes
FOR UPDATE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
)
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- Política: Apenas administradores autenticados podem deletar avaliações
CREATE POLICY "Permitir DELETE apenas para administradores autenticados"
ON public.avaliacoes
FOR DELETE
TO authenticated
USING (
    auth.uid() IN (
        SELECT id FROM public.administradores
    )
);

-- ============================================================================
-- FUNÇÃO PARA CALCULAR MÉDIA DE NOTAS POR UNIDADE
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calcular_media_avaliacoes_unidade(nome_unidade text)
RETURNS TABLE (
    unidade text,
    total_avaliacoes bigint,
    media_atendimento numeric,
    media_profissional numeric,
    media_instalacoes numeric,
    media_tempo_espera numeric,
    media_geral numeric,
    nps_score numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        nome_unidade::text AS unidade,
        COUNT(*)::bigint AS total_avaliacoes,
        ROUND(AVG(nota_atendimento), 2) AS media_atendimento,
        ROUND(AVG(nota_profissional), 2) AS media_profissional,
        ROUND(AVG(nota_instalacoes), 2) AS media_instalacoes,
        ROUND(AVG(nota_tempo_espera), 2) AS media_tempo_espera,
        ROUND(AVG((nota_atendimento + nota_profissional + nota_instalacoes + nota_tempo_espera)::numeric / 4), 2) AS media_geral,
        ROUND(AVG(recomendaria_servico), 2) AS nps_score
    FROM public.avaliacoes
    WHERE unidade_atendimento = nome_unidade;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.calcular_media_avaliacoes_unidade IS 'Calcula as médias de avaliação de uma unidade específica';

-- ============================================================================
-- QUERY DE EXEMPLO: Ver todas as avaliações (para administradores)
-- ============================================================================

-- SELECT * FROM public.avaliacoes ORDER BY created_at DESC;

-- ============================================================================
-- QUERY DE EXEMPLO: Ver média de avaliações de uma unidade
-- ============================================================================

-- SELECT * FROM public.calcular_media_avaliacoes_unidade('Marabá');

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================
