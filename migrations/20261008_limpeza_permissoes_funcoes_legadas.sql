BEGIN;

-- Estas funções continuam preservadas para auditoria/rollback, mas não são API do site.
-- Os gatilhos internos continuam podendo executá-las quando necessário.
REVOKE EXECUTE ON FUNCTION public.atribuir_posicao_fila_integrada() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.atribuir_posicao_fila_unidade() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.atribuir_posicao_pediatria() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.atualizar_vagas_disponiveis() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.corrigir_fila_unidade(text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.executar_limpeza_automatica() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.gerenciar_fila_rodada() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.gerenciar_limite_inscricoes_posto() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.gerenciar_vagas_posto() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.iniciar_rodada_posto(text, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.limpar_acessos_antigos(integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.limpar_agendados_passados() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.limpar_agendamentos_passados() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.limpar_pacientes_agendados_apos_2_dias() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.limpar_pediatria_antigos() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.mover_paciente_na_fila(uuid, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.processar_agendamento_e_limpeza() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.processar_agendamento_e_reorganizar() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.processar_agendamento_pediatria() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reabrir_posto(text, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reorganizar_fila_ao_agendar() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reorganizar_fila_apos_agendamento() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reorganizar_fila_completa_por_unidade(text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reparar_fila_pediatria() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reparar_fila_unidade(text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_limpar_pacientes_agendados_apos_2_dias() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.validar_cpf_antes_de_salvar() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.validar_fila_aberta() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.validar_fila_pediatria_aberta() FROM PUBLIC, anon, authenticated;

-- Exceção deliberada: o cadastro público consulta a cota sem ACS.
-- A função gerenciar_fila_rodada continua sendo chamada apenas pelo trigger.
COMMIT;
