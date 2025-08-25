import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';

class ShippingService {
  static const String _baseUrl = 'https://viacep.com.br/ws';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Calcular frete para um produto
  Future<Map<String, dynamic>> calculateShipping({
    required Product product,
    required String cep,
    String? serviceCode,
  }) async {
    try {
      // Validar CEP
      if (!_isValidCep(cep)) {
        return {
          'success': false,
          'error': 'CEP inválido',
        };
      }

      // Obter dados do CEP
      final cepData = await _getCepData(cep);
      if (cepData == null) {
        return {
          'success': false,
          'error': 'CEP não encontrado',
        };
      }

      // Calcular frete via sua API
      final shippingData = await _calculateShippingViaAPI(
        cep: cep,
        product: product,
      );

      if (shippingData['success']) {
        return {
          'success': true,
          'cep': cep,
          'address': cepData,
          'shipping': shippingData['data'],
          'delivery_time': 0, // Removido acesso direto
          'price': 0.0, // Removido acesso direto
        };
      } else {
        return {
          'success': false,
          'error': shippingData['message'] ?? 'Erro ao calcular frete',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro interno: $e',
      };
    }
  }

  // Obter CEP salvo do usuário
  Future<String?> getUserCep() async {
    try {
      if (_auth.currentUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final addresses = data?['addresses'] as List<dynamic>?;
        
        if (addresses != null && addresses.isNotEmpty) {
          // Buscar endereço padrão
          for (final address in addresses) {
            if (address['isDefault'] == true) {
              return address['cep'] as String?;
            }
          }
          
          // Se não encontrar padrão, usar o primeiro
          return addresses.first['cep'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Erro ao obter CEP do usuário: $e');
      return null;
    }
  }

  // Validar formato do CEP
  bool _isValidCep(String cep) {
    final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
    return cleanCep.length == 8;
  }

  // Obter dados do CEP via ViaCEP
  Future<Map<String, dynamic>?> _getCepData(String cep) async {
    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
      final response = await http.get(
        Uri.parse('$_baseUrl/$cleanCep/json/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == true) {
          return null;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Erro ao buscar CEP: $e');
      return null;
    }
  }

  // Calcular frete via sua API
  Future<Map<String, dynamic>> _calculateShippingViaAPI({
    required String cep,
    required Product product,
  }) async {
    try {
      // Preparar dados para a API
      final requestData = {
        'destination_cep': cep.replaceAll(RegExp(r'[^\d]'), ''),
        'items': [
          {
            'product_id': product.id,
            'quantity': 1,
            'weight': _calculateProductWeight(product),
            'price': product.preco,
            'length': _calculateProductLength(product),
            'height': _calculateProductHeight(product),
            'width': _calculateProductWidth(product),
          }
        ],
      };

      // Fazer requisição para sua API
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.shippingQuote)),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(requestData),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        // Se a API retornar erro, falhar completamente
        return {
          'success': false,
          'message': 'Erro na API de frete: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Se houver erro de conexão, falhar completamente
      return {
        'success': false,
        'message': 'Erro de conexão com API de frete: $e',
      };
    }
  }

  // Calcular peso do produto (em kg)
  double _calculateProductWeight(Product product) {
    // Se o produto tem peso definido, usar ele
    if (product.weight != null && product.weight! > 0) {
      return product.weight!;
    }
    
    // Peso padrão baseado na categoria
    switch (product.categoria.toLowerCase()) {
      case 'eletrônicos':
      case 'celulares':
      case 'computadores':
        return 0.5;
      case 'roupas':
      case 'vestuário':
        return 0.2;
      case 'casa':
      case 'decoração':
        return 1.0;
      case 'brinquedos':
        return 0.3;
      default:
        return 0.5; // Peso padrão
    }
  }

  // Calcular comprimento do produto (em cm)
  double _calculateProductLength(Product product) {
    if (product.length != null && product.length! > 0) {
      return product.length!;
    }
    
    // Comprimento padrão baseado na categoria
    switch (product.categoria.toLowerCase()) {
      case 'eletrônicos':
      case 'celulares':
        return 15.0;
      case 'computadores':
        return 30.0;
      case 'roupas':
      case 'vestuário':
        return 20.0;
      case 'casa':
      case 'decoração':
        return 25.0;
      case 'brinquedos':
        return 20.0;
      default:
        return 20.0;
    }
  }

  // Calcular altura do produto (em cm)
  double _calculateProductHeight(Product product) {
    if (product.height != null && product.height! > 0) {
      return product.height!;
    }
    
    // Altura padrão baseada na categoria
    switch (product.categoria.toLowerCase()) {
      case 'eletrônicos':
      case 'celulares':
        return 5.0;
      case 'computadores':
        return 10.0;
      case 'roupas':
      case 'vestuário':
        return 2.0;
      case 'casa':
      case 'decoração':
        return 15.0;
      case 'brinquedos':
        return 10.0;
      default:
        return 5.0;
    }
  }

  // Calcular largura do produto (em cm)
  double _calculateProductWidth(Product product) {
    if (product.width != null && product.width! > 0) {
      return product.width!;
    }
    
    // Largura padrão baseada na categoria
    switch (product.categoria.toLowerCase()) {
      case 'eletrônicos':
      case 'celulares':
        return 10.0;
      case 'computadores':
        return 20.0;
      case 'roupas':
      case 'vestuário':
        return 15.0;
      case 'casa':
      case 'decoração':
        return 20.0;
      case 'brinquedos':
        return 15.0;
      default:
        return 15.0;
    }
  }



  // Parsear tempo de entrega
  int _parseDeliveryTime(dynamic estimatedDays) {
    if (estimatedDays == null) return 0;
    if (estimatedDays is int) return estimatedDays;
    if (estimatedDays is double) return estimatedDays.toInt();
    if (estimatedDays is String) {
      final cleanDays = estimatedDays.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanDays.isEmpty) return 0;
      return int.tryParse(cleanDays) ?? 0;
    }
    return 0;
  }

  // Calcular frete grátis (se aplicável)
  bool isFreeShipping(double cartTotal, double shippingCost) {
    // Configurar valor mínimo para frete grátis
    const double freeShippingThreshold = 100.0;
    return cartTotal >= freeShippingThreshold;
  }
}


