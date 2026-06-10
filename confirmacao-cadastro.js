/* Tela de confirmação pós-cadastro com protocolo local. */
(function (global) {
    'use strict';

    function escaparHtml(valor) {
        return String(valor ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function apenasDigitos(valor) {
        return String(valor || '').replace(/\D/g, '');
    }

    function formatarCpf(cpf) {
        const digitos = apenasDigitos(cpf);
        if (digitos.length !== 11) return escaparHtml(cpf || 'Não informado');
        return `${digitos.slice(0, 3)}.${digitos.slice(3, 6)}.${digitos.slice(6, 9)}-${digitos.slice(9)}`;
    }

    function formatarTelefone(telefone) {
        const digitos = apenasDigitos(telefone);
        if (digitos.length === 11) return `(${digitos.slice(0, 2)}) ${digitos.slice(2, 7)}-${digitos.slice(7)}`;
        if (digitos.length === 10) return `(${digitos.slice(0, 2)}) ${digitos.slice(2, 6)}-${digitos.slice(6)}`;
        return escaparHtml(telefone || 'Não informado');
    }

    function formatarDataBr(dataIso) {
        if (!dataIso) return 'Não informado';
        const partes = String(dataIso).slice(0, 10).split('-');
        if (partes.length === 3) return `${partes[2]}/${partes[1]}/${partes[0]}`;
        return escaparHtml(dataIso);
    }

    function dataHoraAtualBr() {
        return new Date().toLocaleString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    }

    function inserirEstilos() {
        if (document.getElementById('confirmacao-cadastro-styles')) return;

        const style = document.createElement('style');
        style.id = 'confirmacao-cadastro-styles';
        style.textContent = `
            .confirmacao-overlay {
                position: fixed;
                inset: 0;
                display: flex;
                align-items: center;
                justify-content: center;
                background: rgba(15, 23, 42, 0.74);
                z-index: 99999;
                padding: 18px;
                overflow-y: auto;
            }

            .confirmacao-card {
                width: min(820px, 100%);
                background: #ffffff;
                border-radius: 28px;
                box-shadow: 0 24px 80px rgba(15, 23, 42, 0.35);
                overflow: hidden;
                border: 1px solid rgba(148, 163, 184, 0.3);
                animation: confirmacaoSlideUp 0.28s ease;
                color: #1f2937;
                font-family: inherit;
            }

            .confirmacao-topo {
                background: linear-gradient(135deg, #15803d 0%, #16a34a 50%, #22c55e 100%);
                color: #ffffff;
                padding: 28px 30px;
                text-align: center;
            }

            .confirmacao-topo h2 {
                margin: 0 0 10px;
                font-size: clamp(1.65rem, 4vw, 2.35rem);
                line-height: 1.15;
                font-weight: 900;
            }

            .confirmacao-topo p {
                margin: 0;
                font-size: 1rem;
                line-height: 1.55;
                opacity: 0.96;
            }

            .confirmacao-corpo {
                padding: 28px 30px 30px;
            }

            .confirmacao-alerta-print {
                background: #fff7ed;
                border: 2px solid #fed7aa;
                color: #9a3412;
                padding: 16px 18px;
                border-radius: 18px;
                font-weight: 800;
                line-height: 1.55;
                margin-bottom: 18px;
                text-align: center;
            }

            .confirmacao-protocolo-box {
                background: #0f172a;
                color: #ffffff;
                padding: 22px;
                border-radius: 22px;
                text-align: center;
                margin-bottom: 20px;
                border: 3px solid #22c55e;
            }

            .confirmacao-protocolo-label {
                display: block;
                font-size: 0.86rem;
                letter-spacing: 0.12em;
                text-transform: uppercase;
                color: #bbf7d0;
                font-weight: 900;
                margin-bottom: 10px;
            }

            .confirmacao-protocolo-numero {
                display: block;
                font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', monospace;
                font-size: clamp(1.18rem, 4.8vw, 2.25rem);
                font-weight: 900;
                letter-spacing: 0.04em;
                word-break: break-word;
            }

            .confirmacao-grid {
                display: grid;
                grid-template-columns: repeat(2, minmax(0, 1fr));
                gap: 12px;
                margin: 18px 0;
            }

            .confirmacao-campo {
                background: #f8fafc;
                border: 1px solid #e2e8f0;
                border-radius: 16px;
                padding: 14px 16px;
            }

            .confirmacao-campo.destaque {
                grid-column: 1 / -1;
                background: #ecfdf5;
                border-color: #86efac;
            }

            .confirmacao-campo span {
                display: block;
                color: #64748b;
                font-size: 0.78rem;
                font-weight: 900;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                margin-bottom: 6px;
            }

            .confirmacao-campo strong {
                display: block;
                color: #111827;
                font-size: 1.02rem;
                line-height: 1.35;
                word-break: break-word;
            }

            .confirmacao-mensagem {
                background: #eff6ff;
                border-left: 5px solid #2563eb;
                color: #1e3a8a;
                padding: 16px 18px;
                border-radius: 14px;
                line-height: 1.6;
                margin-top: 18px;
            }

            .confirmacao-acoes {
                display: flex;
                flex-wrap: wrap;
                gap: 12px;
                margin-top: 22px;
            }

            .confirmacao-acoes button,
            .confirmacao-acoes a {
                flex: 1 1 180px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                border: 0;
                border-radius: 16px;
                padding: 14px 18px;
                font-weight: 900;
                text-decoration: none;
                cursor: pointer;
                transition: transform 0.2s ease, box-shadow 0.2s ease;
                font-size: 0.98rem;
                min-height: 52px;
            }

            .confirmacao-acoes button:hover,
            .confirmacao-acoes a:hover {
                transform: translateY(-1px);
                box-shadow: 0 10px 24px rgba(15, 23, 42, 0.16);
            }

            .confirmacao-btn-copiar { background: #2563eb; color: #ffffff; }
            .confirmacao-btn-imprimir { background: #0f172a; color: #ffffff; }
            .confirmacao-btn-extra { background: #db2777; color: #ffffff; }
            .confirmacao-btn-voltar { background: #16a34a; color: #ffffff; }

            @keyframes confirmacaoSlideUp {
                from { opacity: 0; transform: translateY(24px) scale(0.98); }
                to { opacity: 1; transform: translateY(0) scale(1); }
            }

            @media (max-width: 640px) {
                .confirmacao-overlay {
                    align-items: flex-start;
                    padding: 10px;
                }

                .confirmacao-card {
                    border-radius: 22px;
                }

                .confirmacao-topo,
                .confirmacao-corpo {
                    padding-left: 18px;
                    padding-right: 18px;
                }

                .confirmacao-grid {
                    grid-template-columns: 1fr;
                }

                .confirmacao-acoes {
                    flex-direction: column;
                }

                .confirmacao-acoes button,
                .confirmacao-acoes a {
                    flex-basis: auto;
                    width: 100%;
                }
            }

            @media print {
                body * { visibility: hidden !important; }
                .confirmacao-overlay, .confirmacao-overlay * { visibility: visible !important; }
                .confirmacao-overlay {
                    position: static !important;
                    background: #ffffff !important;
                    padding: 0 !important;
                    overflow: visible !important;
                }
                .confirmacao-card {
                    box-shadow: none !important;
                    border: 1px solid #111827 !important;
                    width: 100% !important;
                }
                .confirmacao-acoes { display: none !important; }
            }
        `;
        document.head.appendChild(style);
    }

    function montarCampo(rotulo, valor, destaque) {
        return `
            <div class="confirmacao-campo${destaque ? ' destaque' : ''}">
                <span>${escaparHtml(rotulo)}</span>
                <strong>${escaparHtml(valor || 'Não informado')}</strong>
            </div>
        `;
    }

    async function copiarTexto(texto, botao) {
        try {
            await navigator.clipboard.writeText(texto);
            if (botao) {
                const original = botao.textContent;
                botao.textContent = 'Protocolo copiado';
                setTimeout(() => { botao.textContent = original; }, 1800);
            }
        } catch (erro) {
            alert('Não foi possível copiar automaticamente. Anote ou tire print do protocolo exibido na tela.');
        }
    }

    function mostrarConfirmacao(opcoes) {
        inserirEstilos();

        const protocolo = opcoes.protocolo || '';
        const dataCadastro = opcoes.dataCadastro || dataHoraAtualBr();
        const campos = [
            { rotulo: 'Nome', valor: opcoes.nome, destaque: true },
            { rotulo: 'CPF', valor: formatarCpf(opcoes.cpf) },
            { rotulo: 'Data e hora do cadastro', valor: dataCadastro },
            { rotulo: 'Tipo de cadastro', valor: opcoes.tipo || 'Fila Geral' }
        ].concat(opcoes.camposExtras || []);

        let overlay = document.getElementById('confirmacao-cadastro-overlay');
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.id = 'confirmacao-cadastro-overlay';
            overlay.className = 'confirmacao-overlay';
            document.body.appendChild(overlay);
        }

        const extras = (opcoes.botoesExtras || []).map(botao => `
            <a class="confirmacao-btn-extra" href="${escaparHtml(botao.url || '#')}" target="${botao.novaAba === false ? '_self' : '_blank'}" rel="noopener">
                ${escaparHtml(botao.texto || 'Abrir')}
            </a>
        `).join('');

        overlay.innerHTML = `
            <section class="confirmacao-card" role="dialog" aria-modal="true" aria-labelledby="confirmacao-titulo">
                <div class="confirmacao-topo">
                    <h2 id="confirmacao-titulo">${escaparHtml(opcoes.titulo || 'Cadastro confirmado')}</h2>
                    <p>${escaparHtml(opcoes.subtitulo || 'Seu cadastro foi recebido pelo sistema.')}</p>
                </div>
                <div class="confirmacao-corpo">
                    <div class="confirmacao-alerta-print">
                        Atenção: tire uma foto ou print desta tela agora e anote o número de protocolo. Ele será sua confirmação para conferência posterior.
                    </div>
                    <div class="confirmacao-protocolo-box">
                        <span class="confirmacao-protocolo-label">Número de protocolo</span>
                        <span class="confirmacao-protocolo-numero">${escaparHtml(protocolo)}</span>
                    </div>
                    <div class="confirmacao-grid">
                        ${campos.map(campo => montarCampo(campo.rotulo, campo.valor, campo.destaque)).join('')}
                    </div>
                    <div class="confirmacao-mensagem">
                        ${escaparHtml(opcoes.mensagem || 'Guarde esta confirmação. A equipe entrará em contato pelos dados informados no cadastro.')}
                    </div>
                    <div class="confirmacao-acoes">
                        <button type="button" class="confirmacao-btn-copiar" id="btnCopiarProtocolo">Copiar protocolo</button>
                        <button type="button" class="confirmacao-btn-imprimir" onclick="window.print()">Imprimir ou salvar</button>
                        ${extras}
                        <button type="button" class="confirmacao-btn-voltar" onclick="window.location.href='index.html'">Concluir e voltar ao início</button>
                    </div>
                </div>
            </section>
        `;

        const btnCopiar = document.getElementById('btnCopiarProtocolo');
        if (btnCopiar) {
            btnCopiar.addEventListener('click', () => copiarTexto(protocolo, btnCopiar));
        }

        document.body.style.overflow = 'hidden';
    }

    global.ConfirmacaoCadastro = {
        mostrar: mostrarConfirmacao,
        formatarCpf,
        formatarTelefone,
        formatarDataBr,
        dataHoraAtualBr
    };
})(window);
