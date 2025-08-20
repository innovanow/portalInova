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

  // Cadastrar um novo professor com todas as validações
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
    required String email,
    required String senha,
    required String? sexo,
    required String horaAula,
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
        'email': email,
        'senha': senha,
        'sexo': sexo,
        'valor_hora_aula': converterParaNumero(horaAula),
      };

      // 2. Invoca a Função de Borda 'cadastrar-professor'
      final response = await supabase.functions.invoke(
        'cadastrar-professor',
        body: {'professorData': professorData},
      );

      // 3. Trata a resposta da função
      if (response.status != 201) { // 201 significa 'Created'
        final responseBody = response.data;
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao cadastrar o professor.";
        return errorMessage;
      }

      // Sucesso
      return null;

    } catch (e) {
      // Trata erros de rede ou outros problemas inesperados
      return "Erro inesperado ao se comunicar com o servidor: ${e.toString()}";
    }
  }

  // Atualizar escola
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
    required String id,
    required String? sexo,
    required String horaAula,
  }) async {
    try {
      await supabase.from('professores').update({
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
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
