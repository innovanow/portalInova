import 'package:supabase_flutter/supabase_flutter.dart';

class ModuloService {
  final supabase = Supabase.instance.client;

  // Buscar todas os modulos
  Future<List<Map<String, dynamic>>> buscarModulos(String statusModulo) async {
    final response = await supabase
        .from('modulos')
        .select('*, professores!modulos_professor_id_fkey(nome)')
        .eq('status', statusModulo);

    return response;
  }

  Future<Map<String, int>> buscarModulosParticipadosPorNome() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {};

    // 1. Buscar turma do jovem
    final jovem = await supabase
        .from('jovens_aprendizes')
        .select('turma_id')
        .eq('id', userId)
        .single();

    final turmaId = jovem['turma_id'];
    if (turmaId == null) return {};

    // 2. Buscar módulos da turma com id e nome
    final modulos = await supabase
        .from('modulos')
        .select('id, nome')
        .eq('turma_id', turmaId);

    if (modulos.isEmpty) return {};

    // 3. Buscar presenças do jovem
    final presencas = await supabase
        .from('presencas')
        .select('modulo_id')
        .eq('jovem_id', userId);

    final idsComPresenca = presencas
        .map((p) => p['modulo_id'])
        .toSet();

    // 4. Filtrar os módulos com presença e contar
    final Map<String, int> modulosParticipados = {};

    for (final m in modulos) {
      final id = m['id'];
      final nome = m['nome'] ?? 'Sem nome';
      if (idsComPresenca.contains(id)) {
        modulosParticipados[nome] = 1;
      }
    }

    return modulosParticipados;
  }

  Future<List<Map<String, dynamic>>> buscarProfessores() async {
    final response = await supabase.from('professores').select().eq(
        'status', 'ativo').order('nome', ascending: true);
    return response;
  }

  Future<void> inativarModulo(String id) async {
    await supabase.from('modulos').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarModulo(String id) async {
    await supabase.from('modulos').update({'status': 'ativo'}).eq('id', id);
  }

  Future<Map<String, int>> buscarResumoModulosPorProfessor() async {
    final response = await supabase
        .from('modulos')
        .select('professores(nome)')
        .filter('professor_id', 'not.is', null); // <- CORRETO

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final nome = item['professores']?['nome'] ?? 'Não informado';
      contagem[nome] = (contagem[nome] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarTotalJovensPorModuloDoProfessor() async {
    final professorId = supabase.auth.currentUser?.id;
    if (professorId == null) return {};

    // 1. Buscar módulos do professor
    final modulos = await supabase
        .from('modulos')
        .select('id, nome')
        .eq('professor_id', professorId);

    if (modulos.isEmpty) return {};

    final Map<String, int> resultado = {};

    for (final modulo in modulos) {
      final moduloId = modulo['id'];
      final nomeModulo = modulo['nome'];

      // 2. Buscar turmas associadas a esse módulo
      final modulosTurmas = await supabase
          .from('modulos_turmas')
          .select('turma_id')
          .eq('modulo_id', moduloId);

      final turmaIds = modulosTurmas
          .map((mt) => mt['turma_id'])
          .where((id) => id != null)
          .toSet();

      // 3. Contar jovens nessas turmas
      int totalJovens = 0;

      if (turmaIds.isNotEmpty) {
        final jovens = await supabase
            .from('jovens_aprendizes')
            .select('id')
            .inFilter('turma_id', turmaIds.toList());

        totalJovens = jovens.length;
      }

      resultado[nomeModulo] = totalJovens;
    }

    return resultado;
  }

  Future<String?> cadastrarModulos({
    required String nome,
    required String? turno,
    required String? cor,
    required String professorId,
    required List<Map<String, dynamic>> datasComHorarios,
  }) async {
    try {
      // Converte para lista de strings ISO: cada item = 'inicio' e 'fim' como DateTime
      final List<String> datasParaSalvar = datasComHorarios.expand((item) {
        final DateTime inicio = item['inicio'] as DateTime;
        final DateTime fim = item['fim'] as DateTime;
        return [inicio.toIso8601String(), fim.toIso8601String()];
      }).toList();

      await supabase.from('modulos').insert({
        'nome': nome,
        'turno': turno,
        'status': 'ativo',
        'cor': cor,
        'professor_id': professorId,
        'datas': datasParaSalvar,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> atualizarModulos({
    required String id,
    required String nome,
    required String? turno,
    required String? cor,
    required String professorId,
    required List<Map<String, dynamic>> datasComHorarios,
  }) async {
    try {
      // Converte para lista de strings ISO
      final List<String> datasParaSalvar = datasComHorarios.expand((item) {
        final DateTime inicio = item['inicio'] as DateTime;
        final DateTime fim = item['fim'] as DateTime;
        return [inicio.toIso8601String(), fim.toIso8601String()];
      }).toList();

      await supabase.from('modulos').update({
        'nome': nome,
        'turno': turno,
        'cor': cor,
        'professor_id': professorId,
        'datas': datasParaSalvar,
      }).match({'id': id});

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}