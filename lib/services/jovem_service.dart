
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
    required String rendaMensal,
    required String? turnoEscola,
    required int? anoIncioEscola,
    required int? anoConclusaoEscola,
    required String? instituicaoEscola,
    required String? informatica,
    required String? habilidadeDestaque,
    required String? codPis,
    required String? instagram,
    required String? linkedin,
    required String? areaAprendizado,
  }) async {
    try {
      // 1. Validação de e-mail duplicado
      final existingUser = await supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        return "E-mail já cadastrado.";
      }

      // 2. Validação de CPF duplicado
      final existingCpf = await supabase
          .from('jovens_aprendizes')
          .select('id')
          .eq('cpf', cpf)
          .maybeSingle();

      if (existingCpf != null) {
        return "CPF já cadastrado.";
      }

      // 3. Criar usuário no Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: senha,
      );

      final userId = response.user?.id;
      if (userId == null || userId.isEmpty) {
        return "Erro ao criar usuário no Supabase Auth.";
      }

      try {
        // 4. Criar na tabela users
        await supabase.from('users').insert({
          'id': userId,
          'nome': nome,
          'email': email,
          'tipo': 'jovem_aprendiz',
        });

        // 5. Criar na tabela jovens_aprendizes
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
          'status': 'precadastrado',
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
          'renda_mensal': converterParaNumero(rendaMensal),
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
          // ... outros campos
        });

        return null; // Sucesso

      } catch (e) {
        // ⚠ Se falhar na tabela users ou jovens_aprendizes, remove do Auth
        await supabase.auth.admin.deleteUser(userId);
        return "Erro ao salvar dados do jovem: ${e.toString()}";
      }

    } catch (e) {
      return "Erro inesperado: ${e.toString()}";
    }
  }

  // Precadastro novo jovem
  Future<String?> precadastrarjovem({
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
    required String rendaMensal,
    required String? turnoEscola,
    required int? anoIncioEscola,
    required int? anoConclusaoEscola,
    required String? instituicaoEscola,
    required String? informatica,
    required String? habilidadeDestaque,
    required String? codPis,
    required String? instagram,
    required String? linkedin,
    required String? areaAprendizado,
  }) async {
    try {
      // 1. Validação de e-mail duplicado
      final existingUser = await supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        return "E-mail já cadastrado.";
      }

      // 2. Validação de CPF duplicado
      final existingCpf = await supabase
          .from('jovens_aprendizes')
          .select('id')
          .eq('cpf', cpf)
          .maybeSingle();

      if (existingCpf != null) {
        return "CPF já cadastrado.";
      }

      // 3. Criar usuário no Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: senha,
      );

      final userId = response.user?.id;
      if (userId == null || userId.isEmpty) {
        return "Erro ao criar usuário no Supabase Auth.";
      }

      try {
        // 4. Criar na tabela users
        await supabase.from('users').insert({
          'id': userId,
          'nome': nome,
          'email': email,
          'tipo': 'jovem_aprendiz',
        });

        // 5. Criar na tabela jovens_aprendizes
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
          'status': 'precadastrado',
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
          'renda_mensal': converterParaNumero(rendaMensal),
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
          // ... outros campos
        });

        return null; // Sucesso

      } catch (e) {
        // ⚠ Se falhar na tabela users ou jovens_aprendizes, remove do Auth
        await supabase.auth.admin.deleteUser(userId);
        return "Erro ao salvar dados do jovem: ${e.toString()}";
      }

    } catch (e) {
      return "Erro inesperado: ${e.toString()}";
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
    required String rendaMensal,
    required String? turnoEscola,
    required int? anoIncioEscola,
    required int? anoConclusaoEscola,
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
        'renda_mensal': converterParaNumero(rendaMensal),
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
    final response = await supabase.from('escolas').select().or('status.eq.ativo,status.eq.outro').order('nome', ascending: true);
    return response;
  }

  // Buscar empresas para o dropdown
  Future<List<Map<String, dynamic>>> buscarEmpresas() async {
    final response = await supabase.from('empresas').select().or('status.eq.ativo,status.eq.outro').order('nome', ascending: true);
    return response;
  }

  // Buscar turmas para o dropdown
  Future<List<Map<String, dynamic>>> buscarTurmas() async {
    final response = await supabase.from('turmas').select().or('status.eq.ativo,status.eq.outro').order('codigo_turma', ascending: true);
    return response;
  }

  Future<Map<String, int>> buscarResumoPCD() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('pcd');

    if (response.isEmpty) {
      return {
        'PCD': 0,
        'Não PCD': 0,
      };
    }

    int pcd = 0;
    int naoPcd = 0;

    for (final item in response) {
      final valor = (item['pcd'] ?? '').toString().toLowerCase();
      if (valor == 'sim') {
        pcd++;
      } else {
        naoPcd++;
      }
    }

    return {
      'PCD': pcd,
      'Não PCD': naoPcd,
    };
  }

  Future<Map<String, int>> buscarResumoStatus() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('status');

    if (response.isEmpty) {
      return {
        'Ativos': 0,
        'Inativos': 0,
      };
    }

    int ativos = 0;
    int inativos = 0;

    for (final item in response) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      if (status == 'ativo') {
        ativos++;
      } else if (status == 'inativo') {
        inativos++;
      }
    }

    return {
      'Ativos': ativos,
      'Inativos': inativos,
    };
  }

  Future<Map<String, int>> buscarResumoEstudando() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('estudando');

    if (response.isEmpty) {
      return {
        'Estudando': 0,
        'Não Estudando': 0,
      };
    }

    int estudando = 0;
    int naoEstudando = 0;

    for (final item in response) {
      final valor = (item['estudando'] ?? '').toString().toLowerCase();
      if (valor == 'sim') {
        estudando++;
      } else {
        naoEstudando++;
      }
    }

    return {
      'Estudando': estudando,
      'Não Estudando': naoEstudando,
    };
  }

  Future<Map<String, int>> buscarResumoBeneficioAssistencial() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('beneficio_assistencial');

    if (response.isEmpty) {
      return {
        'Com benefício': 0,
        'Sem benefício': 0,
      };
    }

    int comBeneficio = 0;
    int semBeneficio = 0;

    for (final item in response) {
      final valor = (item['beneficio_assistencial'] ?? '').toString().toLowerCase();
      if (valor == 'sim') {
        comBeneficio++;
      } else {
        semBeneficio++;
      }
    }

    return {
      'Com benefício': comBeneficio,
      'Sem benefício': semBeneficio,
    };
  }

  Future<Map<String, int>> buscarResumoTurnoEscola() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('turno_escola');

    if (response.isEmpty) {
      return {
        'Manhã': 0,
        'Tarde': 0,
        'Noite': 0,
        'Outro': 0,
      };
    }

    int manha = 0;
    int tarde = 0;
    int noite = 0;
    int outro = 0;

    for (final item in response) {
      final turno = (item['turno_escola'] ?? '').toString().toLowerCase();
      if (turno.contains('manhã') || turno.contains('matutino')) {
        manha++;
      } else if (turno.contains('tarde') || turno.contains('vespertino')) {
        tarde++;
      } else if (turno.contains('noite') || turno.contains('noturno')) {
        noite++;
      } else {
        outro++;
      }
    }

    return {
      'Manhã': manha,
      'Tarde': tarde,
      'Noite': noite,
      'Outro': outro,
    };
  }

  Future<Map<String, int>> buscarResumoNacionalidade() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('nacionalidade');

    if (response.isEmpty) {
      return {'Brasileira': 0, 'Outra': 0};
    }

    int brasileira = 0;
    int outras = 0;

    for (final item in response) {
      final nacionalidade = (item['nacionalidade'] ?? '').toString().toLowerCase();
      if (nacionalidade.contains('brasileira')) {
        brasileira++;
      } else {
        outras++;
      }
    }

    return {
      'Brasileira': brasileira,
      'Outra': outras,
    };
  }

  Future<Map<String, int>> buscarResumoMoraCom() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('mora_com');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final valor = (item['mora_com'] ?? 'Não informado').toString().trim();
      final chave = valor.isEmpty ? 'Não informado' : valor;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoQuantidadeFilhos() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('possui_filhos');

    if (response.isEmpty) {
      return {
        'Sem filhos': 0,
        '1 filho': 0,
        '2 filhos': 0,
        '3 filhos': 0,
        '4+ filhos': 0,
      };
    }

    final Map<String, int> contagem = {
      'Sem filhos': 0,
      '1 filho': 0,
      '2 filhos': 0,
      '3 filhos': 0,
      '4+ filhos': 0,
    };

    for (final item in response) {
      final valor = (item['possui_filhos'] ?? 'Não').toString();

      switch (valor) {
        case 'Não':
          contagem['Sem filhos'] = contagem['Sem filhos']! + 1;
          break;
        case '1':
          contagem['1 filho'] = contagem['1 filho']! + 1;
          break;
        case '2':
          contagem['2 filhos'] = contagem['2 filhos']! + 1;
          break;
        case '3':
          contagem['3 filhos'] = contagem['3 filhos']! + 1;
          break;
        case '4':
          contagem['4+ filhos'] = contagem['4+ filhos']! + 1;
          break;
        default:
          contagem['Sem filhos'] = contagem['Sem filhos']! + 1;
      }
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoCorRaca() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('cor');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final cor = (item['cor'] ?? 'Não informado').toString().trim();
      final chave = cor.isEmpty ? 'Não informado' : cor;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoIdentidadeGenero() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('identidade_genero');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final valor = (item['identidade_genero'] ?? 'Não informado').toString().trim();
      final chave = valor.isEmpty ? 'Não informado' : valor;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoOrientacaoSexual() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('orientacao_sexual');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final valor = (item['orientacao_sexual'] ?? 'Não informado').toString().trim();
      final chave = valor.isEmpty ? 'Não informado' : valor;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoPorEscola() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('escola');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final nome = (item['escola'] ?? 'Não informado').toString().trim();
      final chave = nome.isEmpty ? 'Não informado' : nome;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoPorEmpresa() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('empresa');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final nome = (item['empresa'] ?? 'Não informado').toString().trim();
      final chave = nome.isEmpty ? 'Não informado' : nome;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoPorTurma() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('cod_turma');

    if (response.isEmpty) return {};

    final Map<String, int> contagem = {};

    for (final item in response) {
      final codigo = (item['cod_turma'] ?? 'Não informado').toString().trim();
      final chave = codigo.isEmpty ? 'Não informado' : codigo;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    return contagem;
  }

  Future<Map<String, int>> buscarResumoTrabalhando() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('trabalhando');

    if (response.isEmpty) {
      return {
        'Trabalhando': 0,
        'Não trabalhando': 0,
      };
    }

    int trabalhando = 0;
    int naoTrabalhando = 0;

    for (final item in response) {
      final valor = (item['trabalhando'] ?? '').toString().toLowerCase();
      if (valor == 'sim') {
        trabalhando++;
      } else {
        naoTrabalhando++;
      }
    }

    return {
      'Trabalhando': trabalhando,
      'Não trabalhando': naoTrabalhando,
    };
  }

  Future<Map<String, int>> buscarResumoJovensPorTurmaEmpresa() async {
    final empresaId = supabase.auth.currentUser?.id;
    if (empresaId == null) return {};

    // 1. Buscar jovens da empresa logada
    final jovens = await supabase
        .from('jovens_aprendizes')
        .select('cod_turma')
        .eq('empresa_id', empresaId);

    if (jovens.isEmpty) return {};

    final Map<String, int> porTurma = {};

    for (final jovem in jovens) {
      final turma = (jovem['cod_turma'] ?? 'Não informado').toString().trim();
      final chave = turma.isEmpty ? 'Não informado' : turma;
      porTurma[chave] = (porTurma[chave] ?? 0) + 1;
    }

    return porTurma;
  }

  Future<Map<String, int>> buscarResumoJovensPorTurmaEscola() async {
    final escolaId = supabase.auth.currentUser?.id;
    if (escolaId == null) return {};

    // 1. Buscar jovens da escola logada
    final jovens = await supabase
        .from('jovens_aprendizes')
        .select('cod_turma')
        .eq('escola_id', escolaId);

    if (jovens.isEmpty) return {};

    final Map<String, int> porTurma = {};

    for (final jovem in jovens) {
      final turma = (jovem['cod_turma'] ?? 'Não informado').toString().trim();
      final chave = turma.isEmpty ? 'Não informado' : turma;
      porTurma[chave] = (porTurma[chave] ?? 0) + 1;
    }

    return porTurma;
  }

  Future<Map<String, int>> buscarResumoHabilidadesDestaque() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('habilidade_destaque');

    if (response.isEmpty) return {};

    final Map<String, int> habilidades = {
      'Adaptabilidade': 0,
      'Criatividade': 0,
      'Flexibilidade': 0,
      'Proatividade': 0,
      'Trabalho em equipe': 0,
    };

    for (final item in response) {
      final valor = (item['habilidade_destaque'] ?? '').toString().trim();
      if (habilidades.containsKey(valor)) {
        habilidades[valor] = habilidades[valor]! + 1;
      }
    }

    return habilidades;
  }

  Future<Map<String, int>> buscarResumoHabilidadesDestaqueEmpresa() async {
    final empresaId = supabase.auth.currentUser?.id;
    if (empresaId == null) return {};

    final response = await supabase
        .from('jovens_aprendizes')
        .select('habilidade_destaque')
        .eq('empresa_id', empresaId);

    if (response == null || response.isEmpty) return {};

    final Map<String, int> habilidades = {
      'Adaptabilidade': 0,
      'Criatividade': 0,
      'Flexibilidade': 0,
      'Proatividade': 0,
      'Trabalho em equipe': 0,
    };

    for (final item in response) {
      final valor = (item['habilidade_destaque'] ?? '').toString().trim();
      if (habilidades.containsKey(valor)) {
        habilidades[valor] = habilidades[valor]! + 1;
      }
    }

    return habilidades;
  }

}
