-- Fila: evita duas novas inscrições simultâneas receberem a mesma posição.
-- Migração ADITIVA: substitui apenas o corpo de duas funções já usadas por triggers.
-- Não move, apaga nem atualiza qualquer paciente existente; não redefine postos/vagas.
-- Antes de aplicar: conferir os triggers trg_atribuir_posicao e
-- trg_atribuir_posicao_pediatria e testar em banco separado.
BEGIN;

CREATE OR REPLACE FUNCTION public.atribuir_posicao_fila_unidade()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
    v_ultima_posicao integer;
BEGIN
    IF NEW.status = 'aguardando' THEN
        -- Lock transacional por unidade, antes do SELECT MAX. O hash pode
        -- colidir e serializar unidades diferentes, mas nunca gera duplicação.
        PERFORM pg_catalog.pg_advisory_xact_lock(
            104201, pg_catalog.hashtext(NEW.unidade_preferencia)
        );
        SELECT COALESCE(MAX(p.posicao_fila), 0) INTO v_ultima_posicao
          FROM public.pacientes p
         WHERE p.unidade_preferencia = NEW.unidade_preferencia
           AND p.status = 'aguardando';
        NEW.posicao_fila := v_ultima_posicao + 1;
        IF NEW.submitted_at IS NULL THEN
            NEW.submitted_at := now();
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.atribuir_posicao_pediatria()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
    v_ultima_posicao integer;
BEGIN
    NEW.status := lower(trim(coalesce(NEW.status, 'aguardando')));
    IF NEW.submitted_at IS NULL THEN
        NEW.submitted_at := now();
    END IF;
    IF NEW.status = 'aguardando' THEN
        -- Pediatria possui uma única fila global, independente da normal.
        PERFORM pg_catalog.pg_advisory_xact_lock(104202, 0);
        SELECT COALESCE(MAX(p.posicao_fila), 0) INTO v_ultima_posicao
          FROM public.pacientes_pediatria p
         WHERE lower(trim(coalesce(p.status, ''))) = 'aguardando';
        NEW.posicao_fila := v_ultima_posicao + 1;
    END IF;
    RETURN NEW;
END;
$$;

COMMIT;

-- A posição de qualquer novo registro aguardando é recalculada no banco;
-- transferências e reordenações administrativas ainda exigem revisão própria.
-- Não criar índice UNIQUE parcial antes de revisar a atualização em bloco dos
-- triggers de agendamento, que hoje deslocam posições linha a linha.
