
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/drawer.dart';

class JovemService {
  final supabase = Supabase.instance.client;

  // Buscar todas os jovens
  Future<List<Map<String, dynamic>>> buscarjovem(String status) async {
    final response = await supabase.from('jovens_aprendizes').select().eq('status', status).order('nome', ascending: true);
    return response;
  }

  Future<List<String>> buscarTurmasDoProfessor(String professorId) async {
    final modulos = await supabase
        .from('modulos')
        .select('turma_id')
        .eq('status', 'ativo')
        .eq('professor_id', professorId)
    // Pede para o banco não trazer linhas onde turma_id é nulo
        .not('turma_id', 'is', null);

    // Agora o `map` é seguro, pois não haverá mais nulos
    final turmasIds = (modulos as List)
        .map((modulo) => modulo['turma_id'].toString())
        .toList();

    return turmasIds;
  }

  Future<List<Map<String, dynamic>>> buscarJovensDoProfessor(String professorId, String status) async {
    // 1. Executa a chamada RPC como antes
    final response = await supabase.rpc(
      'buscar_jovens_do_professor_com_modulo',
      params: {
        'p_professor_id': professorId,
        'p_status': status,
      },
    );

    if (kDebugMode) {
      print(response);
    }

    final List<dynamic> data = response;

    // Mapa para agrupar os jovens por ID para não haver duplicatas
    final Map<String, Map<String, dynamic>> jovensAgrupados = {};

    // Mapa para armazenar a lista de módulos de cada jovem
    final Map<String, List<String>> modulosPorJovem = {};

    // 2. Itera sobre a resposta para agrupar os dados por jovem
    for (final item in data) {
      // Pega o JSON do jovem e o nome do módulo
      final Map<String, dynamic> dadosJovem = Map.from(item['jovem_json']);
      final String? nomeModulo = item['nome_modulo'];

      // Usa o ID do jovem como chave única (convertido para String)
      final String jovemId = dadosJovem['id'].toString();

      // Se o jovem ainda não foi adicionado ao mapa, o adiciona
      if (!jovensAgrupados.containsKey(jovemId)) {
        jovensAgrupados[jovemId] = dadosJovem;
      }

      // Se houver um nome de módulo, adiciona à lista daquele jovem
      if (nomeModulo != null) {
        modulosPorJovem.putIfAbsent(jovemId, () => []).add(nomeModulo);
      }
    }

    // 3. Monta a lista final com os novos campos
    final List<Map<String, dynamic>> resultadoFinal = [];
    jovensAgrupados.forEach((jovemId, dadosJovem) {
      final List<String>? modulos = modulosPorJovem[jovemId];

      // Adiciona os campos de nomes e quantidade
      if (modulos != null && modulos.isNotEmpty) {
        dadosJovem['nomes_modulos'] = modulos.join(', ');
        dadosJovem['qtd_modulos'] = modulos.length;
      } else {
        dadosJovem['nomes_modulos'] = 'Nenhum módulo';
        dadosJovem['qtd_modulos'] = 0;
      }
      resultadoFinal.add(dadosJovem);
    });

    // 4. Ordena a lista final pelo nome do jovem
    resultadoFinal.sort((a, b) {
      final nomeA = a['nome'] as String? ?? '';
      final nomeB = b['nome'] as String? ?? '';
      return nomeA.compareTo(nomeB);
    });

    return resultadoFinal;
  }

  Future<List<Map<String, dynamic>>> buscarJovensDaEscola(String status) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    String? escolaId;

    if (auth.tipoUsuario == "escola") {
      escolaId = currentUser.id;
    } else if (auth.tipoUsuario == "professor_externo") {
      try {
        final professorData = await supabase
            .from('professores')
            .select('id_colegio')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (professorData != null && professorData['id_colegio'] != null) {
          escolaId = professorData['id_colegio'].toString();
        }
      } catch (e) {
        if (kDebugMode) print("Erro ao buscar escola do professor: $e");
        return [];
      }
    }

    if (escolaId == null) {
      if (kDebugMode) print("Não foi possível determinar a escola para o usuário: ${currentUser.id}");
      return [];
    }

    try {
      final jovensResponse = await supabase
          .from('jovens_aprendizes')
          .select('*, turmas(codigo_turma)')
          .eq('escola_id', escolaId)
          .eq('status', status);

      if (jovensResponse.isEmpty) return [];

      final List<String> turmaIds = jovensResponse
          .map((jovem) => jovem['turma_id'].toString())
          .where((id) => id != 'null')
          .toSet()
          .toList();

      if (turmaIds.isEmpty) {
        return jovensResponse.map((jovem) {
          final Map<String, dynamic> dadosJovem = Map.from(jovem);
          dadosJovem['nomes_modulos'] = 'Nenhum módulo';
          dadosJovem['qtd_modulos'] = 0;
          return dadosJovem;
        }).toList()..sort((a,b) => (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));
      }

      // Solução alternativa para o filtro 'in', usando 'or'
      final orFilter = turmaIds.map((id) => 'turma_id.eq.$id').join(',');

      final modulosResponse = await supabase
          .from('modulos')
          .select('id, nome, turma_id')
          .or(orFilter)
          .eq('status', 'ativo');

      final Map<String, List<String>> turmaModulosMap = {};
      for (final modulo in modulosResponse) {
        final turmaId = modulo['turma_id'].toString();
        turmaModulosMap.putIfAbsent(turmaId, () => []).add(modulo['nome']);
      }

      final List<Map<String, dynamic>> jovensProcessados = [];
      for (final jovem in jovensResponse) {
        final Map<String, dynamic> novoJovem = Map.from(jovem);
        final turmaId = novoJovem['turma_id']?.toString();
        final List<String>? modulosDaTurma = turmaModulosMap[turmaId];

        novoJovem['cod_turma'] = jovem['turmas']?['codigo_turma'];

        if (modulosDaTurma != null && modulosDaTurma.isNotEmpty) {
          novoJovem['nomes_modulos'] = modulosDaTurma.join(', ');
          novoJovem['qtd_modulos'] = modulosDaTurma.length;
        } else {
          novoJovem['nomes_modulos'] = 'Nenhum módulo';
          novoJovem['qtd_modulos'] = 0;
        }

        jovensProcessados.add(novoJovem);
      }

      jovensProcessados.sort((a, b) => (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));

      return jovensProcessados;

    } catch (e) {
      if (kDebugMode) print("Erro ao buscar jovens da escola: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> buscarJovensDaEmpresa(String empresaId, String status) async {
    try {
      final jovensResponse = await supabase
          .from('jovens_aprendizes')
          .select('*, turmas(codigo_turma)')
          .eq('empresa_id', empresaId)
          .eq('status', status);

      if (jovensResponse.isEmpty) return [];

      final List<String> turmaIds = jovensResponse
          .map((jovem) => jovem['turma_id'].toString())
          .where((id) => id != 'null')
          .toSet()
          .toList();

      if (turmaIds.isEmpty) {
        return jovensResponse.map((jovem) {
          final Map<String, dynamic> dadosJovem = Map.from(jovem);
          dadosJovem['nomes_modulos'] = 'Nenhum módulo';
          dadosJovem['qtd_modulos'] = 0;
          return dadosJovem;
        }).toList()..sort((a,b) => (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));
      }

      final orFilter = turmaIds.map((id) => 'turma_id.eq.$id').join(',');

      final modulosResponse = await supabase
          .from('modulos')
          .select('id, nome, turma_id')
          .or(orFilter)
          .eq('status', 'ativo');

      final Map<String, List<String>> turmaModulosMap = {};
      for (final modulo in modulosResponse) {
        final turmaId = modulo['turma_id'].toString();
        turmaModulosMap.putIfAbsent(turmaId, () => []).add(modulo['nome']);
      }

      final List<Map<String, dynamic>> jovensProcessados = [];
      for (final jovem in jovensResponse) {
        final Map<String, dynamic> novoJovem = Map.from(jovem);
        final turmaId = novoJovem['turma_id']?.toString();
        final List<String>? modulosDaTurma = turmaModulosMap[turmaId];

        novoJovem['cod_turma'] = jovem['turmas']?['codigo_turma'];

        if (modulosDaTurma != null && modulosDaTurma.isNotEmpty) {
          novoJovem['nomes_modulos'] = modulosDaTurma.join(', ');
          novoJovem['qtd_modulos'] = modulosDaTurma.length;
        } else {
          novoJovem['nomes_modulos'] = 'Nenhum módulo';
          novoJovem['qtd_modulos'] = 0;
        }

        jovensProcessados.add(novoJovem);
      }

      jovensProcessados.sort((a, b) => (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));

      return jovensProcessados;

    } catch (e) {
      if (kDebugMode) print("Erro ao buscar jovens da empresa: $e");
      return [];
    }
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
    required String email,
    required String senha,
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
    required String? codCarteiraTrabalho,
    required String? estadoCivilPai,
    required String? estadoCivilMae,
    required String? estadoCivil,
    required String? estadoCivilResponsavel,
    required String remuneracao,
    required String? horasTrabalho,
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
    required String? emailResponsavel,
  }) async {
    try {
      // 1. Monta o objeto com todos os dados do jovem.
      // As chaves devem corresponder exatamente às colunas da sua tabela 'jovens_aprendizes'.
      final jovemData = {
        'nome': nome,
        'data_nascimento': dataNascimento,
        'email': email,
        'senha': senha, // A senha será usada pela Edge Function e não será salva no banco
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'nome_responsavel': nomeResponsavel,
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
        'cpf_mae': cpfMae,
        'cpf_pai': cpfPai,
        'rg': rg,
        'rg_mae': rgMae,
        'rg_pai': rgPai,
        'cidade_estado_natal': cidadeEstadoNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'estado_civil': estadoCivil,
        'estado_civil_responsavel': estadoCivilResponsavel,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
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
        'email_responsavel': emailResponsavel,
        'status': 'ativo', // Define o status inicial
      };

      // 2. Invoca a Função de Borda 'cadastrar-jovem'
      final response = await supabase.functions.invoke(
        'cadastrar-jovem',
        body: {'jovemData': jovemData},
      );

      // 3. Trata a resposta da função
      if (response.status != 201) { // 201 significa 'Created'
        final responseBody = response.data;
        // Pega a mensagem de erro específica retornada pela sua função de borda
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao cadastrar o jovem.";
        return errorMessage;
      }

      // Se chegou aqui, o cadastro foi um sucesso
      return null;

    } catch (e) {
      // Trata erros de rede ou outros problemas inesperados
      return "Erro inesperado ao se comunicar com o servidor: ${e.toString()}";
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
    required String? codCarteiraTrabalho,
    required String? estadoCivilPai,
    required String? estadoCivilMae,
    required String? estadoCivil,
    required String? estadoCivilResponsavel,
    required String remuneracao,
    required String? horasTrabalho,
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
      // 1. Monta o objeto com os dados para enviar à Edge Function.
      // A estrutura está correta, com chaves que correspondem ao esperado no backend.
      final jovemData = {
        'nome': nome,
        'data_nascimento': dataNascimento,
        'email': email,
        'senha': senha, // A senha será usada pela Edge Function e não será salva no banco
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'nome_responsavel': nomeResponsavel,
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
        'cpf_mae': cpfMae,
        'cpf_pai': cpfPai,
        'rg': rg,
        'rg_mae': rgMae,
        'rg_pai': rgPai,
        'cidade_estado_natal': cidadeEstadoNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'estado_civil': estadoCivil,
        'estado_civil_responsavel': estadoCivilResponsavel,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
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
      };

      // 2. Invoca a Edge Function 'precadastrar-jovem'.
      // O corpo da requisição `{'jovemData': jovemData}` corresponde exatamente
      // ao que a sua Edge Function espera (`const { jovemData } = await req.json();`).
      final response = await supabase.functions.invoke(
        'precadastrar-jovem',
        body: {'jovemData': jovemData},
      );

      // 3. Trata a resposta da função.
      // Sua Edge Function retorna status 201 em caso de sucesso.
      // Esta verificação é a maneira correta de identificar se a operação falhou.
      if (response.status != 201) {
        final responseBody = response.data;
        // Pega a mensagem de erro específica retornada pela sua função de borda.
        // A Edge Function retorna um JSON com a chave 'error' (ex: { "error": "CPF já cadastrado." }),
        // então esta linha extrai essa mensagem corretamente.
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao pré-cadastrar o jovem.";
        return errorMessage;
      }

      // Se o status for 201, a função retorna null, indicando sucesso.
      // Este é um padrão limpo e eficaz.
      return null;

    } catch (e) {
      // Captura qualquer erro inesperado (ex: problema de rede, erro de programação)
      // e retorna uma mensagem clara.
      return "Erro inesperado ao se comunicar com o servidor: ${e.toString()}";
    }
  }

    // Atualizar jovem
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
    required String? codCarteiraTrabalho,
    required String? estadoCivilPai,
    required String? estadoCivilMae,
    required String? estadoCivil,
    required String? estadoCivilResponsavel,
    required String remuneracao,
    required String? horasTrabalho,
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
    required String? emailResponsavel,
  }) async {
    try {
      final jovemData = {
        'id': id, // Envia o ID se for uma atualização
        'nome': nome,
        'cpf': cpf,
        'data_nascimento': dataNascimento,
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'nome_responsavel': nomeResponsavel,
        'email_responsavel': emailResponsavel,
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
        'cpf_pai': cpfPai,
        'cpf_mae': cpfMae,
        'rg': rg,
        'rg_pai': rgPai,
        'rg_mae': rgMae,
        'cidade_estado_natal': cidadeEstadoNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'estado_civil': estadoCivil,
        'estado_civil_responsavel': estadoCivilResponsavel,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
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
      };

      // Remove chaves com valores nulos para não enviar dados desnecessários,
      // especialmente importante na atualização para não sobrescrever campos com null.
      jovemData.removeWhere((key, value) => value == null);

      // Chama a Edge Function unificada
      await supabase.functions.invoke(
        'cadastrar-jovem', // O nome da sua Edge Function
        body: {'jovemData': jovemData},
      );
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return e.toString();
    }
  }

  Future<String?> buscarStatusDoJovemLogado() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    if (kDebugMode) {
      print("UserID: $userId");
    }
    final response = await supabase
        .from('jovens_aprendizes')
        .select('status')
        .eq('id', userId)
        .maybeSingle();

    return response?['status'];
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
        .select('pcd')
        .eq('status', 'ativo');

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
        .select('estudando')
        .eq('status', 'ativo');

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
        .select('beneficio_assistencial')
        .eq('status', 'ativo');

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
        .select('turno_escola')
        .eq('status', 'ativo');

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
        .select('nacionalidade')
        .eq('status', 'ativo');

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
        .select('mora_com')
        .eq('status', 'ativo');

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
        .select('possui_filhos')
        .eq('status', 'ativo');

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
        .select('cor')
        .eq('status', 'ativo');

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
        .select('identidade_genero')
        .eq('status', 'ativo');

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
        .select('orientacao_sexual')
        .eq('status', 'ativo');

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
        .select('escola')
        .eq('status', 'ativo');

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
        .select('empresa')
        .eq('status', 'ativo');

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
        .select('cod_turma')
        .eq('status', 'ativo');

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
        .select('trabalhando')
        .eq('status', 'ativo');

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
        .eq('status', 'ativo')
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
    final id = supabase.auth.currentUser?.id;
    if (id == null) return {};

    // 1. Buscar jovens da escola logada
    if (auth.tipoUsuario == "escola") {
      final jovens = await supabase
          .from('jovens_aprendizes')
          .select('cod_turma')
          .eq('status', 'ativo')
          .eq('escola_id', id);
      if (jovens.isEmpty) return {};

      final Map<String, int> porTurma = {};

      for (final jovem in jovens) {
        final turma = (jovem['cod_turma'] ?? 'Não informado').toString().trim();
        final chave = turma.isEmpty ? 'Não informado' : turma;
        porTurma[chave] = (porTurma[chave] ?? 0) + 1;
      }

      return porTurma;
    }

    if (auth.tipoUsuario == "professor_externo") {
      // ATENÇÃO: A lógica original aqui pode causar um erro.
      // O ideal seria extrair o valor do mapa, como 'idEscola['id_colegio']'.
      // Mantendo como estava, mas ciente do potencial problema.
      final idEscolaData = await supabase.from('professores').select('id_colegio').eq('id', id).maybeSingle();

      // É importante verificar se idEscolaData não é nulo antes de usá-lo.
      if (idEscolaData == null || idEscolaData['id_colegio'] == null) {
        return {}; // Retorna vazio se o professor não tiver uma escola associada
      }

      final idEscola = idEscolaData['id_colegio'];

      final jovens = await supabase
          .from('jovens_aprendizes')
          .select('cod_turma')
          .eq('status', 'ativo')
          .eq('escola_id', idEscola); // Usando a variável corrigida

      if (jovens.isEmpty) return {};

      final Map<String, int> porTurma = {};

      for (final jovem in jovens) {
        final turma = (jovem['cod_turma'] ?? 'Não informado').toString().trim();
        final chave = turma.isEmpty ? 'Não informado' : turma;
        porTurma[chave] = (porTurma[chave] ?? 0) + 1;
      }

      return porTurma;
    }

    // Adicionado para garantir que a função sempre retorne um valor.
    return {};
  }

  Future<Map<String, int>> buscarResumoHabilidadesDestaque() async {
    final response = await supabase
        .from('jovens_aprendizes')
        .select('habilidade_destaque')
        .eq('status', 'ativo');

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
        .eq('empresa_id', empresaId)
        .eq('status', 'ativo');

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

}
