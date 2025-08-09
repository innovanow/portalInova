import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessorService {
  final supabase = Supabase.instance.client;

  // Buscar todas os professores
  Future<List<Map<String, dynamic>>> buscarprofessor(String statusProfessor) async {
    final response = await supabase.from('professores').select().eq('status', statusProfessor).order('nome', ascending: true);
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
  }) async {
    try {
      // 1. Verifica se o CPF já existe
      final existeCpf = await supabase
          .from('professores')
          .select('id')
          .eq('cpf', cpf)
          .maybeSingle();

      if (existeCpf != null) {
        return "CPF já cadastrado.";
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
        'tipo': 'professor',
      });

      // 4. Insere na tabela 'professores'
      await supabase.from('professores').insert({
        'id': userId,
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
        'status': 'ativo',
        'sexo': sexo,
      });

      return null; // Sucesso

    } on AuthException catch (e) {
      // Trata erros específicos de autenticação, como email já existente
      return "Erro de autenticação: ${e.message}";
    } catch (e) {
      return "Erro inesperado ao cadastrar: ${e.toString()}";
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
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
