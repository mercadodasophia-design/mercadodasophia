import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  static const String _baseUrl = 'https://viacep.com.br/ws';

  /// Busca endereço pelo CEP usando a API ViaCEP
  static Future<Map<String, dynamic>?> searchCep(String cep) async {
    try {
      // Limpar CEP (remover caracteres não numéricos)
      final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanCep.length != 8) {
        throw Exception('CEP deve ter 8 dígitos');
      }

      final url = '$_baseUrl/$cleanCep/json/';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar se o CEP foi encontrado
        if (data['erro'] == true) {
          return null; // CEP não encontrado
        }

        return {
          'cep': data['cep'],
          'logradouro': data['logradouro'],
          'bairro': data['bairro'],
          'localidade': data['localidade'],
          'uf': data['uf'],
          'ibge': data['ibge'],
          'ddd': data['ddd'],
        };
      } else {
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar CEP: $e');
    }
  }

  /// Formata CEP para exibição (00000-000)
  static String formatCep(String cep) {
    final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCep.length == 8) {
      return '${cleanCep.substring(0, 5)}-${cleanCep.substring(5)}';
    }
    return cep;
  }

  /// Valida formato do CEP
  static bool isValidCep(String cep) {
    final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
    return cleanCep.length == 8;
  }
}
