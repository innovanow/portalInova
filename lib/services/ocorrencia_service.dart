import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/drawer.dart';

class OcorrenciaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarOcorrenciasPorJovem(String jovemId, String tipoUsuario) async {
    String tipoConsulta;

    if (tipoUsuario == 'administrador') {
      tipoConsulta = 'instituto';
    } else if (tipoUsuario == 'professor') {
      tipoConsulta = 'escola';
    } else {
      tipoConsulta = tipoUsuario;
    }

    final response = await _client
        .from('ocorrencias_jovem')
        .select()
        .eq('jovem_id', jovemId)
        .eq('tipo', tipoConsulta)
        .order('data_ocorrencia', ascending: false);

    return response.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<List<Map<String, dynamic>>> buscarOcorrenciasGeral() async {

    final response = await _client
        .from('ocorrencias_jovem')
        .select('*, jovens_aprendizes(nome)')
        .order('data_ocorrencia', ascending: false);

    return response.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, int>> buscarResumoOcorrenciasPessoais() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('ocorrencias_jovem')
        .select('tipo')
        .eq('jovem_id', userId);

    if (response.isEmpty) {
      return {
        'Instituto': 0,
        'Escola': 0,
        'Empresa': 0,
      };
    }

    final Map<String, int> contagem = {
      'Instituto': 0,
      'Escola': 0,
      'Empresa': 0,
    };

    for (final item in response) {
      final tipo = (item['tipo'] ?? '').toString().toLowerCase();
      if (tipo == 'instituto') contagem['Instituto'] = contagem['Instituto']! + 1;
      if (tipo == 'escola') contagem['Escola'] = contagem['Escola']! + 1;
      if (tipo == 'empresa') contagem['Empresa'] = contagem['Empresa']! + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoOcorrenciasPorProfessor() async {
    final professorId = _client.auth.currentUser?.id;
    if (professorId == null) return {};

    final response = await _client
        .from('ocorrencias_jovem')
        .select('resolvido')
        .eq('id', professorId);

    if (response.isEmpty) {
      return {
        'Resolvidas': 0,
        'Pendentes': 0,
      };
    }

    int resolvidas = 0;
    int pendentes = 0;

    for (final item in response) {
      final resolvido = item['resolvido'];
      if (resolvido == true) {
        resolvidas++;
      } else {
        pendentes++;
      }
    }

    return {
      'Resolvidas': resolvidas,
      'Pendentes': pendentes,
    };
  }

  Future<Map<String, int>> buscarOcorrenciasPorStatusEmpresa() async {
    final empresaId = _client.auth.currentUser?.id;
    if (empresaId == null) return {'Resolvidas': 0, 'Pendentes': 0};

    // 1. Buscar ids dos jovens dessa empresa
    final jovens = await _client
        .from('jovens_aprendizes')
        .select('id')
        .eq('empresa_id', empresaId);

    if (jovens.isEmpty) return {'Resolvidas': 0, 'Pendentes': 0};

    final ids = jovens.map((j) => j['id']).toList();

    // 2. Buscar ocorrências do tipo 'empresa' para esses jovens
    final ocorrencias = await _client
        .from('ocorrencias_jovem')
        .select('resolvido')
        .eq('tipo', 'empresa')
        .inFilter('jovem_id', ids);

    int resolvidas = 0;
    int pendentes = 0;

    for (final o in ocorrencias) {
      if (o['resolvido'] == true) {
        resolvidas++;
      } else {
        pendentes++;
      }
    }

    return {
      'Resolvidas': resolvidas,
      'Pendentes': pendentes,
    };
  }

  Future<Map<String, int>> buscarResumoResolucao() async {
    final response = await _client
        .from('ocorrencias_jovem')
        .select('resolvido');

    if (response.isEmpty) {
      return {
        'Resolvidas': 0,
        'Pendentes': 0,
      };
    }

    int resolvidas = 0;
    int pendentes = 0;

    for (final item in response) {
      final resolvido = item['resolvido'];
      if (resolvido == true) {
        resolvidas++;
      } else {
        pendentes++;
      }
    }

    return {
      'Resolvidas': resolvidas,
      'Pendentes': pendentes,
    };
  }

  Future<Map<String, int>> buscarResumoOcorrencias() async {
    final response = await _client
        .from('ocorrencias_jovem')
        .select('tipo');

    if (response.isEmpty) {
      return {
        'Escola': 0,
        'Instituto': 0,
        'Empresa': 0,
      };
    }

    Map<String, int> resumo = {
      'Escola': 0,
      'Instituto': 0,
      'Empresa': 0,
    };

    for (final item in response) {
      final tipo = item['tipo']?.toString().toLowerCase() ?? '';
      if (tipo == 'escola') resumo['Escola'] = resumo['Escola']! + 1;
      if (tipo == 'instituto') resumo['Instituto'] = resumo['Instituto']! + 1;
      if (tipo == 'empresa') resumo['Empresa'] = resumo['Empresa']! + 1;
    }

    return resumo;
  }

  Future<Map<String, int>> buscarOcorrenciasPorStatusEscola() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      // Retorna o valor padrão se não houver usuário logado
      return {'Resolvidas': 0, 'Pendentes': 0};
    }

    String? escolaId;

    // 1. Determinar o ID da escola com base no tipo de usuário
    if (auth.tipoUsuario == "escola") {
      escolaId = currentUser.id;
    } else if (auth.tipoUsuario == "professor_externo") {
      try {
        final professorData = await _client
            .from('professores')
            .select('id_colegio')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (professorData != null && professorData['id_colegio'] != null) {
          escolaId = professorData['id_colegio'].toString();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erro ao buscar escola do professor: $e");
        }
        return {'Resolvidas': 0, 'Pendentes': 0};
      }
    }

    // 2. Se não foi possível determinar o ID da escola, retorna o valor padrão
    if (escolaId == null) {
      if (kDebugMode) {
        print("Não foi possível determinar a escola para o usuário: ${currentUser.id}");
      }
      return {'Resolvidas': 0, 'Pendentes': 0};
    }

    // 3. Buscar e processar as ocorrências usando o 'escolaId' determinado
    try {
      // Buscar ids dos jovens da escola correta
      final jovens = await _client
          .from('jovens_aprendizes')
          .select('id')
          .eq('escola_id', escolaId); // <- AQUI está a mudança principal

      if (jovens.isEmpty) {
        return {'Resolvidas': 0, 'Pendentes': 0};
      }

      final ids = jovens.map((j) => j['id']).toList();

      // Buscar ocorrências do tipo 'escola' desses jovens
      final ocorrencias = await _client
          .from('ocorrencias_jovem')
          .select('resolvido')
          .eq('tipo', 'escola')
          .inFilter('jovem_id', ids);

      int resolvidas = 0;
      int pendentes = 0;

      for (final o in ocorrencias) {
        if (o['resolvido'] == true) {
          resolvidas++;
        } else {
          pendentes++;
        }
      }

      return {
        'Resolvidas': resolvidas,
        'Pendentes': pendentes,
      };
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao buscar dados de ocorrências: $e");
      }
      return {'Resolvidas': 0, 'Pendentes': 0};
    }
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