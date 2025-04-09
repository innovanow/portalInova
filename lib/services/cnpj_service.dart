import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String capitalizarCadaPalavra(String texto) {
  return texto.toLowerCase().split(' ').map((palavra) {
    if (palavra.isEmpty) return '';
    return palavra[0].toUpperCase() + palavra.substring(1);
  }).join(' ');
}

Future<Map<String, dynamic>?> buscarEnderecoPorCnpj(String cnpj) async {
  final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  final url = Uri.parse('https://publica.cnpj.ws/cnpj/$cnpjLimpo');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'cep': data['estabelecimento']?['cep'] ?? '',
      'endereco': data['estabelecimento']?['logradouro'] ?? '',
      'numero': data['estabelecimento']?['numero'] ?? '',
      'bairro': data['estabelecimento']?['bairro'] ?? '',
      'cidade': data['estabelecimento']?['cidade']?['nome'] ?? '',
      'uf': data['estabelecimento']?['estado']?['sigla'] ?? '',
    };
  } else {
    if (kDebugMode) {
      print('Erro ao buscar CNPJ: ${response.statusCode}');
    }
  }

  return null;
}
