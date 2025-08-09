import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TurmaService {
  final supabase = Supabase.instance.client;

  // Buscar todas as turmas
  Future<List<Map<String, dynamic>>> buscarTurmas(String status) async {
    final response = await supabase.from('turmas').select().eq('status', status).order('codigo_turma', ascending: true);
    return response;
  }

  Future<List<String>> buscarModulosDaTurma(String turmaId) async {
    final response = await supabase
        .from('modulos_turmas')
        .select('modulo_id')
        .eq('turma_id', turmaId);

    return (response as List)
        .map((e) => e['modulo_id'].toString())
        .toList();
  }


  // Buscar todos os modulos
  Future<List<Map<String, dynamic>>> buscarModulos() async {
    final response = await supabase.from('modulos').select().eq('status', 'ativo').order('nome', ascending: true);
    return response;
  }

  Future<void> inativarTurma(String id) async {
    await supabase.from('turmas').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarTurma(String id) async {
    await supabase.from('turmas').update({'status': 'ativo'}).eq('id', id);
  }

  // Cadastrar uma nova turma
  Future<String?> cadastrarTurmas({
    required String codigo,
    required int ano,
    required String? dataInicio,
    required String? dataTermino,
    //required List<String> modulosSelecionados,
  }) async {
    try {
      // 1. Cria a turma
      final turmaInsert = await supabase.from('turmas').insert({
        'codigo_turma': codigo,
        'ano': ano,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'status': 'ativo',
      }).select().single();

      final turmaId = turmaInsert['id'];

      if (kDebugMode) {
        print(turmaId);
      }

/*      // 2. Insere os relacionamentos na tabela modulos_turmas
      for (var moduloId in modulosSelecionados) {
        await supabase.from('modulos_turmas').insert({
          'modulo_id': moduloId,
          'turma_id': turmaId,
        });
      }*/

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
    //required List<String> modulosSelecionados,
  }) async {
    try {
      // 1. Atualiza os dados básicos da turma
      await supabase.from('turmas').update({
        'codigo_turma': codigo,
        'ano': ano,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
      }).eq('id', id);

      // 2. Remove os relacionamentos antigos da turma
      await supabase.from('modulos_turmas').delete().eq('turma_id', id);

      // 3. Insere os novos relacionamentos
/*      for (var moduloId in modulosSelecionados) {
        await supabase.from('modulos_turmas').insert({
          'modulo_id': moduloId,
          'turma_id': id,
        });
      }*/

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
