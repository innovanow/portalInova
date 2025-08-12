import 'package:flutter/material.dart';

// Função genérica para filtrar listas
void filtrarLista({
  required String query,
  required List<Map<String, dynamic>> listaOriginal,
  required Function(List<Map<String, dynamic>>) atualizarListaFiltrada,
}) {
  if (query.isEmpty) {
    atualizarListaFiltrada(listaOriginal);
  } else {
    // Normaliza a query: se for data, extrai yyyy-MM-dd; senão, usa como texto
    String queryFormatada;
    DateTime? dataQuery = DateTime.tryParse(query);
    if (dataQuery != null) {
      queryFormatada = "${dataQuery.year.toString().padLeft(4, '0')}-"
          "${dataQuery.month.toString().padLeft(2, '0')}-"
          "${dataQuery.day.toString().padLeft(2, '0')}";
    } else {
      queryFormatada = query.toLowerCase();
    }

    List<Map<String, dynamic>> listaFiltrada = listaOriginal.where((item) {
      final nome = item["nome"]?.toString().toLowerCase() ?? '';
      final jovemNome = item["jovem_nome"]?.toString().toLowerCase() ?? '';
      final professorNome = item["professor_nome"]?.toString().toLowerCase() ?? '';
      final moduloNome = item["modulo_nome"]?.toString().toLowerCase() ?? '';
      final codigoTurma = item["codigo_turma"]?.toString().toLowerCase() ?? '';
      final dataItem = item["data"]?.toString().split(' ').first.toLowerCase() ?? '';

      return nome.contains(queryFormatada) ||
          jovemNome.contains(queryFormatada) ||
          professorNome.contains(queryFormatada) ||
          moduloNome.contains(queryFormatada) ||
          codigoTurma.contains(queryFormatada) ||
          dataItem.contains(queryFormatada);
    }).toList();

    atualizarListaFiltrada(listaFiltrada);
  }
}

void fecharPesquisa(
    Function setStateCallback,
    TextEditingController pesquisaController,
    List<Map<String, dynamic>> listaOriginal,
    Function(List<Map<String, dynamic>>) atualizarListaFiltrada,
    ) {
  setStateCallback(() {
    pesquisaController.clear();
    atualizarListaFiltrada(List.from(listaOriginal)); // 🔹 Restaura a lista completa
  });
}

