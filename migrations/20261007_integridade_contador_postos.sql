-- Proteção do contador usado pelo cadastro público.
-- Pré-condição: todos os postos já possuem vagas_disponiveis >= 0.
-- Não atualiza, recalcula nem redefine nenhuma vaga.
BEGIN;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.postos WHERE vagas_disponiveis IS NULL OR vagas_disponiveis < 0) THEN
        RAISE EXCEPTION 'VAGAS_INVALIDAS: corrigir manualmente antes da migration';
    END IF;
END;
$$;
ALTER TABLE public.postos ALTER COLUMN vagas_disponiveis SET NOT NULL;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
         WHERE conrelid = 'public.postos'::regclass
           AND conname = 'postos_vagas_disponiveis_nao_negativas'
    ) THEN
        ALTER TABLE public.postos
          ADD CONSTRAINT postos_vagas_disponiveis_nao_negativas
          CHECK (vagas_disponiveis >= 0);
    END IF;
END;
$$;
COMMIT;
