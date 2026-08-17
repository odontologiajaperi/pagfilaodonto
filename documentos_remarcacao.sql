-- ============================================================
-- DOCUMENTOS DE JUSTIFICATIVA PARA REMARCAÇÃO
-- ============================================================
-- Cria um bucket PRIVADO para fotos/PDFs e registra o documento
-- na solicitação correspondente. Execute no SQL Editor.
-- ============================================================

-- 1. Campos de referência do anexo na solicitação.
ALTER TABLE public.solicitacoes_remarcacao
    ADD COLUMN IF NOT EXISTS documento_path TEXT,
    ADD COLUMN IF NOT EXISTS documento_nome TEXT,
    ADD COLUMN IF NOT EXISTS documento_mime TEXT,
    ADD COLUMN IF NOT EXISTS documento_tamanho INTEGER,
    ADD COLUMN IF NOT EXISTS documento_enviado_em TIMESTAMPTZ;

-- 2. Bucket privado: sem URL pública, máximo de 5 MB e tipos permitidos.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'documentos-remarcacao',
    'documentos-remarcacao',
    false,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf'];

-- 3. Acesso somente para UPLOAD. Não há política de leitura pública.
-- O painel abrirá documentos com URL temporária gerada pelo serviço administrativo.
DROP POLICY IF EXISTS "Permitir envio controlado de documentos de remarcacao" ON storage.objects;
CREATE POLICY "Permitir envio controlado de documentos de remarcacao"
ON storage.objects
FOR INSERT
TO anon, authenticated
WITH CHECK (
    bucket_id = 'documentos-remarcacao'
    AND (storage.foldername(name))[1] = 'solicitacoes'
);

-- 4. Vincula o caminho enviado ao registro correto.
-- O caminho precisa obrigatoriamente começar com solicitacoes/<id-da-solicitacao>/.
CREATE OR REPLACE FUNCTION public.vincular_documento_remarcacao(
    p_solicitacao_id UUID,
    p_documento_path TEXT,
    p_documento_nome TEXT,
    p_documento_mime TEXT,
    p_documento_tamanho INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_documento_path IS NULL
       OR p_documento_path NOT LIKE 'solicitacoes/' || p_solicitacao_id::TEXT || '/%' THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Caminho de documento inválido.');
    END IF;

    IF p_documento_tamanho IS NULL OR p_documento_tamanho < 1 OR p_documento_tamanho > 5242880 THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'O documento deve ter no máximo 5 MB.');
    END IF;

    IF p_documento_mime NOT IN ('image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf') THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Formato de documento não permitido.');
    END IF;

    UPDATE public.solicitacoes_remarcacao
    SET documento_path = p_documento_path,
        documento_nome = LEFT(COALESCE(p_documento_nome, 'documento'), 160),
        documento_mime = p_documento_mime,
        documento_tamanho = p_documento_tamanho,
        documento_enviado_em = NOW(),
        updated_at = NOW()
    WHERE id = p_solicitacao_id;

    IF NOT FOUND THEN
        RETURN json_build_object('sucesso', false, 'mensagem', 'Solicitação não encontrada.');
    END IF;

    RETURN json_build_object('sucesso', true, 'mensagem', 'Documento anexado com sucesso.');
END;
$$;

GRANT EXECUTE ON FUNCTION public.vincular_documento_remarcacao(UUID, TEXT, TEXT, TEXT, INTEGER) TO anon, authenticated;

-- Verificação administrativa: execute depois para listar anexos.
-- SELECT id, cpf, documento_nome, documento_mime, documento_tamanho, documento_enviado_em
-- FROM public.solicitacoes_remarcacao
-- WHERE documento_path IS NOT NULL
-- ORDER BY documento_enviado_em DESC;
