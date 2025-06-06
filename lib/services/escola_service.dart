import 'package:supabase_flutter/supabase_flutter.dart';

class EscolaService {
  final supabase = Supabase.instance.client;

  // Buscar todas as escolas
  Future<List<Map<String, dynamic>>> buscarescolas(status) async {
    final response = await supabase.from('escolas').select().eq('status', '$status').order('nome', ascending: true);
    return response;
  }

  Future<void> inativarEscola(String id) async {
    await supabase.from('escolas').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarEscola(String id) async {
    await supabase.from('escolas').update({'status': 'ativo'}).eq('id', id);
  }

  // Cadastrar uma nova escola
  Future<String?> cadastrarescola({
    required String nome,
    required String email,
    required String senha,
    required String cnpj,
    required String endereco,
    required String telefone,
    required String numero,
    required String cep,
    required String? cidadeEstado,
    required String bairro,
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
        'tipo': 'escola',
      });

      await supabase.from('escolas').insert({
        'id': userId,
        'nome': nome,
        'cnpj': cnpj,
        'endereco': endereco,
        'cidade_estado': cidadeEstado,
        'numero': numero,
        'cep': cep,
        'telefone': telefone,
        'status': 'ativo',
        'bairro': bairro,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Atualizar escola
  Future<String?> atualizarescola({
    required String id,
    required String nome,
    required String cnpj,
    required String endereco,
    required String telefone,
    required String? cidadeEstado,
    required String numero,
    required String cep,
    required String bairro,
  }) async {
    try {
      await supabase.from('escolas').update({
        'nome': nome,
        'cnpj': cnpj,
        'endereco': endereco,
        'cidade_estado': cidadeEstado,
        'numero': numero,
        'cep': cep,
        'telefone': telefone,
        'bairro': bairro,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
