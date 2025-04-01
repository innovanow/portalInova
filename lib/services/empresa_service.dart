import 'package:supabase_flutter/supabase_flutter.dart';

class EmpresaService {
  final supabase = Supabase.instance.client;

  // Buscar todas as empresas
  Future<List<Map<String, dynamic>>> buscarEmpresas(status) async {
    final response = await supabase.from('empresas').select().eq('status', '$status');
    return response;
  }

 Future<void> inativarEmpresa(String id) async {
  await supabase.from('empresas').update({'status': 'inativo'}).eq('id', id);
 }

  Future<void> ativarEmpresa(String id) async {
    await supabase.from('empresas').update({'status': 'ativo'}).eq('id', id);
  }

  // Cadastrar uma nova empresa
  Future<String?> cadastrarEmpresa({
    required String nome,
    required String email,
    required String senha,
    required String cnpj,
    required String endereco,
    required String telefone,
    required String estado,
    required String numero,
    required String cep,
    required String cidade,
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
        'tipo': 'empresa',
      });

      await supabase.from('empresas').insert({
        'id': userId,
        'nome': nome,
        'cnpj': cnpj,
        'endereco': endereco,
        'cidade': cidade,
        'estado': estado,
        'numero': numero,
        'cep': cep,
        'telefone': telefone,
        'status': 'ativo',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Atualizar empresa
  Future<String?> atualizarEmpresa({
    required String id,
    required String nome,
    required String cnpj,
    required String endereco,
    required String telefone,
    required String cidade,
    required String estado,
    required String numero,
    required String cep,
  }) async {
    try {
      await supabase.from('empresas').update({
        'nome': nome,
        'cnpj': cnpj,
        'endereco': endereco,
        'cidade': cidade,
        'estado': estado,
        'numero': numero,
        'cep': cep,
        'telefone': telefone,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
