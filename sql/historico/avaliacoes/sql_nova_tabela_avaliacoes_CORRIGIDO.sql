-- ============================================================================
-- RECRIAR TABELA DE AVALIAÇÕES (VERSÃO SIMPLIFICADA) - CORRIGIDO
-- ============================================================================
-- Este script remove TUDO da versão antiga e cria uma nova versão simplificada
-- ============================================================================

-- PASSO 1: Remover as FUNÇÕES antigas (se existirem)
DROP FUNCTION IF EXISTS public.calcular_media_avaliacoes_unidade(text);
DROP FUNCTION IF EXISTS public.calcular_media_geral_avaliacoes();

-- PASSO 2: Remover a tabela antiga (se existir)
DROP TABLE IF EXISTS public.avaliacoes CASCADE;

-- PASSO 3: Criar nova tabela simplificada
CREATE TABLE public.avaliacoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamp with time zone DEFAULT now(),
    
    -- Dados do paciente
    cpf text NOT NULL,
    
    -- Dados do atendimento
    data_atendimento date NOT NULL,
    unidade text NOT NULL,
    cirurgiao_dentista text NOT NULL,
    
    -- Avaliação
    nota integer NOT NULL CHECK (nota >= 0 AND nota <= 10),
    comentario text
);

-- PASSO 4: Criar índices
CREATE INDEX IF NOT EXISTS idx_avaliacoes_cpf ON public.avaliacoes USING btree (cpf);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_unidade ON public.avaliacoes USING btree (unidade);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_data ON public.avaliacoes USING btree (data_atendimento DESC);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_nota ON public.avaliacoes USING btree (nota);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_created ON public.avaliacoes USING btree (created_at DESC);

-- PASSO 5: Adicionar comentários
COMMENT ON TABLE public.avaliacoes IS 'Avaliações simplificadas dos atendimentos odontológicos';
COMMENT ON COLUMN public.avaliacoes.id IS 'Identificador único da avaliação';
COMMENT ON COLUMN public.avaliacoes.created_at IS 'Data e hora do envio da avaliação';
COMMENT ON COLUMN public.avaliacoes.cpf IS 'CPF do paciente (sem formatação)';
COMMENT ON COLUMN public.avaliacoes.data_atendimento IS 'Data em que foi atendido';
COMMENT ON COLUMN public.avaliacoes.unidade IS 'Unidade onde foi atendido';
COMMENT ON COLUMN public.avaliacoes.cirurgiao_dentista IS 'Nome do cirurgião-dentista que atendeu';
COMMENT ON COLUMN public.avaliacoes.nota IS 'Nota do atendimento (0 a 10)';
COMMENT ON COLUMN public.avaliacoes.comentario IS 'Comentário opcional sobre a consulta';

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
    media_nota numeric,
    nota_maxima integer,
    nota_minima integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        nome_unidade::text AS unidade,
        COUNT(*)::bigint AS total_avaliacoes,
        ROUND(AVG(nota), 2) AS media_nota,
        MAX(nota) AS nota_maxima,
        MIN(nota) AS nota_minima
    FROM public.avaliacoes
    WHERE avaliacoes.unidade = nome_unidade;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.calcular_media_avaliacoes_unidade IS 'Calcula as médias de avaliação de uma unidade específica';

-- ============================================================================
-- FUNÇÃO PARA CALCULAR MÉDIA GERAL DE TODAS AS UNIDADES
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calcular_media_geral_avaliacoes()
RETURNS TABLE (
    unidade text,
    total_avaliacoes bigint,
    media_nota numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        avaliacoes.unidade::text,
        COUNT(*)::bigint AS total_avaliacoes,
        ROUND(AVG(nota), 2) AS media_nota
    FROM public.avaliacoes
    GROUP BY avaliacoes.unidade
    ORDER BY media_nota DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.calcular_media_geral_avaliacoes IS 'Calcula as médias de avaliação de todas as unidades';

-- ============================================================================
-- QUERIES DE EXEMPLO
-- ============================================================================

-- Ver todas as avaliações (para administradores)
-- SELECT * FROM public.avaliacoes ORDER BY created_at DESC;

-- Ver média de avaliações de uma unidade
-- SELECT * FROM public.calcular_media_avaliacoes_unidade('Marabá');

-- Ver média de todas as unidades
-- SELECT * FROM public.calcular_media_geral_avaliacoes();

-- Ver avaliações com nota baixa (0-5)
-- SELECT * FROM public.avaliacoes WHERE nota <= 5 ORDER BY created_at DESC;

-- Ver avaliações com nota alta (9-10)
-- SELECT * FROM public.avaliacoes WHERE nota >= 9 ORDER BY created_at DESC;

-- ============================================================================
-- MENSAGEM DE SUCESSO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Tabela avaliacoes criada com sucesso!';
    RAISE NOTICE '✅ Políticas RLS configuradas!';
    RAISE NOTICE '✅ Funções SQL criadas!';
    RAISE NOTICE '🎉 Sistema de avaliação V2.0 pronto para uso!';
END $$;

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================
