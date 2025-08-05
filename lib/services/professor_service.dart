import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessorService {
  final supabase = Supabase.instance.client;

  // Buscar todas os professores
  Future<List<Map<String, dynamic>>> buscarprofessor(statusProfessor) async {
    final response = await supabase.from('professores').select().eq('status', '$statusProfessor').order('nome', ascending: true);
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
      final supabase = Supabase.instance.client;

      // 1. Verifica se o CPF já está cadastrado na tabela 'professores'
      final existeCpf = await supabase
          .from('professores')
          .select('id')
          .eq('cpf', cpf)
          .maybeSingle();

      if (existeCpf != null) {
        return "Este CPF já está cadastrado para um professor.";
      }

      // 2. Verifica se o perfil do usuário já existe na tabela 'users'
      final userDB = await supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      String userId;

      if (userDB != null) {
        // Se o perfil já existe na nossa tabela 'users', usamos o ID dele.
        userId = userDB['id'];
      } else {
        // Se não existe na tabela 'users', vamos verificar no sistema de autenticação (Auth)
        try {
          // 3. Tenta fazer login. Se funcionar, o usuário já existe no Auth.
          final login = await supabase.auth.signInWithPassword(
            email: email,
            password: senha,
          );
          userId = login.user?.id ?? '';
          if (userId.isEmpty) return "Erro ao recuperar ID de usuário existente.";

        } catch (_) {
          // 4. Se o login falhar, o usuário é realmente novo. Criamos no Auth.
          final signUpResp = await supabase.auth.signUp(
            email: email,
            password: senha,
          );
          userId = signUpResp.user?.id ?? '';
          if (userId.isEmpty) {
            return "Erro ao criar o novo usuário no sistema de autenticação.";
          }
        }

        // 5. Com o ID do Auth em mãos, inserimos o perfil na tabela 'users'
        //    Isso só acontece se ele não existia lá antes.
        try {
          await supabase.from('users').insert({
            'id': userId,
            'nome': nome,
            'email': email,
            'tipo': 'professor', // Define o tipo de usuário corretamente
          });
        } catch (e) {
          // Ignora o erro se a chave for duplicada (caso de uma condição de corrida)
          // mas reporta qualquer outro erro.
          if (!e.toString().contains("duplicate key")) {
            return "Erro ao salvar o perfil do usuário: $e";
          }
        }
      }

      // 6. Agora que temos um userId válido, inserimos os dados na tabela 'professores'
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
        'cidade_natal': cidadeEstadoNatal, // Atenção: Verifique se o nome da coluna no DB é 'cidade_natal'
        'status': 'ativo',
        'sexo': sexo,
      });

      // Se todas as etapas foram concluídas com sucesso, retorna null (sem erro)
      return null;

    } catch (e) {
      // Trata erros de forma mais amigável para o usuário final
      if (e is AuthException) {
        if (e.message.contains("User already registered")) {
          return "Este e-mail já está cadastrado. Tente fazer login ou use um e-mail diferente.";
        }
        if (e.message.contains("Password should be at least 6 characters")) {
          return "A senha deve ter no mínimo 6 caracteres.";
        }
        return "Erro de autenticação: ${e.message}";
      }
      return "Ocorreu um erro inesperado: ${e.toString()}";
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
