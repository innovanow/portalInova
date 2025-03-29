import 'package:supabase_flutter/supabase_flutter.dart';

class JovemService {
  final supabase = Supabase.instance.client;

  // Buscar todas os jovens
  Future<List<Map<String, dynamic>>> buscarjovem() async {
    final response = await supabase.from('jovens_aprendizes').select().eq('status', 'ativo');
    return response;
  }

  Future<void> inativarJovem(String id) async {
    await supabase.from('jovens_aprendizes').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarJovem(String id) async {
    await supabase.from('jovens_aprendizes').update({'status': 'ativo'}).eq('id', id);
  }

  double converterParaNumero(String valor) {
    // Remove tudo que não for número ou vírgula e substitui ',' por '.'
    String numeroLimpo = valor.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    return double.tryParse(numeroLimpo) ?? 0.0;
  }

  // Cadastrar um novo jovem
  Future<String?> cadastrarjovem({
    required String nome,
    required String? dataNascimento,
    required String nomePai,
    required String nomeMae,
    required String endereco,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
    required String telefoneJovem,
    required String telefonePai,
    required String telefoneMae,
    required String? escola,
    required String? empresa,
    required String escolaridade,
    required String email,
    required String senha,
    required String cpf,
    required String cpfMae,
    required String cpfPai,
    required String rg,
    required String rgMae,
    required String rgPai,
    required String pais,
    required String cidadeNatal,
    required String codCarteiraTrabalho,
    required String estadoCivilPai,
    required String estadoCivilMae,
    required String remuneracao,
    required String horasTrabalho,
    required String horasCurso,
    required String horasSemanais,
    required String areaAprendizado,
    required String? turma,
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
        'tipo': 'jovem_aprendiz',
      });

      await supabase.from('jovens_aprendizes').insert({
        'id': userId,
        'nome': nome,
        'data_nascimento': dataNascimento,
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'endereco': endereco,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'telefone_jovem': telefoneJovem,
        'telefone_pai': telefonePai,
        'telefone_mae': telefoneMae,
        'escola_id': escola,
        'empresa_id': empresa,
        'escolaridade': escolaridade,
        'cpf': cpf,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
        'horas_curso': horasCurso,
        'horas_semanais': horasSemanais,
        'area_aprendizado': areaAprendizado,
        'rg': rg,
        'pais': pais,
        'cidade_natal': cidadeNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'cpf_pai': cpfPai,
        'cpf_mae': cpfMae,
        'rg_pai': rgPai,
        'rg_mae': rgMae,
        'turma_id': turma,
        'status': 'ativo',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Atualizar escola
  Future<String?> atualizarjovem({
    required String nome,
    required String endereco,
    required String cidade,
    required String estado,
    required String numero,
    required String cep,
    required String escolaridade,
    required String? dataNascimento,
    required String nomePai,
    required String nomeMae,
    required String telefoneJovem,
    required String telefonePai,
    required String telefoneMae,
    required String? escola,
    required String? empresa,
    required String bairro,
    required String id,
    required String cpf,
    required String remuneracao,
    required String horasTrabalho,
    required String horasCurso,
    required String horasSemanais,
    required String areaAprendizado,
    required String rg,
    required String pais,
    required String cidadeNatal,
    required String codCarteiraTrabalho,
    required String estadoCivilPai,
    required String estadoCivilMae,
    required String cpfPai,
    required String cpfMae,
    required String rgPai,
    required String rgMae,
    String? turma,
  }) async {
    try {
      await supabase.from('jovens_aprendizes').update({
        'nome': nome,
        'data_nascimento': dataNascimento,
        'nome_pai': nomePai,
        'nome_mae': nomeMae,
        'endereco': endereco,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'telefone_jovem': telefoneJovem,
        'telefone_pai': telefonePai,
        'telefone_mae': telefoneMae,
        'escola_id': escola,
        'empresa_id': empresa,
        'escolaridade': escolaridade,
        'cpf': cpf,
        'remuneracao': converterParaNumero(remuneracao),
        'horas_trabalho': horasTrabalho,
        'horas_curso': horasCurso,
        'horas_semanais': horasSemanais,
        'area_aprendizado': areaAprendizado,
        'rg': rg,
        'pais': pais,
        'cidade_natal': cidadeNatal,
        'cod_carteira_trabalho': codCarteiraTrabalho,
        'estado_civil_pai': estadoCivilPai,
        'estado_civil_mae': estadoCivilMae,
        'cpf_pai': cpfPai,
        'cpf_mae': cpfMae,
        'rg_pai': rgPai,
        'rg_mae': rgMae,
        'turma_id': turma,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  // Buscar escolas para o dropdown
  Future<List<Map<String, dynamic>>> buscarEscolas() async {
    final response = await supabase.from('escolas').select().eq('status', 'ativo');
    return response;
  }

  // Buscar empresas para o dropdown
  Future<List<Map<String, dynamic>>> buscarEmpresas() async {
    final response = await supabase.from('empresas').select().eq('status', 'ativo');
    return response;
  }

  // Buscar turmas para o dropdown
  Future<List<Map<String, dynamic>>> buscarTurmas() async {
    final response = await supabase.from('turmas').select().eq('status', 'ativo');
    return response;
  }
}
