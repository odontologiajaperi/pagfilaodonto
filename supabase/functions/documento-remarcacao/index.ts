import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://odontologiajaperi.github.io',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ sucesso: false, mensagem: 'Método não permitido.' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const { senha, solicitacao_id } = await req.json();

    if (typeof senha !== 'string' || typeof solicitacao_id !== 'string') {
      return new Response(JSON.stringify({ sucesso: false, mensagem: 'Dados inválidos.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: senhaValida, error: erroSenha } = await admin.rpc('verificar_senha_admin', {
      p_senha: senha,
    });

    if (erroSenha || senhaValida !== true) {
      return new Response(JSON.stringify({ sucesso: false, mensagem: 'Acesso não autorizado.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: solicitacao, error: erroSolicitacao } = await admin
      .from('solicitacoes_remarcacao')
      .select('documento_path, documento_nome')
      .eq('id', solicitacao_id)
      .maybeSingle();

    if (erroSolicitacao || !solicitacao?.documento_path) {
      return new Response(JSON.stringify({ sucesso: false, mensagem: 'Documento não encontrado.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: urlAssinada, error: erroUrl } = await admin.storage
      .from('documentos-remarcacao')
      .createSignedUrl(solicitacao.documento_path, 300, {
        download: solicitacao.documento_nome || 'documento-justificativa',
      });

    if (erroUrl || !urlAssinada?.signedUrl) {
      return new Response(JSON.stringify({ sucesso: false, mensagem: 'Não foi possível abrir o documento.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ sucesso: true, url: urlAssinada.signedUrl }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (erro) {
    console.error('Erro ao gerar URL do documento:', erro);
    return new Response(JSON.stringify({ sucesso: false, mensagem: 'Erro interno ao abrir documento.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
