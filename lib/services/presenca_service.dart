import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresencaService {
  final _client = Supabase.instance.client;

  Future<String?> buscarTurmaIdPorModulo(String moduloId) async {
    final response = await _client
        .from('turmas')
        .select('id')
        .filter('modulos_ids', 'cs', '[$moduloId]'); // 'cs' = contains

    if (response.isNotEmpty) {
      return response.first['id'] as String?;
    }
    return null;
  }



  Future<List<Map<String, dynamic>>> listarModulosDoProfessor(String professorId) async {
    final modulos = await _client
        .from('modulos')
        .select('id, nome')
        .eq('professor_id', professorId)
        .order('data_inicio');

    List<Map<String, dynamic>> modulosComTurma = [];

    for (var modulo in modulos) {
      final moduloId = modulo['id'];

      final turma = await _client
          .from('turmas')
          .select('id, codigo_turma')
          .filter('modulos_ids', 'cs', '{$moduloId}') // ✅ formato correto
          .maybeSingle();

      if (turma != null) {
        modulosComTurma.add({
          'id': moduloId,
          'nome': modulo['nome'],
          'codigo_turma': turma['codigo_turma'],
          'turma_id': turma['id'],
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
    required String moduloId, // novo parâmetro
    required DateTime data,
  }) async {
    final payload = listaPresenca.map((item) {
      return {
        'jovem_id': item['id'],
        'presente': item['presente'],
        'data': data.toIso8601String().substring(0, 10),
        'turma_id': turmaId,
        'modulo_id': moduloId, // novo campo
      };
    }).toList();

    if (kDebugMode) {
      print('Enviando para Supabase: $payload');
    }

    await _client.from('presencas').insert(payload);
  }


}
