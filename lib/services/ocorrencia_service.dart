import 'package:supabase_flutter/supabase_flutter.dart';

class OcorrenciaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarOcorrenciasPorJovem(String jovemId) async {
    final response = await _client
        .from('ocorrencias_jovem')
        .select()
        .eq('jovem_id', jovemId)
        .order('data_ocorrencia', ascending: false);

    return response.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<String?> cadastrarOcorrencia({
    required String jovemId,
    required String tipo,
    required String descricao,
    String? idUsuario,
  }) async {
    try {
      final data = {
        'jovem_id': jovemId,
        'tipo': tipo,
        'descricao': descricao,
        'data_ocorrencia': DateTime.now().toIso8601String(),
        'resolvido': false,
        'user_id': idUsuario,
      };
      await _client.from('ocorrencias_jovem').insert(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> marcarComoResolvido(String id) async {
    await _client.from('ocorrencias_jovem').update({
      'resolvido': true,
      'data_resolucao': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> desmarcarComoResolvido(String id) async {
    await _client.from('ocorrencias_jovem').update({
      'resolvido': false,
      'data_resolucao': null,
    }).eq('id', id);
  }

  Future<void> adicionarObservacao(String id, String texto) async {
    await _client.from('ocorrencias_jovem').update({
      'observacoes': texto == '' ? null : texto,
    }).eq('id', id);
  }

  Future<void> excluirOcorrencia(String id) async {
    await _client.from('ocorrencias_jovem').delete().eq('id', id);
  }

}