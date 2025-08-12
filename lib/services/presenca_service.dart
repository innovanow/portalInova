import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresencaService {
  final _client = Supabase.instance.client;

  /// Retorna um mapa com dados agregados de presença: 'Presentes' e 'Faltas'
  Future<Map<String, int>> buscarResumoPresenca() async {
    final response = await _client
        .from('historico_chamadas')
        .select('presentes, faltas');

    if (response.isEmpty) {
      return {
        'Presentes': 0,
        'Faltas': 0,
      };
    }

    int totalPresentes = 0;
    int totalFaltas = 0;

    for (final row in response) {
      totalPresentes += row['presentes'] == null ? 0 : int.parse(row['presentes'].toString());
      totalFaltas += row['faltas'] == null ? 0 : int.parse(row['faltas'].toString());
    }

    return {
      'Presentes': totalPresentes,
      'Faltas': totalFaltas,
    };
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoPresencaPessoal() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. Buscar o jovem e descobrir a turma dele (lógica inalterada)
    final jovem = await _client
        .from('jovens_aprendizes')
        .select('turma_id')
        .eq('id', userId)
        .single();

    final turmaId = jovem['turma_id'];
    if (turmaId == null) return [];

    // 2. Buscar os módulos que pertencem diretamente à turma do jovem.
    final modulosResponse = await _client
        .from('modulos')
        .select('datas')
        .eq('turma_id', turmaId);

    final diasComAula = <DateTime>{};

    // AJUSTE: Pega a data de hoje para filtrar apenas aulas passadas.
    final hoje = DateTime.now();
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    // 3. Ler os dias de aula diretamente do array 'datas' de cada módulo
    for (final modulo in modulosResponse) {
      final List<dynamic>? datasDoModulo = modulo['datas'];
      if (datasDoModulo != null) {
        for (final dataStr in datasDoModulo) {
          if (dataStr != null) {
            final dataAula = DateTime.parse(dataStr as String);
            final dataAulaNormalizada = DateTime(dataAula.year, dataAula.month, dataAula.day);

            // AJUSTE: Adiciona a data apenas se for hoje ou uma data passada.
            if (!dataAulaNormalizada.isAfter(hojeNormalizado)) {
              diasComAula.add(dataAulaNormalizada);
            }
          }
        }
      }
    }

    // 4. Buscar as presenças do jovem (lógica inalterada)
    final presencas = await _client
        .from('presencas')
        .select('data, presente')
        .eq('jovem_id', userId);

    final mapaPresenca = {
      for (final p in presencas)
        DateFormat('yyyy-MM-dd').format(DateTime.parse(p['data'])):
        p['presente'] == true
    };

    // 5. Gerar histórico baseado nos dias letivos (lógica inalterada)
    final historico = diasComAula.toList()..sort((a, b) => a.compareTo(b));

    return historico.map((data) {
      final chave = DateFormat('yyyy-MM-dd').format(data);
      return {
        'data': data,
        'presente': mapaPresenca[chave] ?? false, // Se não houver registro, assume falta
      };
    }).toList();
  }

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
        .select('id, nome, turma_id')
        .eq('professor_id', professorId)
        .eq('status', 'ativo')
        .order('data_inicio');

    if (kDebugMode) {
      print('Modulos: $modulos $professorId');
    }

    return modulos;
  }

  Future<List<Map<String, dynamic>>> listarAlunosPorTurma(String turmaId) async {
    final response = await _client
        .from('jovens_aprendizes')
        .select('id, nome')
        .eq('turma_id', turmaId)
        .eq('status', 'ativo')
        .order('nome', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, int>> buscarTopAlunosComMaisFaltas() async {
    final professorId = _client.auth.currentUser?.id;
    if (professorId == null) return {};

    // 1. Buscar módulos do professor
    final modulos = await _client
        .from('modulos')
        .select('id')
        .eq('professor_id', professorId);

    final moduloIds = modulos.map((m) => m['id']).toList();
    if (moduloIds.isEmpty) return {};

    // 2. Buscar presenças desses módulos
    final presencas = await _client
        .from('presencas')
        .select('jovem_id, presente')
        .inFilter('modulo_id', moduloIds);

    // 3. Contar faltas por jovem
    final Map<String, int> faltasPorJovem = {};
    for (final p in presencas) {
      if (p['presente'] == false) {
        final jovemId = p['jovem_id'];
        faltasPorJovem[jovemId] = (faltasPorJovem[jovemId] ?? 0) + 1;
      }
    }

    if (faltasPorJovem.isEmpty) return {};

    // 4. Buscar nomes dos jovens
    final ids = faltasPorJovem.keys.toList();
    final jovens = await _client
        .from('jovens_aprendizes')
        .select('id, nome')
        .inFilter('id', ids);

    final Map<String, String> nomes = {
      for (final j in jovens) j['id']: j['nome'] ?? 'Sem nome'
    };

    // 5. Substituir id por nome e ordenar pelos que mais faltaram
    final Map<String, int> resultado = {
      for (final id in faltasPorJovem.keys)
        nomes[id] ?? 'Desconhecido': faltasPorJovem[id]!,
    };

    // 6. Ordenar por maior número de faltas
    final sorted = resultado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 7. Retornar top 5
    return Map.fromEntries(sorted.take(5));
  }

  Future<Map<String, int>> buscarPresencaMediaPorEmpresa() async {
    final empresaId = _client.auth.currentUser?.id;
    if (empresaId == null) return {'Presentes': 0, 'Faltas': 0};

    // 1. Buscar jovens da empresa
    final jovens = await _client
        .from('jovens_aprendizes')
        .select('id')
        .eq('empresa_id', empresaId);

    if (jovens.isEmpty) return {'Presentes': 0, 'Faltas': 0};

    final ids = jovens.map((j) => j['id']).toList();

    // 2. Buscar presenças desses jovens
    final presencas = await _client
        .from('presencas')
        .select('presente')
        .inFilter('jovem_id', ids);

    int presentes = 0;
    int faltas = 0;

    for (final p in presencas) {
      if (p['presente'] == true) {
        presentes++;
      } else {
        faltas++;
      }
    }

    return {
      'Presentes': presentes,
      'Faltas': faltas,
    };
  }

  Future<Map<String, int>> buscarTopFaltasPorJovensEmpresa() async {
    final empresaId = _client.auth.currentUser?.id;
    if (empresaId == null) return {};

    // 1. Buscar ids dos jovens da empresa
    final jovens = await _client
        .from('jovens_aprendizes')
        .select('id')
        .eq('empresa_id', empresaId);

    if (jovens.isEmpty) return {};

    final ids = jovens.map((j) => j['id']).toList();

    // 2. Buscar presenças desses jovens
    final presencas = await _client
        .from('presencas')
        .select('jovem_id, presente')
        .inFilter('jovem_id', ids);

    // 3. Contar faltas por jovem
    final Map<String, int> faltas = {};

    for (final p in presencas) {
      if (p['presente'] == false) {
        final id = p['jovem_id'];
        faltas[id] = (faltas[id] ?? 0) + 1;
      }
    }

    if (faltas.isEmpty) return {};

    // 4. Buscar nomes dos jovens
    final jovensNomes = await _client
        .from('jovens_aprendizes')
        .select('id, nome')
        .inFilter('id', faltas.keys.toList());

    final nomes = {
      for (final j in jovensNomes)
        j['id']: j['nome'] ?? 'Sem nome'
    };

    // 5. Substituir id por nome e ordenar
    final resultado = {
      for (final id in faltas.keys)
        nomes[id] ?? 'Desconhecido': faltas[id]!,
    };

    final sorted = resultado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(
      sorted.take(5).map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }

  Future<Map<String, int>> buscarPresencaMediaPorEscola() async {
    final escolaId = _client.auth.currentUser?.id;
    if (escolaId == null) return {'Presentes': 0, 'Faltas': 0};

    // 1. Buscar ids dos jovens da escola
    final jovens = await _client
        .from('jovens_aprendizes')
        .select('id')
        .eq('escola_id', escolaId);

    if (jovens.isEmpty) return {'Presentes': 0, 'Faltas': 0};

    final ids = jovens.map((j) => j['id']).toList();

    // 2. Buscar presenças desses jovens
    final presencas = await _client
        .from('presencas')
        .select('presente')
        .inFilter('jovem_id', ids);

    int presentes = 0;
    int faltas = 0;

    for (final p in presencas) {
      if (p['presente'] == true) {
        presentes++;
      } else {
        faltas++;
      }
    }

    return {
      'Presentes': presentes,
      'Faltas': faltas,
    };
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
    .eq('professor_id', professorId)
        .order('data', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoChamadasGeral() async {
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

    return response.map((e) {
      final modulo = e['modulos'];
      final professor = modulo?['professores'];

      return {
        'data': e['data'],
        'presente': e['presente'],
        'modulo_nome': modulo?['nome'] ?? 'Módulo desconhecido',
        'professor_nome': professor?['nome'] ?? 'Professor desconhecido',
      };
    }).toList();
  }
}