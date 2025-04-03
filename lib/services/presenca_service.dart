import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresencaService {
  final _client = Supabase.instance.client;

  Future<String?> buscarTurmaIdPorModulo(String moduloId) async {
    final response = await _client
        .from('modulos_turmas')
        .select('turma_id')
        .eq('modulo_id', moduloId)
        .maybeSingle();

    return response?['turma_id'] as String?;
  }

  Future<List<Map<String, dynamic>>> listarModulosDoProfessor(String professorId) async {
    // 1. Pega todos os módulos do professor
    final modulos = await _client
        .from('modulos')
        .select('id, nome')
        .eq('professor_id', professorId)
        .eq('status', 'ativo')
        .order('data_inicio');

    List<Map<String, dynamic>> modulosComTurma = [];

    for (var modulo in modulos) {
      final moduloId = modulo['id'];

      // 2. Pega as turmas ligadas a esse módulo via tabela intermediária
      final turmas = await _client
          .from('modulos_turmas')
          .select('turma_id, turmas(codigo_turma)')
          .eq('modulo_id', moduloId);

      for (var turma in turmas) {
        modulosComTurma.add({
          'id': moduloId,
          'nome': modulo['nome'],
          'codigo_turma': turma['turmas']?['codigo_turma'] ?? 'Sem código',
          'turma_id': turma['turma_id'],
        });
      }
    }

    return modulosComTurma;
  }

  Future<List<Map<String, dynamic>>> listarAlunosPorTurma(String turmaId) async {
    final response = await _client
        .from('jovens_aprendizes')
        .select('id, nome')
        .eq('turma_id', turmaId)
        .eq('status', 'ativo')
        .order('nome');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> salvarPresencas({
    required List<Map<String, dynamic>> listaPresenca,
    required String turmaId,
    required String moduloId,
    required DateTime data,
  }) async {
    final payload = listaPresenca.map((item) {
      return {
        'jovem_id': item['id'],
        'presente': item['presente'],
        'data': data.toIso8601String().substring(0, 10),
        'turma_id': turmaId,
        'modulo_id': moduloId,
      };
    }).toList();

    if (kDebugMode) {
      print('Enviando para Supabase: $payload');
    }

    await _client.from('presencas').insert(payload);
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoChamadas(String professorId) async {
    final response = await _client
        .from('historico_chamadas')
        .select('*')
        .order('data', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> removerChamada(DateTime data, String moduloId) async {
    await _client
        .from('presencas')
        .delete()
        .match({
      'data': data.toIso8601String().substring(0, 10),
      'modulo_id': moduloId,
    });
  }

  Future<List<Map<String, dynamic>>> buscarFrequenciaDoJovem(String jovemId) async {
    final response = await _client
        .from('presencas')
        .select('data, presente, modulo_id, modulos (nome, professores (nome))')
        .eq('jovem_id', jovemId)
        .order('data', ascending: false);

    return response.map((e) => {
      'data': e['data'],
      'presente': e['presente'],
      'modulo_nome': e['modulos']['nome'],
      'professor_nome': e['modulos']['professores']?['nome'] ?? 'Desconhecido',
    }).toList();
  }
}