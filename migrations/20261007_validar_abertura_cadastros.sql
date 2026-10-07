-- O site já consulta configuracoes.cadastros_abertos e
-- configuracoes.cadastros_pediatria_abertos. Ambos estão fechados hoje.
-- Garante no próprio banco que inserts diretos não contornem a página HTML.
-- A regra não altera nenhum cadastro, vaga, posição ou status preexistente.
BEGIN;

CREATE OR REPLACE FUNCTION public.validar_fila_aberta()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE v_aberto text;
BEGIN
  SELECT c.valor INTO v_aberto FROM public.configuracoes c
   WHERE c.chave='cadastros_abertos';
  IF v_aberto IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'Os cadastros estão temporariamente fechados. Apenas gestantes podem se cadastrar no momento.';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.validar_fila_pediatria_aberta()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE v_aberto text;
BEGIN
  SELECT c.valor INTO v_aberto FROM public.configuracoes c
   WHERE c.chave='cadastros_pediatria_abertos';
  IF v_aberto IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'As inscrições na odontopediatria estão fechadas no momento.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_pediatria_aberta ON public.pacientes_pediatria;
CREATE TRIGGER trg_validar_pediatria_aberta
BEFORE INSERT ON public.pacientes_pediatria
FOR EACH ROW EXECUTE FUNCTION public.validar_fila_pediatria_aberta();
COMMIT;
