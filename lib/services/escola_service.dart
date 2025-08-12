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
      // 1. Monta o objeto com os dados para enviar à Edge Function
      final escolaData = {
        'nome': nome,
        'email': email,
        'senha': senha,
        'cnpj': cnpj,
        'endereco': endereco,
        'telefone': telefone,
        'numero': numero,
        'cep': cep,
        'cidade_estado': cidadeEstado,
        'bairro': bairro,
      };

      // 2. Invoca a Função de Borda 'cadastrar-escola'
      final response = await supabase.functions.invoke(
        'cadastrar-escola',
        body: {'escolaData': escolaData},
      );

      // 3. Trata a resposta da função
      if (response.status != 201) { // 201 significa 'Created'
        final responseBody = response.data;
        final errorMessage = responseBody?['error'] ?? "Erro desconhecido ao cadastrar a escola.";
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
