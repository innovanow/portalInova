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

    // 1. Buscar o jovem e descobrir a turma dele
    final jovem = await _client
        .from('jovens_aprendizes')
        .select('turma_id')
        .eq('id', userId)
        .single();

    final turmaId = jovem['turma_id'];
    if (turmaId == null) return [];

    // 2. Buscar os módulos da turma com lista de dias da semana
    final modulos = await _client
        .from('modulos')
        .select('data_inicio, data_fim, dia_semana')
        .eq('turma_id', turmaId);

    final diasComAula = <DateTime>{};

    for (final modulo in modulos) {
      final inicio = DateTime.parse(modulo['data_inicio']);
      final fim = DateTime.parse(modulo['data_fim']);
      final diasSemanaStr = List<String>.from(modulo['dia_semana'] ?? []);

      final diasSemana = _converterDiasSemana(diasSemanaStr);

      for (var dia = inicio;
      dia.isBefore(fim.add(const Duration(days: 1)));
      dia = dia.add(const Duration(days: 1))) {
        if (diasSemana.contains(dia.weekday)) {
          diasComAula.add(dia);
        }
      }
    }

    // 3. Buscar as presenças do jovem
    final presencas = await _client
        .from('presencas')
        .select('data, presente')
        .eq('jovem_id', userId);

    final mapaPresenca = {
      for (final p in presencas)
        DateFormat('yyyy-MM-dd').format(DateTime.parse(p['data'])):
        p['presente'] == true
    };

    // 4. Gerar histórico baseado nos dias letivos
    final historico = diasComAula.toList()
      ..sort();

    return historico.map((data) {
      final chave = DateFormat('yyyy-MM-dd').format(data);
      return {
        'data': data,
        'presente': mapaPresenca[chave] ?? false,
      };
    }).toList();
  }

  // 🧠 Converte lista de strings para números do DateTime.weekday (1 = segunda)
  Set<int> _converterDiasSemana(List<String> dias) {
    const map = {
      'segunda-feira': DateTime.monday,
      'terça-feira': DateTime.tuesday,
      'quarta-feira': DateTime.wednesday,
      'quinta-feira': DateTime.thursday,
      'sexta-feira': DateTime.friday,
      'sábado': DateTime.saturday,
      'domingo': DateTime.sunday,
    };

    return dias
        .map((d) => map[d.toLowerCase()] ?? -1)
        .where((d) => d > 0)
        .toSet();
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