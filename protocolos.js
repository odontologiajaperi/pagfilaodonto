/*
 * Protocolos locais da fila odontológica de Japeri.
 *
 * O protocolo não é gravado no banco de dados. Ele é gerado no navegador
 * somente após o cadastro ser aceito e pode ser validado por cálculo de
 * dígitos verificadores. Em site estático, qualquer lógica enviada ao
 * navegador é pública; portanto, este mecanismo valida estrutura e integridade,
 * mas não substitui uma confirmação persistente em banco de dados.
 */
(function (global) {
    'use strict';

    const TIPOS = {
        '1': 'Fila Geral',
        '2': 'Gestante',
        '3': 'Odontopediatria'
    };

    function apenasDigitos(valor) {
        return String(valor || '').replace(/\D/g, '');
    }

    function doisDigitos(numero) {
        return String(numero).padStart(2, '0');
    }

    function quatroDigitos(numero) {
        return String(numero).padStart(4, '0');
    }

    function obterPartesData(data) {
        return {
            ano: String(data.getFullYear()).slice(-2),
            anoCompleto: data.getFullYear(),
            mes: doisDigitos(data.getMonth() + 1),
            dia: doisDigitos(data.getDate()),
            hora: doisDigitos(data.getHours()),
            minuto: doisDigitos(data.getMinutes()),
            segundo: doisDigitos(data.getSeconds())
        };
    }

    function gerarSerieAleatoria() {
        if (global.crypto && typeof global.crypto.getRandomValues === 'function') {
            const valores = new Uint32Array(1);
            global.crypto.getRandomValues(valores);
            return quatroDigitos(valores[0] % 10000);
        }
        return quatroDigitos(Math.floor(Math.random() * 10000));
    }

    function calcularHashCpf(cpf) {
        const digitos = apenasDigitos(cpf).padStart(11, '0').slice(-11);
        let total = 0;

        for (let i = 0; i < digitos.length; i++) {
            const n = Number(digitos[i]);
            total += n * ((i % 7) + 3) * (i + 1);
        }

        return quatroDigitos(total % 10000);
    }

    function calcularDigitosVerificadores(corpo) {
        const digitos = apenasDigitos(corpo);
        let total = 0;

        for (let i = 0; i < digitos.length; i++) {
            const n = Number(digitos[i]);
            total = (total + n * ((i % 9) + 2) + (i + 1)) % 97;
        }

        return doisDigitos((97 - total) % 97);
    }

    function formatarProtocolo(raw) {
        const digitos = apenasDigitos(raw);
        if (digitos.length !== 23) return String(raw || '').trim();
        return [
            digitos.slice(0, 6),
            digitos.slice(6, 7),
            digitos.slice(7, 13),
            digitos.slice(13, 17),
            digitos.slice(17, 21),
            digitos.slice(21, 23)
        ].join('-');
    }

    function gerarProtocolo(cpf, tipoCodigo, dataBase) {
        const tipo = String(tipoCodigo || '1');
        if (!TIPOS[tipo]) {
            throw new Error('Tipo de protocolo inválido.');
        }

        const agora = dataBase instanceof Date ? dataBase : new Date();
        const partes = obterPartesData(agora);
        const corpo = [
            partes.ano,
            partes.mes,
            partes.dia,
            tipo,
            partes.hora,
            partes.minuto,
            partes.segundo,
            gerarSerieAleatoria(),
            calcularHashCpf(cpf)
        ].join('');
        const dv = calcularDigitosVerificadores(corpo);

        return formatarProtocolo(corpo + dv);
    }

    function dataValida(anoCompleto, mes, dia) {
        const data = new Date(anoCompleto, mes - 1, dia);
        return data.getFullYear() === anoCompleto && data.getMonth() === mes - 1 && data.getDate() === dia;
    }

    function formatarDataDoProtocolo(ano, mes, dia) {
        return `${doisDigitos(dia)}/${doisDigitos(mes)}/${ano}`;
    }

    function formatarHoraDoProtocolo(hora, minuto, segundo) {
        return `${doisDigitos(hora)}:${doisDigitos(minuto)}:${doisDigitos(segundo)}`;
    }

    function validarProtocolo(protocolo, cpfOpcional) {
        const digitos = apenasDigitos(protocolo);

        if (digitos.length !== 23) {
            return {
                valido: false,
                motivo: 'O protocolo deve conter 23 dígitos numéricos no total.'
            };
        }

        const corpo = digitos.slice(0, 21);
        const dvInformado = digitos.slice(21, 23);
        const dvCalculado = calcularDigitosVerificadores(corpo);

        if (dvInformado !== dvCalculado) {
            return {
                valido: false,
                motivo: 'Os dígitos verificadores não conferem. Verifique se algum número foi digitado errado.'
            };
        }

        const yy = Number(digitos.slice(0, 2));
        const mes = Number(digitos.slice(2, 4));
        const dia = Number(digitos.slice(4, 6));
        const tipo = digitos.slice(6, 7);
        const hora = Number(digitos.slice(7, 9));
        const minuto = Number(digitos.slice(9, 11));
        const segundo = Number(digitos.slice(11, 13));
        const serie = digitos.slice(13, 17);
        const hashCpf = digitos.slice(17, 21);
        const anoCompleto = 2000 + yy;

        if (!TIPOS[tipo]) {
            return { valido: false, motivo: 'O tipo de cadastro informado no protocolo não existe.' };
        }

        if (!dataValida(anoCompleto, mes, dia)) {
            return { valido: false, motivo: 'A data codificada no protocolo é inválida.' };
        }

        if (hora > 23 || minuto > 59 || segundo > 59) {
            return { valido: false, motivo: 'O horário codificado no protocolo é inválido.' };
        }

        const cpfDigitado = apenasDigitos(cpfOpcional);
        let cpfConfere = null;
        if (cpfDigitado) {
            cpfConfere = calcularHashCpf(cpfDigitado) === hashCpf;
            if (!cpfConfere) {
                return {
                    valido: false,
                    motivo: 'O protocolo tem estrutura válida, mas não confere com o CPF informado.'
                };
            }
        }

        return {
            valido: true,
            motivo: cpfDigitado ? 'Protocolo válido e compatível com o CPF informado.' : 'Protocolo válido pela estrutura e pelos dígitos verificadores.',
            protocoloFormatado: formatarProtocolo(digitos),
            tipoCodigo: tipo,
            tipoNome: TIPOS[tipo],
            data: formatarDataDoProtocolo(anoCompleto, mes, dia),
            hora: formatarHoraDoProtocolo(hora, minuto, segundo),
            serie,
            cpfConfere
        };
    }

    global.ProtocoloFila = {
        TIPOS,
        apenasDigitos,
        calcularHashCpf,
        calcularDigitosVerificadores,
        formatarProtocolo,
        gerar: gerarProtocolo,
        validar: validarProtocolo
    };
})(window);
