import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessorService {
  final supabase = Supabase.instance.client;

  // Buscar todas os professores
  Future<List<Map<String, dynamic>>> buscarprofessor(String statusProfessor) async {
    final response = await supabase
        .from('professores')
        .select()
        .eq('status', statusProfessor)
        .not('nome', 'eq', 'Não Definido')
        .order('nome', ascending: true);
    return response;
  }

  Future<void> inativarProfessor(String id) async {
    await supabase.from('professores').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarProfessor(String id) async {
    await supabase.from('professores').update({'status': 'ativo'}).eq('id', id);
  }

  double converterParaNumero(String valor) {
    // Remove tudo que não for número ou vírgula e substitui ',' por '.'
    String numeroLimpo = valor.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    return double.tryParse(numeroLimpo) ?? 0.0;
  }

  Future<String?> atualizarprofessor({
    required String nome,
    required String? dataNascimento,
    required String endereco,
    required String numero,
    required String bairro,
    required String? cidadeEstado,
    required String cep,
    required String telefone,
    required String formacao,
    required String cpf,
    required String rg,
    required String codCarteiraTrabalho,
    required String? estadoCivil,
    required String? nacionalidade,
    required String? cidadeEstadoNatal,
    required String id, // O ID é recebido como parâmetro
    required String? sexo,
    required String horaAula,
    required String horaAula2,
    required bool? interno,
    required String? idColegio,
  }) async {
    // Adicionamos uma verificação para dar um erro mais claro caso o ID esteja vazio
    if (id.isEmpty) {
      return "Erro Crítico: Tentativa de atualizar um professor sem fornecer um ID.";
    }

    try {
      // 1. Monta o objeto com os dados, ASSIM COMO NA FUNÇÃO DE CADASTRO
      final professorUpdateData = {
        'id': id, // A INCLUSÃO DO ID É A CHAVE PARA A ATUALIZAÇÃO!
        'nome': nome,
        'data_nascimento': dataNascimento,
        'cpf': cpf,
        'rg': rg,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil': estadoCivil,
        'endereco': endereco,
        'cidade_estado': cidadeEstado,
        'numero': numero,
        'bairro': bairro,
        'cep': cep,
        'telefone': telefone,
        'formacao': formacao,
        'nacionalidade': nacionalidade,
        'cidade_natal': cidadeEstadoNatal,
        'sexo': sexo,
        'valor_hora_aula': converterParaNumero(horaAula),
        'interno': interno,
        'id_colegio': idColegio == "" ? null : idColegio,
        'valor_hora_aula2': converterParaNumero(horaAula2),
      };

      // 2. Invoca a MESMA Edge Function usada para o cadastro
      final response = await supabase.functions.invoke(
        'cadastrar-professor',
        body: {'professorData': professorUpdateData},
      );

      // 3. Trata a resposta (sucesso para atualização é o status 200 OK)
      if (response.status != 200) {
        final responseBody = response.data;
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao atualizar o professor.";
        return errorMessage;
      }

      // Sucesso
      return null;

    } catch (e) {
      return "Erro inesperado ao se comunicar com o servidor: ${e.toString()}";
    }
  }

  Future<String?> cadastrarprofessor({
    required String nome,
    required String? dataNascimento,
    required String endereco,
    required String numero,
    required String bairro,
    required String? cidadeEstado,
    required String cep,
    required String telefone,
    required String formacao,
    required String cpf,
    required String rg,
    required String codCarteiraTrabalho,
    required String? estadoCivil,
    required String? nacionalidade,
    required String? cidadeEstadoNatal,
    required String email, // <-- CAMPO RESTAURADO
    required String senha, // <-- CAMPO RESTAURADO
    required String? sexo,
    required String horaAula,
    required String horaAula2,
    required bool? interno,
    required String? idColegio,
  }) async {
    try {
      // 1. Monta o objeto com os dados para enviar à Edge Function
      final professorData = {
        'nome': nome,
        'data_nascimento': dataNascimento,
        'endereco': endereco,
        'numero': numero,
        'bairro': bairro,
        'cidade_estado': cidadeEstado,
        'cep': cep,
        'telefone': telefone,
        'formacao': formacao,
        'cpf': cpf,
        'rg': rg,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil': estadoCivil,
        'nacionalidade': nacionalidade,
        'cidade_natal': cidadeEstadoNatal,
        'email': email, // <-- CAMPO INCLUÍDO NO OBJETO
        'senha': senha, // <-- CAMPO INCLUÍDO NO OBJETO
        'sexo': sexo,
        'valor_hora_aula': converterParaNumero(horaAula),
        'interno': interno,
        'id_colegio': idColegio,
        'valor_hora_aula2': converterParaNumero(horaAula2),
      };

      // 2. Invoca a Função de Borda
      final response = await supabase.functions.invoke(
        'cadastrar-professor',
        body: {'professorData': professorData},
      );

      // 3. Trata a resposta (201 Created)
      if (response.status != 201) {
        final responseBody = response.data;
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao cadastrar o professor.";
        return errorMessage;
      }
      return null; // Sucesso
    } catch (e) {
      return "Erro inesperado ao se comunicar com o servidor: ${e.toString()}";
    }
  }
}
