import 'package:supabase_flutter/supabase_flutter.dart';

class EmpresaService {
  final supabase = Supabase.instance.client;

  // Buscar todas as empresas
  Future<List<Map<String, dynamic>>> buscarEmpresas(status) async {
    final response = await supabase.from('empresas').select().eq('status', '$status').order('nome', ascending: true);
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
    required String? cidadeEstado,
    required String numero,
    required String cep,
    required String representante,
    required String bairro,
  }) async {
    try {
      // 1. Verifica se o CNPJ já existe
      final existeCnpj = await supabase
          .from('empresas')
          .select('id')
          .eq('cnpj', cnpj)
          .maybeSingle();

      if (existeCnpj != null) {
        return "CNPJ já cadastrado.";
      }

      // 2. Cria o novo usuário usando o cliente admin, sem fazer login.
      final adminUserResponse = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: senha,
          emailConfirm: true, // Já cria o usuário como confirmado
        ),
      );

      final novoUsuario = adminUserResponse.user;
      if (novoUsuario == null) {
        return "Erro ao criar o usuário de autenticação.";
      }
      final userId = novoUsuario.id;

      // 3. Insere na tabela 'users'
      await supabase.from('users').insert({
        'id': userId,
        'nome': nome,
        'email': email,
        'tipo': 'empresa',
      });

      // 4. Insere na tabela 'empresas'
      await supabase.from('empresas').insert({
        'id': userId,
        'nome': nome,
        'cnpj': cnpj,
        'endereco': endereco,
        'cidade_estado': cidadeEstado,
        'numero': numero,
        'cep': cep,
        'telefone': telefone,
        'status': 'ativo',
        'representante': representante,
        'bairro': bairro,
      });

      return null; // Sucesso
    } on AuthException catch (e) {
      // Trata erros específicos de autenticação, como email já existente
      return "Erro de autenticação: ${e.message}";
    } catch (e) {
      return "Erro inesperado ao cadastrar: ${e.toString()}";
    }
  }

  // Atualizar empresa
  Future<String?> atualizarEmpresa({
    required String id,
    required String nome,
    required String cnpj,
    required String endereco,
    required String telefone,
    required String? cidadeEstado,
    required String numero,
    required String bairro,
    required String cep,
    required String representante,
  }) async {
    try {
      await supabase.from('empresas').update({
        'nome': nome,
        'cnpj': cnpj,
        'endereco': endereco,
        'cidade_estado': cidadeEstado,
        'numero': numero,
        'cep': cep,
        'telefone': telefone,
        'representante': representante,
        'bairro': bairro,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
