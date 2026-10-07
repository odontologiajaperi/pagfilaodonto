-- ========================================
-- TABELA GESTANTES
-- ========================================
-- Esta tabela armazena informações de pacientes gestantes
-- que recebem atendimento prioritário e diferenciado.
-- NÃO possui sistema de fila (sem posicao_fila, mes_referencia, status, data_agendamento)
-- ========================================

CREATE TABLE IF NOT EXISTS public.gestantes (
    -- Identificação e timestamps
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NULL DEFAULT now(),
    updated_at timestamp with time zone NULL DEFAULT now(),
    submitted_at timestamp with time zone NULL,
    
    -- Dados pessoais
    nome_completo text NOT NULL,
    sexo text NOT NULL,
    data_nascimento date NOT NULL,
    celular text NOT NULL,
    email text NULL,
    cpf text NOT NULL,
    cartao_sus text NOT NULL,
    nome_mae text NOT NULL,
    endereco text NOT NULL,
    
    -- Preferências de atendimento
    unidade_preferencia text NOT NULL,
    aceita_outra_unidade boolean NOT NULL,
    
    -- Queixas e avaliações
    queixa_principal text NOT NULL,
    avaliacao_agendamento text NULL,
    sugestoes text NULL,
    probabilidade_recomendacao integer NULL,
    
    -- Campos específicos de gestantes
    data_prevista_parto date NOT NULL,
    deseja_atendimento boolean NOT NULL,
    termo_gestante_aceito boolean NOT NULL DEFAULT true,
    
    -- Constraints
    CONSTRAINT gestantes_pkey PRIMARY KEY (id),
    CONSTRAINT gestantes_cpf_key UNIQUE (cpf)
) TABLESPACE pg_default;

-- Criar índice para consultas rápidas por CPF
CREATE INDEX IF NOT EXISTS idx_gestantes_cpf ON public.gestantes USING btree (cpf) TABLESPACE pg_default;

-- Criar índice para consultas por data prevista de parto
CREATE INDEX IF NOT EXISTS idx_gestantes_data_parto ON public.gestantes USING btree (data_prevista_parto) TABLESPACE pg_default;

-- Criar índice para consultas por deseja_atendimento
CREATE INDEX IF NOT EXISTS idx_gestantes_deseja_atendimento ON public.gestantes USING btree (deseja_atendimento) TABLESPACE pg_default;

-- Comentários na tabela
COMMENT ON TABLE public.gestantes IS 'Cadastro de pacientes gestantes com atendimento prioritário (sem sistema de fila)';
COMMENT ON COLUMN public.gestantes.id IS 'Identificador único da gestante';
COMMENT ON COLUMN public.gestantes.cpf IS 'CPF da gestante (único)';
COMMENT ON COLUMN public.gestantes.data_prevista_parto IS 'Data prevista do parto';
COMMENT ON COLUMN public.gestantes.deseja_atendimento IS 'Se a gestante deseja ser atendida durante a gestação';
COMMENT ON COLUMN public.gestantes.termo_gestante_aceito IS 'Se o termo de declaração de gestante foi aceito';

-- ========================================
-- OBSERVAÇÕES IMPORTANTES:
-- ========================================
-- 1. Esta tabela NÃO possui triggers de fila (atribuir_posicao_novo_paciente e reorganizar_fila_apos_remocao)
-- 2. Esta tabela NÃO possui os campos: posicao_fila, mes_referencia, status, data_agendamento
-- 3. Gestantes têm atendimento prioritário e não entram na fila regular
-- 4. O CPF é único tanto na tabela gestantes quanto na tabela pacientes (uma pessoa não pode estar em ambas)
-- ========================================
