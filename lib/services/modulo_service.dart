import 'package:supabase_flutter/supabase_flutter.dart';

class ModuloService {
  final supabase = Supabase.instance.client;

  // Buscar todas os modulos
  Future<List<Map<String, dynamic>>> buscarModulos(String statusModulo) async {
    final response = await supabase
        .from('modulos')
        .select('*, professores!modulos_professor_id_fkey(nome)')
        .eq('status', statusModulo);

    return response;
  }

  Future<List<Map<String, dynamic>>> buscarProfessores() async {
    final response = await supabase.from('professores').select().eq('status', 'ativo').order('nome', ascending: true);
    return response;
  }

  Future<void> inativarModulo(String id) async {
    await supabase.from('modulos').update({'status': 'inativo'}).eq('id', id);
  }

  Future<void> ativarModulo(String id) async {
    await supabase.from('modulos').update({'status': 'ativo'}).eq('id', id);
  }

  // Cadastrar uma nova modulo
  Future<String?> cadastrarModulos({
    required String nome,
    required String? turno,
    required String? dataInicio,
    required String? dataTermino,
    required String? horarioInicial,
    required String? horarioFinal,
    required String? diaSemana,
    required String? cor,
    required String professorId,
  }) async {
    try {

      await supabase.from('modulos').insert({
        'nome': nome,
        'turno': turno,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'horario_inicial': horarioInicial,
        'horario_final': horarioFinal,
        'dia_semana': diaSemana,
        'status': 'ativo',
        'cor': cor,
        'professor_id': professorId,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Atualizar modulos
  Future<String?> atualizarModulos({
    required String id,
    required String nome,
    required String? turno,
    required String? dataInicio,
    required String? dataTermino,
    required String? horarioInicial,
    required String? horarioFinal,
    required String? diaSemana,
    required String? cor,
    required String professorId,
  }) async {
    try {
      await supabase.from('modulos').update({
        'nome': nome,
        'turno': turno,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'horario_inicial': horarioInicial,
        'horario_final': horarioFinal,
        'dia_semana': diaSemana,
        'cor': cor,
        'professor_id': professorId,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
