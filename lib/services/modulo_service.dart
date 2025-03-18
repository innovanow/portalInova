import 'package:supabase_flutter/supabase_flutter.dart';

class ModuloService {
  final supabase = Supabase.instance.client;

  // Buscar todas os modulos
  Future<List<Map<String, dynamic>>> buscarModulos() async {
    final response = await supabase.from('modulos').select();
    return response;
  }

  // Cadastrar uma nova modulo
  Future<String?> cadastrarModulos({
    required String nome,
    required String? turno,
    required String? dataInicio,
    required String? dataTermino,
    required String? horarioInicial,
    required String? horarioFinal,
  }) async {
    try {

      await supabase.from('modulos').insert({
        'nome': nome,
        'turno': turno,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'horario_inicial': horarioInicial,
        'horario_final': horarioFinal,
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
  }) async {
    try {
      await supabase.from('modulos').update({
        'nome': nome,
        'turno': turno,
        'data_inicio': dataInicio,
        'data_termino': dataTermino,
        'horario_inicial': horarioInicial,
        'horario_final': horarioFinal,
      }).match({'id': id});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
