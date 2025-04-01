import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessorService {
  final supabase = Supabase.instance.client;

  // Buscar todas os professores
  Future<List<Map<String, dynamic>>> buscarprofessor(statusProfessor) async {
    final response = await supabase.from('professores').select().eq('status', '$statusProfessor');
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

  // Cadastrar um novo professor
  Future<String?> cadastrarprofessor({
    required String nome,
    required String? dataNascimento,
    required String endereco,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
    required String telefone,
    required String formacao,
    required String cpf,
    required String rg,
    required String codCarteiraTrabalho,
    required String estadoCivil,
    required String pais,
    required String cidadeNatal,
    required String email,
    required String senha,
  }) async {
    try {

      final response = await supabase.auth.signUp(
        email: email,
        password: senha,
      );

      final userId = response.user?.id;
      if (userId == null) return "Erro ao criar usuário.";

      await supabase.from('users').insert({
        'id': userId,
        'nome': nome,
        'email': email,
        'tipo': 'professor',
      });


      await supabase.from('professores').insert({
        'id': userId,
        'nome': nome,
        'data_nascimento': dataNascimento,
        'cpf': cpf,
        'rg': rg,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil': estadoCivil,
        'endereco': endereco,
        'cidade': cidade,
        'estado': estado,
        'numero': numero,
        'bairro': bairro,
        'cep': cep,
        'telefone': telefone,
        'formacao': formacao,
        'pais': pais,
        'cidade_natal': cidadeNatal,
        'status': 'ativo',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Atualizar escola
  Future<String?> atualizarprofessor({
    required String nome,
    required String? dataNascimento,
    required String endereco,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
    required String telefone,
    required String formacao,
    required String cpf,
    required String rg,
    required String codCarteiraTrabalho,
    required String estadoCivil,
    required String pais,
    required String cidadeNatal,
    required String id,
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
        'cidade': cidade,
        'estado': estado,
        'numero': numero,
        'bairro': bairro,
        'cep': cep,
        'telefone': telefone,
        'formacao': formacao,
        'pais': pais,
        'cidade_natal': cidadeNatal,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
