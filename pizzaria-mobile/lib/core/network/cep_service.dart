import 'dart:convert';

import 'package:http/http.dart' as http;

class CepAddress {
  const CepAddress({
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String street;
  final String neighborhood;
  final String city;
  final String state;
}

class CepService {
  const CepService();

  Future<CepAddress?> lookup(String value) async {
    final cep = value.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return null;
    final response = await http
        .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['erro'] == true) return null;
    return CepAddress(
      street: data['logradouro']?.toString() ?? '',
      neighborhood: data['bairro']?.toString() ?? '',
      city: data['localidade']?.toString() ?? '',
      state: data['uf']?.toString() ?? '',
    );
  }
}
