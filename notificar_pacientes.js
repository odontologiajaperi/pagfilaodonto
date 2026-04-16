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
    console.log('Iniciando busca de agendamentos para amanhã...');

    // 1. Calcular a data de amanhã
    const amanha = new Date();
    amanha.setDate(amanha.getDate() + 1);
    const dataAmanhaStr = amanha.toISOString().split('T')[0]; // Formato YYYY-MM-DD

    // 2. Buscar pacientes agendados para amanhã
    const { data: pacientes, error } = await supabase
        .from('pacientes')
        .select('*')
        .eq('status', 'agendado')
        .eq('data_agendamento', dataAmanhaStr);

    if (error) {
        console.error('Erro ao buscar pacientes:', error);
        return;
    }

    if (!pacientes || pacientes.length === 0) {
        console.log('Nenhum paciente agendado para amanhã.');
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
            const dataFormatada = dataAmanhaStr.split('-').reverse().join('/');
            
            // Montar a mensagem conforme o modelo do usuário
            const mensagem = `📅 *AGENDAMENTO DE CONSULTA ODONTOLÓGICA - PREFEITURA DE JAPERI*

Olá, *${paciente.nome_completo}*,

Sua consulta está agendada:

🗓 *Data:* ${dataFormatada}
⏰ *Horário:* ${paciente.hora_agendamento || 'A confirmar'}
📍 *Local:* ${paciente.unidade_preferencia}
📌 *Endereço:* (Endereço a definir)
🦷 *Especialidade:* (Especialidade a definir)

👉 *Responda a esta mensagem com:*

✔️ *SIM* – para confirmar presença
❌ *NÃO* – se não puder comparecer (entraremos em contato para remarcação)

⚠️ *ORIENTAÇÕES IMPORTANTES*

* Leve: RG, CPF, comprovante de residência e Cartão SUS atualizado;
* Tolerância máxima: 15 minutos de atraso;
* Falta sem justificativa gera a perda da vaga;
* Já está em tratamento? Mantenha assiduidade para que não haja a suspensão do plano de tratamento;
* Não poderá comparecer? Avise com antecedência! Sua vaga pode ajudar outro munícipe.

📩 Este não é um canal interativo! Dúvidas: odontologiajaperi@gmail.com

Atenciosamente,
Equipe de agendamento da Coordenação de Saúde Bucal de Japeri`;

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
