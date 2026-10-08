-- Pediatria: uma fila global. Usa o MESMO advisory lock do INSERT.
-- Apenas substitui a função do trigger BEFORE UPDATE já existente;
-- não altera nenhuma linha da tabela durante a migração.
BEGIN;
CREATE OR REPLACE FUNCTION public.processar_agendamento_pediatria()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  v_antes boolean;
  v_depois boolean;
  v_ultima integer;
BEGIN
  NEW.status := lower(trim(coalesce(NEW.status, OLD.status, 'aguardando')));
  v_antes := lower(trim(coalesce(OLD.status,'')))='aguardando';
  v_depois := NEW.status='aguardando';
  IF v_antes IS DISTINCT FROM v_depois THEN
    PERFORM pg_catalog.pg_advisory_xact_lock(104202,0);
    IF v_antes THEN
      NEW.posicao_fila:=NULL;
      IF OLD.posicao_fila IS NOT NULL THEN
        UPDATE public.pacientes_pediatria
           SET posicao_fila=posicao_fila-1
         WHERE id<>OLD.id AND lower(trim(coalesce(status,'')))='aguardando'
           AND posicao_fila>OLD.posicao_fila;
      END IF;
    ELSE
      SELECT COALESCE(MAX(p.posicao_fila),0) INTO v_ultima
        FROM public.pacientes_pediatria p
       WHERE lower(trim(coalesce(p.status,'')))='aguardando' AND p.id<>OLD.id;
      NEW.posicao_fila:=v_ultima+1;
      NEW.submitted_at:=COALESCE(NEW.submitted_at,now());
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
COMMIT;
