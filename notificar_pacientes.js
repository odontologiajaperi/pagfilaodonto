const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');

// Configurações do Supabase (serão lidas das Secrets do GitHub)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Configurações da API do WhatsApp (serão lidas das Secrets do GitHub)
const whatsappApiUrl = process.env.WHATSAPP_API_URL;
const whatsappApiKey = process.env.WHATSAPP_API_KEY;

async function enviarNotificacoes() {
    console.log('Iniciando busca de agendamentos para daqui a 3 dias...');

    // 1. Calcular a data para daqui a 3 dias
    const dataAlvo = new Date();
    dataAlvo.setDate(dataAlvo.getDate() + 3);
    const dataAlvoStr = dataAlvo.toISOString().split('T')[0]; // Formato YYYY-MM-DD

    console.log(`Buscando agendamentos para a data: ${dataAlvoStr}`);

    // 2. Buscar pacientes agendados para daqui a 3 dias
    const { data: pacientes, error } = await supabase
        .from('pacientes')
        .select('*')
        .eq('status', 'agendado')
        .eq('data_agendamento', dataAlvoStr);

    if (error) {
        console.error('Erro ao buscar pacientes:', error);
        return;
    }

    if (!pacientes || pacientes.length === 0) {
        console.log(`Nenhum paciente agendado para ${dataAlvoStr}.`);
        return;
    }

    console.log(`Encontrados ${pacientes.length} pacientes. Iniciando envios...`);

    for (const paciente of pacientes) {
        try {
            // Limpar o número do celular (remover parênteses, espaços, traços)
            let numero = paciente.celular.replace(/\D/g, '');
            
            // Garantir que tenha o código do país (55 para Brasil)
            if (numero.length === 11 || numero.length === 10) {
                numero = '55' + numero;
            }

            // Formatar a data para exibição (DD/MM/YYYY)
            const dataFormatada = dataAlvoStr.split('-').reverse().join('/');
            
            // Montar a mensagem conforme o novo modelo do usuário
            const mensagem = `Prezada *${paciente.nome_completo}*,

Sua consulta odontológica está agendada para o dia *${dataFormatada}, às ${paciente.hora_agendamento || 'horário a confirmar'}*, na *${paciente.unidade_preferencia}*.

*Podemos confirmar?*
Reforçamos que o agendamento da consulta é feito através do WhatsApp e e-mail.

ORIENTAÇÕES IMPORTANTES
* Traga seus documentos em todas as consultas: identidade, CPF, comprovante de residência e Cartão Nacional de Saúde (SUS) atualizado;
* A tolerância é de 15 minutos. Não se atrase!
* A falta não justificada por documento legal para pacientes que iniciarão o plano de tratamento acarreta na perda da vaga;
* Pacientes que já estão em tratamento devem se comprometer com a assiduidade, a fim de que seu plano de tratamento não seja suspenso. Em caso de dúvidas, pergunte à técnica de saúde bucal;
* É fundamental manter seu número de contato sempre atualizado para eventuais remarcações ou imprevistos;
* Caso não consiga comparecer, remarque a consulta com antecedência. A sua vaga pode ajudar outro munícipe!

Em caso de dúvidas, fale conosco através do e-mail odontologiajaperi@gmail.com

*Não respondemos mensagens por este WhatsApp*

Atenciosamente,
Coordenação de Saúde Bucal de Japeri.`;

            // 3. Enviar via API do WhatsApp (Exemplo genérico para Evolution API / Z-API)
            // Nota: O formato do JSON pode variar levemente dependendo da API escolhida
            await axios.post(whatsappApiUrl, {
                number: numero,
                message: mensagem
            }, {
                headers: { 'apikey': whatsappApiKey }
            });

            console.log(`✅ Mensagem enviada para: ${paciente.nome_completo} (${numero})`);

        } catch (err) {
            console.error(`❌ Erro ao enviar para ${paciente.nome_completo}:`, err.message);
        }
    }
}

enviarNotificacoes();
