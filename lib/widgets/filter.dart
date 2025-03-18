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
    List<Map<String, dynamic>> listaFiltrada = listaOriginal
        .where((item) => item["nome"]
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()) ||
        item["codigo_turma"]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

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

