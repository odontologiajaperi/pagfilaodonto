-- ============================================================
-- CORREÇÃO: FILA DE ODONTOPEDIATRIA + LIMPEZA DA FILA NORMAL
-- Projeto: Saúde Bucal de Japeri
-- Objetivo:
-- 1) Fazer a coluna posicao_fila da tabela pacientes_pediatria funcionar automaticamente.
-- 2) Corrigir a limpeza automática da tabela pacientes para apagar registros
--    2 dias após a data/hora da consulta marcada.
--
-- IMPORTANTE:
-- Execute este script no Supabase em SQL Editor > New query > Run.
-- ============================================================

-- ============================================================
-- PARTE 1: GARANTIR COLUNAS NECESSÁRIAS NA ODONTOPEDIATRIA
-- ============================================================

ALTER TABLE public.pacientes_pediatria
    ADD COLUMN IF NOT EXISTS posicao_fila INTEGER,
    ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'aguardando',
    ADD COLUMN IF NOT EXISTS data_agendamento DATE,
    ADD COLUMN IF NOT EXISTS hora_agendamento TIME,
    ADD COLUMN IF NOT EXISTS observacoes TEXT;

-- Normaliza os status antigos/novos para evitar erro por maiúscula/minúscula.
-- Exemplo: 'Aguardando' vira 'aguardando'.
UPDATE public.pacientes_pediatria
SET status = LOWER(TRIM(status))
WHERE status IS NOT NULL
  AND status <> LOWER(TRIM(status));

UPDATE public.pacientes_pediatria
SET status = 'aguardando'
WHERE status IS NULL OR TRIM(status) = '';

-- ============================================================
-- PARTE 2: FUNÇÃO PARA ATRIBUIR POSIÇÃO AUTOMÁTICA NA PEDIATRIA
-- ============================================================

CREATE OR REPLACE FUNCTION public.atribuir_posicao_pediatria()
RETURNS TRIGGER AS $$
DECLARE
    v_ultima_posicao INTEGER;
BEGIN
    NEW.status := LOWER(TRIM(COALESCE(NEW.status, 'aguardando')));

    IF NEW.submitted_at IS NULL THEN
        NEW.submitted_at := NOW();
    END IF;

    IF (NEW.status = 'aguardando' AND (NEW.posicao_fila IS NULL OR NEW.posicao_fila = 0)) THEN
        SELECT COALESCE(MAX(posicao_fila), 0)
          INTO v_ultima_posicao
          FROM public.pacientes_pediatria
         WHERE LOWER(TRIM(COALESCE(status, ''))) = 'aguardando';

        NEW.posicao_fila := v_ultima_posicao + 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_atribuir_posicao_pediatria ON public.pacientes_pediatria;
CREATE TRIGGER trg_atribuir_posicao_pediatria
    BEFORE INSERT ON public.pacientes_pediatria
    FOR EACH ROW
    EXECUTE FUNCTION public.atribuir_posicao_pediatria();

-- ============================================================
-- PARTE 3: REORGANIZAR FILA DA PEDIATRIA AO AGENDAR/ATENDER
-- ============================================================

CREATE OR REPLACE FUNCTION public.processar_agendamento_pediatria()
RETURNS TRIGGER AS $$
BEGIN
    NEW.status := LOWER(TRIM(COALESCE(NEW.status, OLD.status, 'aguardando')));

    IF (
        NEW.status IN ('agendado', 'atendido')
        AND LOWER(TRIM(COALESCE(OLD.status, ''))) = 'aguardando'
    ) THEN
        NEW.posicao_fila := NULL;

        IF OLD.posicao_fila IS NOT NULL THEN
            UPDATE public.pacientes_pediatria
               SET posicao_fila = posicao_fila - 1
             WHERE LOWER(TRIM(COALESCE(status, ''))) = 'aguardando'
               AND posicao_fila > OLD.posicao_fila;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_processar_agendamento_pediatria ON public.pacientes_pediatria;
CREATE TRIGGER trg_processar_agendamento_pediatria
    BEFORE UPDATE ON public.pacientes_pediatria
    FOR EACH ROW
    EXECUTE FUNCTION public.processar_agendamento_pediatria();

-- ============================================================
-- PARTE 4: REPARAR POSIÇÕES JÁ EXISTENTES NA PEDIATRIA
-- ============================================================

CREATE OR REPLACE FUNCTION public.reparar_fila_pediatria()
RETURNS void AS $$
DECLARE
    r RECORD;
    v_posicao INTEGER := 1;
BEGIN
    FOR r IN
        SELECT id
          FROM public.pacientes_pediatria
         WHERE LOWER(TRIM(COALESCE(status, ''))) = 'aguardando'
         ORDER BY COALESCE(submitted_at, NOW()) ASC, nome_completo ASC
    LOOP
        UPDATE public.pacientes_pediatria
           SET posicao_fila = v_posicao,
               status = 'aguardando'
         WHERE id = r.id;

        v_posicao := v_posicao + 1;
    END LOOP;

    UPDATE public.pacientes_pediatria
       SET posicao_fila = NULL
     WHERE LOWER(TRIM(COALESCE(status, ''))) IN ('agendado', 'atendido');
END;
$$ LANGUAGE plpgsql;

SELECT public.reparar_fila_pediatria();

-- ============================================================
-- PARTE 5: LIMPEZA DA TABELA NORMAL 2 DIAS APÓS CONSULTA
-- ============================================================

CREATE OR REPLACE FUNCTION public.limpar_pacientes_agendados_apos_2_dias()
RETURNS void AS $$
BEGIN
    DELETE FROM public.pacientes
     WHERE LOWER(TRIM(COALESCE(status, ''))) IN ('agendado', 'atendido')
       AND data_agendamento IS NOT NULL
       AND (
            data_agendamento::timestamp
            + COALESCE(hora_agendamento, TIME '00:00')
            + INTERVAL '2 days'
       ) < NOW();
END;
$$ LANGUAGE plpgsql;

-- Mantém também um gatilho para limpar quando houver movimento no sistema.
CREATE OR REPLACE FUNCTION public.trg_limpar_pacientes_agendados_apos_2_dias()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.limpar_pacientes_agendados_apos_2_dias();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_limpeza_geral ON public.pacientes;
CREATE TRIGGER trg_limpeza_geral
    AFTER INSERT OR UPDATE ON public.pacientes
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trg_limpar_pacientes_agendados_apos_2_dias();

-- Executa uma limpeza imediata no momento em que o script for rodado.
SELECT public.limpar_pacientes_agendados_apos_2_dias();

-- ============================================================
-- PARTE 6: LIMPEZA AUTOMÁTICA DIÁRIA VIA PG_CRON
-- ============================================================
-- Sem agendamento diário, trigger só roda quando alguém insere/atualiza algum registro.
-- O pg_cron garante a limpeza mesmo se ninguém mexer no sistema naquele dia.
-- Se o seu projeto Supabase ainda não tiver pg_cron habilitado, habilite em:
-- Database > Extensions > pg_cron, e depois rode novamente esta parte.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM pg_namespace
         WHERE nspname = 'cron'
    ) THEN
        PERFORM cron.unschedule(jobid)
          FROM cron.job
         WHERE jobname = 'limpar-pacientes-agendados-apos-2-dias';

        PERFORM cron.schedule(
            'limpar-pacientes-agendados-apos-2-dias',
            '0 3 * * *',
            'SELECT public.limpar_pacientes_agendados_apos_2_dias();'
        );
    END IF;
END $$;

-- ============================================================
-- PARTE 7: CONSULTAS DE CONFERÊNCIA
-- ============================================================

-- Conferir pediatria aguardando com posição:
SELECT id, nome_completo, status, posicao_fila, submitted_at
  FROM public.pacientes_pediatria
 WHERE LOWER(TRIM(COALESCE(status, ''))) = 'aguardando'
 ORDER BY posicao_fila ASC;

-- Conferir pacientes normais que ainda seriam candidatos à limpeza:
SELECT id, nome_completo, status, data_agendamento, hora_agendamento
  FROM public.pacientes
 WHERE LOWER(TRIM(COALESCE(status, ''))) IN ('agendado', 'atendido')
   AND data_agendamento IS NOT NULL
   AND (
        data_agendamento::timestamp
        + COALESCE(hora_agendamento, TIME '00:00')
        + INTERVAL '2 days'
   ) < NOW();
