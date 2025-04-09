import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> buscarEnderecoPorCep(String cep) async {
  final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
  final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['erro'] == true) {
      return null;
    }
    return {
      'logradouro': data['logradouro'] ?? '',
      'bairro': data['bairro'] ?? '',
      'cidade': data['localidade'] ?? '',
      'uf': data['uf'] ?? '',
    };
  } else {
    if (kDebugMode) {
      print('Erro ao buscar CEP: ${response.statusCode}');
    }
    return null;
  }
}
