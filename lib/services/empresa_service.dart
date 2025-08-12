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

// Cadastrar uma nova empresa (versão segura com Edge Function)
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
      // 1. Monta o objeto com os dados para enviar à Edge Function
      final empresaData = {
        'nome': nome,
        'email': email,
        'senha': senha,
        'cnpj': cnpj,
        'endereco': endereco,
        'telefone': telefone,
        'cidade_estado': cidadeEstado,
        'numero': numero,
        'cep': cep,
        'representante': representante,
        'bairro': bairro,
      };

      // 2. Invoca a Função de Borda 'cadastrar-empresa'
      final response = await supabase.functions.invoke(
        'cadastrar-empresa',
        body: {'empresaData': empresaData},
      );

      // 3. Trata a resposta da função
      if (response.status != 201) { // 201 significa 'Created'
        final responseBody = response.data;
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao cadastrar a empresa.";
        return errorMessage;
      }

      // Sucesso
      return null;

    } catch (e) {
      // Trata erros de rede ou outros problemas inesperados
      return "Erro inesperado ao se comunicar com o servidor: ${e.toString()}";
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
