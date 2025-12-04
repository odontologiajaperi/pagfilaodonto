// Sistema de Modal para Dúvidas sobre Documentos
function mostrarDuvidasDocumentos() {
    // Criar modal se não existir
    let modalOverlay = document.getElementById('modal-documentos-overlay');
    
    if (!modalOverlay) {
        // Criar estrutura do modal
        modalOverlay = document.createElement('div');
        modalOverlay.id = 'modal-documentos-overlay';
        modalOverlay.style.cssText = `
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.6);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            animation: fadeIn 0.3s ease;
        `;
        
        modalOverlay.innerHTML = `
            <div style="
                background: white;
                border-radius: 16px;
                padding: 30px;
                max-width: 600px;
                width: 90%;
                max-height: 90vh;
                overflow-y: auto;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                animation: slideUp 0.3s ease;
                border-top: 6px solid #17a2b8;
            ">
                <div style="text-align: center; font-size: 4em; margin-bottom: 20px;">📄</div>
                <h2 style="margin: 0 0 20px; color: #333; text-align: center; font-size: 1.5em;">Documentos Necessários</h2>
                
                <div style="text-align: left; color: #555; line-height: 1.8;">
                    <p style="margin-bottom: 15px;"><strong>Para ser atendido, você precisará apresentar os seguintes documentos:</strong></p>
                    
                    <ul style="margin: 15px 0; padding-left: 25px;">
                        <li style="margin-bottom: 10px;">📋 Documento de identificação com foto (RG, CNH ou Carteira de Trabalho)</li>
                        <li style="margin-bottom: 10px;">🏥 Cartão do SUS (Cartão Nacional de Saúde)</li>
                        <li style="margin-bottom: 10px;">🆔 CPF</li>
                        <li style="margin-bottom: 10px;">📮 Comprovante de residência atualizado (conta de luz, água ou telefone)</li>
                    </ul>
                    
                    <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px;">
                        <p style="margin: 0 0 10px; font-weight: 600; color: #856404;">⚠️ IMPORTANTE:</p>
                        <ul style="margin: 0; padding-left: 20px; color: #856404;">
                            <li>Todos os documentos devem estar <strong>originais</strong> ou com <strong>cópia autenticada</strong></li>
                            <li>Menores de 18 anos devem estar acompanhados de <strong>responsável legal</strong></li>
                            <li>O responsável deve apresentar documento de identificação</li>
                            <li><strong>A falta não justificada por documento legal</strong> para pacientes que iniciarão o plano de tratamento <strong>acarreta na perda da vaga</strong></li>
                            <li>Pacientes que já estão em tratamento devem se <strong>comprometer com a assiduidade</strong>, a fim de que seu plano de tratamento não seja suspenso</li>
                        </ul>
                    </div>
                    
                    <div style="background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 20px 0; border-radius: 4px;">
                        <p style="margin: 0 0 10px; font-weight: 600; color: #0c5460;">💡 OBSERVAÇÕES:</p>
                        <ul style="margin: 0; padding-left: 20px; color: #0c5460;">
                            <li>A falta de qualquer documento pode <strong>impedir o atendimento</strong></li>
                            <li>Chegue com <strong>15 minutos de antecedência</strong></li>
                            <li><strong>Mantenha seu número de contato sempre atualizado</strong> para eventuais remarcações ou imprevistos</li>
                            <li>Caso não consiga comparecer, <strong>remarque a consulta com o mínimo de 24 horas de antecedência</strong>. A sua vaga pode ajudar outro munícipio!</li>
                            <li>Em caso de dúvidas, entre em contato: <a href="mailto:odontologiajaperi@gmail.com" style="color: #0c5460; font-weight: 600;">odontologiajaperi@gmail.com</a></li>
                        </ul>
                    </div>
                </div>
                
                <button onclick="document.getElementById('modal-documentos-overlay').remove()" style="
                    width: 100%;
                    padding: 12px 30px;
                    border: none;
                    border-radius: 8px;
                    font-size: 1em;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.3s;
                    background: #17a2b8;
                    color: white;
                    margin-top: 20px;
                ">Fechar</button>
            </div>
        `;
        
        // Fechar ao clicar fora
        modalOverlay.addEventListener('click', function(e) {
            if (e.target === modalOverlay) {
                modalOverlay.remove();
            }
        });
        
        document.body.appendChild(modalOverlay);
    }
}

// Adicionar animações CSS
if (!document.getElementById('modal-animations-style')) {
    const style = document.createElement('style');
    style.id = 'modal-animations-style';
    style.textContent = `
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    `;
    document.head.appendChild(style);
}
