
import 'package:supabase_flutter/supabase_flutter.dart';

class JovemService {
  final supabase = Supabase.instance.client;

  // Buscar todas os jovens
  Future<List<Map<String, dynamic>>> buscarjovem(status) async {
    final response = await supabase.from('jovens_aprendizes').select().eq('status', '$status').order('nome', ascending: true);
    return response;
  }

  Future<List<String>> buscarTurmasDoProfessor(String professorId) async {
    // 1. Buscar os módulos do professor
    final modulos = await supabase
        .from('modulos')
        .select('id')
        .eq('professor_id', professorId);

    final moduloIds = (modulos as List)
        .map((modulo) => modulo['id'].toString())
        .toList();

    if (moduloIds.isEmpty) return [];

    // 2. Buscar as turmas associadas a esses módulos via tabela intermediária
    final modulosTurmas = await supabase
        .from('modulos_turmas')
        .select('turma_id')
        .inFilter('modulo_id', moduloIds);

    // 3. Extrair os IDs das turmas (evita duplicados com toSet())
    final turmaIds = (modulosTurmas as List)
        .map((item) => item['turma_id'].toString())
        .toSet()
        .toList();

    return turmaIds;
  }

  Future<List<Map<String, dynamic>>> buscarJovensDoProfessor(String professorId, String status) async {
    final turmasIds = await buscarTurmasDoProfessor(professorId);

    if (turmasIds.isEmpty) return [];

    final response = await supabase
        .from('jovens_aprendizes')
        .select('*, turmas(codigo_turma, modulos_turmas(modulos(nome)))')
        .inFilter('turma_id', turmasIds)
        .eq('status', status);

    return response;
  }

  Future<List<Map<String, dynamic>>> buscarJovensDaEscola(String escolaId, String status) async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('*, turmas(codigo_turma)')
        .eq('escola_id', escolaId)
        .eq('status', status)
        .order('nome', ascending: true);
    return response;
  }

  Future<List<Map<String, dynamic>>> buscarJovensDaEmpresa(String empresaId, String status) async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('*, turmas(codigo_turma)')
        .eq('empresa_id', empresaId)
        .eq('status', status)
        .order('nome', ascending: true);
    return response;
  }


  Future<void> inativarJovem(String id) async {
    await supabase.from('jovens_aprendizes').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarJovem(String id) async {
    await supabase.from('jovens_aprendizes').update({'status': 'ativo'}).eq('id', id);
  }

  double converterParaNumero(String valor) {
    // Remove qualquer caractere que não seja número ou vírgula
    String numeroLimpo = valor
        .replaceAll('.', '')               // remove ponto de milhar
        .replaceAll(RegExp(r'[^\d,]'), '') // mantém apenas números e vírgula
        .replaceAll(',', '.');             // troca vírgula decimal por ponto

    return double.tryParse(numeroLimpo) ?? 0.0;
  }


  // Cadastrar um novo jovem
  Future<String?> cadastrarjovem({
    required String nome,
    required String? dataNascimento,
    required String nomePai,
    required String nomeMae,
    required String nomeResponsavel,
    required String endereco,
    required String numero,
    required String bairro,
    required String? cidadeEstado,
    required String cep,
    required String telefoneJovem,
    required String telefonePai,
    required String telefoneMae,
    required String? escola,
    required String? empresa,
    required String? escolaridade,
    required String email,
    required String senha,
    required String cpf,
    required String cpfMae,
    required String cpfPai,
    required String rg,
    required String rgMae,
    required String rgPai,
    required String? cidadeEstadoNatal,
    required String codCarteiraTrabalho,
    required String? estadoCivilPai,
    required String? estadoCivilMae,
    required String? estadoCivil,
    required String? estadoCivilResponsavel,
    required String remuneracao,
    required String horasTrabalho,
    required String? turma,
    required String? sexoBiologico,
    required String? orientacaoSexual,
    required String? identidadeGenero,
    required String? cor,
    required String? pcd,
    required String? estudando,
    required String? trabalhando,
    required String escolaAlternativa,
    required String empresaAlternativa,
    required String? nacionalidade,
    required String? moraCom,
    required String? infracao,
    required String? rendaMensal,
    required String? turnoEscola,
    required String? anoIncioEscola,
    required String? anoConclusaoEscola,
    required String? instituicaoEscola,
    required String? informatica,
    required String? habilidadeDestaque,
    required String? codPis,
    required String? instagram,
    required String? linkedin,
    required String? areaAprendizado,
  }) async {
    try {
      // 🔍 Verifica se já existe usuário cadastrado com esse email
      final existingUsers = await supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      String userId;

      if (existingUsers != null) {
        userId = existingUsers['id'];
      } else {
        // 🧾 Cria novo usuário
        final response = await supabase.auth.signUp(
          email: email,
          password: senha,
        );

        userId = response.user?.id ?? '';
        if (userId.isEmpty) return "Erro ao criar usuário.";

        // 👤 Cria o registro na tabela 'users'
        await supabase.from('users').insert({
          'id': userId,
          'nome': nome,
          'email': email,
          'tipo': 'jovem_aprendiz',
        });
      }

      // ✅ Cria o registro na tabela 'jovens_aprendizes'
      await supabase.from('jovens_aprendizes').insert({
        'id': userId,
        'nome': nome,
        'data_nascimento': dataNascimento,
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'endereco': endereco,
        'numero': numero,
        'bairro': bairro,
        'cidade_estado': cidadeEstado,
        'cep': cep,
        'telefone_jovem': telefoneJovem,
        'telefone_pai': telefonePai,
        'telefone_mae': telefoneMae,
        'escola_id': escola,
        'empresa_id': empresa,
        'escolaridade': escolaridade,
        'cpf': cpf,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
        'rg': rg,
        'cidade_estado_natal': cidadeEstadoNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'cpf_pai': cpfPai,
        'cpf_mae': cpfMae,
        'rg_pai': rgPai,
        'rg_mae': rgMae,
        'turma_id': turma,
        'status': 'ativo',
        'sexo_biologico': sexoBiologico,
        'orientacao_sexual': orientacaoSexual,
        'identidade_genero': identidadeGenero,
        'cor': cor,
        'pcd': pcd,
        'estudando': estudando,
        'trabalhando': trabalhando,
        'escola_alternativa': escolaAlternativa,
        'empresa_alternativa': empresaAlternativa,
        'nacionalidade': nacionalidade,
        'mora_com': moraCom,
        'infracao': infracao,
        'renda_mensal': rendaMensal,
        'turno_escola': turnoEscola,
        'ano_inicio_escola': anoIncioEscola,
        'ano_conclusao_escola': anoConclusaoEscola,
        'instituicao_escola': instituicaoEscola,
        'informatica': informatica,
        'habilidade_destaque': habilidadeDestaque,
        'cod_pis': codPis,
        'instagram': instagram,
        'linkedin': linkedin,
        'area_aprendizado': areaAprendizado,
      });

      return null;
    } catch (e) {
      return "Erro ao cadastrar jovem: ${e.toString()}";
    }
  }


  // Atualizar escola
  Future<String?> atualizarjovem({
    required String id,
    required String nome,
    required String? dataNascimento,
    required String nomePai,
    required String nomeMae,
    required String nomeResponsavel,
    required String endereco,
    required String numero,
    required String bairro,
    required String? cidadeEstado,
    required String cep,
    required String telefoneJovem,
    required String telefonePai,
    required String telefoneMae,
    required String? escola,
    required String? empresa,
    required String? escolaridade,
    required String cpf,
    required String cpfMae,
    required String cpfPai,
    required String rg,
    required String rgMae,
    required String rgPai,
    required String? cidadeEstadoNatal,
    required String codCarteiraTrabalho,
    required String? estadoCivilPai,
    required String? estadoCivilMae,
    required String? estadoCivil,
    required String? estadoCivilResponsavel,
    required String remuneracao,
    required String horasTrabalho,
    required String? turma,
    required String? sexoBiologico,
    required String? orientacaoSexual,
    required String? identidadeGenero,
    required String? cor,
    required String? pcd,
    required String? estudando,
    required String? trabalhando,
    required String escolaAlternativa,
    required String empresaAlternativa,
    required String? nacionalidade,
    required String? moraCom,
    required String? infracao,
    required String? rendaMensal,
    required String? turnoEscola,
    required String? anoIncioEscola,
    required String? anoConclusaoEscola,
    required String? instituicaoEscola,
    required String? informatica,
    required String? habilidadeDestaque,
    required String? codPis,
    required String? instagram,
    required String? linkedin,
    required String? areaAprendizado,
  }) async {
    try {
      await supabase.from('jovens_aprendizes').update({
        'nome': nome,
        'data_nascimento': dataNascimento,
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'endereco': endereco,
        'numero': numero,
        'bairro': bairro,
        'cidade_estado': cidadeEstado,
        'cep': cep,
        'telefone_jovem': telefoneJovem,
        'telefone_pai': telefonePai,
        'telefone_mae': telefoneMae,
        'escola_id': escola,
        'empresa_id': empresa,
        'escolaridade': escolaridade,
        'cpf': cpf,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
        'rg': rg,
        'cidade_estado_natal': cidadeEstadoNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'cpf_pai': cpfPai,
        'cpf_mae': cpfMae,
        'rg_pai': rgPai,
        'rg_mae': rgMae,
        'turma_id': turma,
        'sexo_biologico': sexoBiologico,
        'orientacao_sexual': orientacaoSexual,
        'identidade_genero': identidadeGenero,
        'cor': cor,
        'pcd': pcd,
        'estudando': estudando,
        'trabalhando': trabalhando,
        'escola_alternativa': escolaAlternativa,
        'empresa_alternativa': empresaAlternativa,
        'nacionalidade': nacionalidade,
        'mora_com': moraCom,
        'infracao': infracao,
        'renda_mensal': rendaMensal,
        'turno_escola': turnoEscola,
        'ano_inicio_escola': anoIncioEscola,
        'ano_conclusao_escola': anoConclusaoEscola,
        'instituicao_escola': instituicaoEscola,
        'informatica': informatica,
        'habilidade_destaque': habilidadeDestaque,
        'cod_pis': codPis,
        'instagram': instagram,
        'linkedin': linkedin,
        'area_aprendizado': areaAprendizado,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  // Buscar escolas para o dropdown
  Future<List<Map<String, dynamic>>> buscarEscolas() async {
    final response = await supabase.from('escolas').select().eq('status', 'ativo');
    return response;
  }

  // Buscar empresas para o dropdown
  Future<List<Map<String, dynamic>>> buscarEmpresas() async {
    final response = await supabase.from('empresas').select().eq('status', 'ativo').order('nome', ascending: true);
    return response;
  }

  // Buscar turmas para o dropdown
  Future<List<Map<String, dynamic>>> buscarTurmas() async {
    final response = await supabase.from('turmas').select().eq('status', 'ativo').order('codigo_turma', ascending: true);
    return response;
  }
}
