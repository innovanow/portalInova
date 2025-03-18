import 'package:supabase_flutter/supabase_flutter.dart';

class TurmaService {
  final supabase = Supabase.instance.client;

  // Buscar todas as turmas
  Future<List<Map<String, dynamic>>> buscarTurmas() async {
    final response = await supabase.from('turmas').select();
    return response;
  }

  // Buscar todos os modulos
  Future<List<Map<String, dynamic>>> buscarModulos() async {
    final response = await supabase.from('modulos').select();
    return response;
  }

  // Cadastrar uma nova turma
  Future<String?> cadastrarTurmas({
    required String codigo,
    required int ano,
    required String? dataInicio,
    required String? dataTermino,
    required List<String> modulosSelecionados,
  }) async {
    try {

      await supabase.from('turmas').insert({
        'codigo_turma': codigo,
        'ano': ano,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'modulos_ids': modulosSelecionados,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Atualizar turmas
  Future<String?> atualizarTurmas({
    required String id,
    required String codigo,
    required int ano,
    required String? dataInicio,
    required String? dataTermino,
    required List<String> modulosSelecionados,
  }) async {
    try {
      await supabase.from('turmas').update({
        'codigo_turma': codigo,
        'ano': ano,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'modulos_ids': modulosSelecionados,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
