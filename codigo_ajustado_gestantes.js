// ========================================
// CÓDIGO AJUSTADO PARA GESTANTES
// ========================================
// Este é o trecho de código que deve substituir a seção de gestantes
// no arquivo cadastro.html (linhas 861-931)
// ========================================

if (eGestante) {
    // ========== FLUXO PARA GESTANTES ==========
    
    // Validar se o termo foi aceito
    if (!termoGestanteAceito) {
        showModal(
            'Termo Não Aceito',
            'Você precisa aceitar o termo de declaração de gestante para continuar.',
            'error'
        );
        submitBtn.disabled = false;
        submitBtn.textContent = 'Enviar Cadastro';
        return;
    }
    
    // Converter deseja_atendimento para boolean
    data.deseja_atendimento = data.deseja_atendimento === 'true';
    data.termo_gestante_aceito = true;
    
    // Adicionar campos automáticos (AJUSTE AQUI)
    data.submitted_at = new Date().toISOString();
    
    // Remover campo e_gestante (não existe na tabela)
    delete data.e_gestante;
    
    // Validar CPF duplicado na tabela de gestantes
    const { data: cpfCheckGestante, error: cpfErrorGestante } = await supabaseClient
        .from('gestantes')
        .select('cpf, nome_completo')
        .eq('cpf', data.cpf)
        .limit(1);
    
    if (cpfErrorGestante) throw cpfErrorGestante;
    
    if (cpfCheckGestante && cpfCheckGestante.length > 0) {
        showModal(
            'CPF Já Cadastrado',
            `O CPF ${data.cpf.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')} já está cadastrado como gestante no sistema.`,
            'error'
        );
        submitBtn.disabled = false;
        submitBtn.textContent = 'Enviar Cadastro';
        return;
    }
    
    // Inserir na tabela de gestantes
    const { error: errorGestante } = await supabaseClient
        .from('gestantes')
        .insert([data]);
    
    if (errorGestante) throw errorGestante;
    
    // Mensagem personalizada baseada na escolha
    let mensagemGestante = '';
    
    if (data.deseja_atendimento) {
        // DESEJA ATENDIMENTO
        mensagemGestante = `Parabéns! Seu cadastro como gestante foi realizado com sucesso!\n\n🤰 ATENDIMENTO PRIORITÁRIO\n\nVocê será atendida com prioridade. Entraremos em contato em breve pelo telefone ${data.celular.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3')} para prosseguir com o agendamento.\n\n📌 Data prevista do parto: ${new Date(data.data_prevista_parto).toLocaleDateString('pt-BR')}\n\n📝 Importante: Mantenha seu telefone atualizado e atenda nossas ligações.`;
    } else {
        // NÃO DESEJA ATENDIMENTO
        mensagemGestante = `Cadastro realizado com sucesso!\n\n🤰 Seu cadastro como gestante foi registrado.\n\nVocê informou que não tem necessidade de atendimento no momento. Caso mude de ideia, entre em contato conosco.\n\n📌 Data prevista do parto: ${new Date(data.data_prevista_parto).toLocaleDateString('pt-BR')}\n\nObrigado pelo cadastro!`;
    }
    
    showModal(
        'Cadastro de Gestante Realizado!',
        mensagemGestante,
        'success'
    );
    
    e.target.reset();
    document.getElementById('checkbox_gestante').checked = false;
    document.getElementById('campos_gestante').style.display = 'none';
    termoGestanteAceito = false;
    
} else {
    // ========== FLUXO NORMAL (NÃO GESTANTE) ==========
    // ... (resto do código continua igual)
}

// ========================================
// RESUMO DO AJUSTE:
// ========================================
// Linha adicionada (após linha 878):
//     data.submitted_at = new Date().toISOString();
//
// Isso garante que o campo submitted_at seja preenchido
// automaticamente para gestantes, assim como é feito
// para pacientes regulares.
// ========================================
