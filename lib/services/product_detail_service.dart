import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailService {
  static const String baseUrl = 'https://mercadodasophia-api.onrender.com';

  /// Buscar detalhes completos de um produto
  static Future<Map<String, dynamic>> getCompleteProductDetails(String itemId) async {
    try {
      print('🔍 Buscando detalhes completos do produto: $itemId');
      
      // Obter token de autenticação
      String? authToken;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          authToken = await user.getIdToken();
          print('✅ Token de autenticação obtido');
        } else {
          print('⚠️ Usuário não autenticado');
        }
      } catch (e) {
        print('❌ Erro ao obter token: $e');
      }
      
      // Preparar headers
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        print('🔐 Token incluído nos headers');
      }
      
      // Chamar API de detalhes do produto
      final detailsResponse = await http.get(
        Uri.parse('$baseUrl/api/aliexpress/product/$itemId'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      Map<String, dynamic> productDetails = {};
      Map<String, dynamic> freightInfo = {};

      // Processar resposta dos detalhes
      if (detailsResponse.statusCode == 200) {
        final detailsData = json.decode(detailsResponse.body);
        
        // LOG DETALHADO DA RESPOSTA COMPLETA
        print('🔍 === RESPOSTA COMPLETA DA API DE DETALHES ===');
        print('Status Code: ${detailsResponse.statusCode}');
        print('Content-Type: ${detailsResponse.headers['content-type']}');
        print('Tamanho da resposta: ${detailsResponse.body.length} caracteres');
        print('Estrutura JSON completa:');
        print(JsonEncoder.withIndent('  ').convert(detailsData));
        print('=== FIM DA RESPOSTA ===');
        
        if (detailsData['success'] == true) {
          productDetails = detailsData['data'];
          print('✅ Detalhes do produto obtidos com sucesso');
          
          // LOG DETALHADO DOS DADOS PROCESSADOS
          print('📋 === DADOS PROCESSADOS PARA FRONTEND ===');
          print('Keys principais: ${productDetails.keys.toList()}');
          
          // Log de campos específicos importantes
          final importantFields = [
            'basic_info', 'pricing', 'images', 'variations', 'raw_data'
          ];
          
          for (String field in importantFields) {
            if (productDetails.containsKey(field)) {
              final value = productDetails[field];
              if (value is Map) {
                print('  ✓ $field: ${value.keys.toList()}');
              } else if (value is List) {
                print('  ✓ $field: ${value.length} itens');
              } else {
                print('  ✓ $field: $value');
              }
            } else {
              print('  ✗ $field: NÃO ENCONTRADO');
            }
          }
          
          // Log específico para basic_info
          if (productDetails.containsKey('basic_info')) {
            final basicInfo = productDetails['basic_info'];
            print('  📝 Basic Info - Keys: ${basicInfo.keys.toList()}');
            if (basicInfo.containsKey('title')) {
              print('    - Título: ${basicInfo['title']}');
            }
          }
          
          // Log específico para pricing
          if (productDetails.containsKey('pricing')) {
            final pricing = productDetails['pricing'];
            print('  💰 Pricing - Keys: ${pricing.keys.toList()}');
            print('    - Preço mínimo: ${pricing['min_price']}');
            print('    - Preço máximo: ${pricing['max_price']}');
            print('    - Moeda: ${pricing['currency']}');
          }
          
          // Log específico para images
          if (productDetails.containsKey('images')) {
            final images = productDetails['images'];
            print('  🖼️ Images: ${images.length} imagens encontradas');
            if (images.isNotEmpty) {
              print('    - Primeira imagem: ${images[0]}');
            }
          }
          
          // Log específico para variations
          if (productDetails.containsKey('variations')) {
            final variations = productDetails['variations'];
            print('  🎨 Variations: ${variations.length} variações encontradas');
            if (variations.isNotEmpty) {
              print('    - Primeira variação: ${variations[0].keys.toList()}');
            }
          }
          
          print('=== FIM DOS DADOS PROCESSADOS ===');
          
        } else {
          print('⚠️ API de detalhes retornou erro: ${detailsData['message']}');
        }
      } else {
        print('❌ Erro na API de detalhes: ${detailsResponse.statusCode}');
        print('Resposta de erro: ${detailsResponse.body}');
      }

      // Tentar buscar informações de frete (opcional)
      try {
        final freightResponse = await http.get(
          Uri.parse('$baseUrl/api/aliexpress/freight/$itemId'),
          headers: headers,
        ).timeout(const Duration(seconds: 15));

        if (freightResponse.statusCode == 200) {
          final freightData = json.decode(freightResponse.body);
          
          // LOG DETALHADO DA RESPOSTA DE FRETE
          print('🚚 === RESPOSTA COMPLETA DA API DE FRETE ===');
          print('Status Code: ${freightResponse.statusCode}');
          print('Content-Type: ${freightResponse.headers['content-type']}');
          print('Tamanho da resposta: ${freightResponse.body.length} caracteres');
          print('Estrutura JSON completa:');
          print(JsonEncoder.withIndent('  ').convert(freightData));
          print('=== FIM DA RESPOSTA DE FRETE ===');
          
          if (freightData['success'] == true) {
            freightInfo = freightData['data'];
            print('✅ Informações de frete obtidas');
            
            // Log detalhado dos dados de frete
            print('📦 === DADOS DE FRETE PROCESSADOS ===');
            print('Keys principais: ${freightInfo.keys.toList()}');
            
            if (freightInfo.containsKey('freight_options')) {
              final options = freightInfo['freight_options'];
              print('  🚚 Opções de frete: ${options.length} encontradas');
              if (options.isNotEmpty) {
                print('    - Primeira opção: ${options[0].keys.toList()}');
              }
            }
            
            print('=== FIM DOS DADOS DE FRETE ===');
          } else {
            print('⚠️ API de frete retornou erro: ${freightData['message']}');
          }
        } else {
          print('❌ Erro na API de frete: ${freightResponse.statusCode}');
          print('Resposta de erro: ${freightResponse.body}');
        }
      } catch (e) {
        print('⚠️ Erro ao buscar frete (opcional): $e');
        // Frete é opcional, não falha a operação principal
      }

      // Combinar todas as informações
      final result = {
        'success': true,
        'productDetails': productDetails,
        'freightInfo': freightInfo,
        'hasDetails': productDetails.isNotEmpty,
        'hasFreight': freightInfo.isNotEmpty,
      };
      
      // LOG FINAL DA ESTRUTURA RETORNADA
      print('🎯 === ESTRUTURA FINAL RETORNADA PARA FRONTEND ===');
      print('Success: ${result['success']}');
      print('Has Details: ${result['hasDetails']}');
      print('Has Freight: ${result['hasFreight']}');
      print('Product Details Keys: ${productDetails.keys.toList()}');
      print('Freight Info Keys: ${freightInfo.keys.toList()}');
      print('Estrutura completa:');
      print(JsonEncoder.withIndent('  ').convert(result));
      print('=== FIM DA ESTRUTURA FINAL ===');
      
      return result;

    } catch (e) {
      print('❌ Erro ao buscar detalhes completos: $e');
      return {
        'success': false,
        'error': e.toString(),
        'productDetails': {},
        'freightInfo': {},
        'hasDetails': false,
        'hasFreight': false,
      };
    }
  }

  /// Extrair galeria de imagens dos detalhes
  static List<String> extractImageGallery(Map<String, dynamic> productDetails) {
    List<String> images = [];
    
    try {
      // Buscar em diferentes locais possíveis
      final imageSources = [
        'images', 'productImages', 'imageUrls', 'gallery',
        'aeProductImageGallery', 'itemImages', 'productPicUrl',
        'mainImageList', 'additionalImageUrls'
      ];

      for (String source in imageSources) {
        final imageData = _findNestedValue(productDetails, source);
        if (imageData != null) {
          if (imageData is List) {
            for (var img in imageData) {
              final imgUrl = _extractImageUrl(img);
              if (imgUrl.isNotEmpty && !images.contains(imgUrl)) {
                images.add(imgUrl);
              }
            }
          } else if (imageData is String) {
            final imgUrl = _extractImageUrl(imageData);
            if (imgUrl.isNotEmpty && !images.contains(imgUrl)) {
              images.add(imgUrl);
            }
          }
        }
      }

      print('📸 Encontradas ${images.length} imagens na galeria');
    } catch (e) {
      print('❌ Erro ao extrair galeria: $e');
    }

    return images;
  }

  /// Extrair variações do produto (cores, tamanhos, etc.)
  static List<Map<String, dynamic>> extractProductVariations(Map<String, dynamic> productDetails) {
    List<Map<String, dynamic>> variations = [];
    
    try {
      final variationSources = [
        'skuInfos', 'variations', 'skuList', 'productSkuInfos',
        'aeItemSkuInfos', 'skuPropertyList', 'variations'
      ];

      for (String source in variationSources) {
        final variationData = _findNestedValue(productDetails, source);
        if (variationData != null && variationData is List) {
          for (var variation in variationData) {
            if (variation is Map) {
              variations.add(Map<String, dynamic>.from(variation));
            }
          }
          if (variations.isNotEmpty) break;
        }
      }

      print('🎨 Encontradas ${variations.length} variações do produto');
    } catch (e) {
      print('❌ Erro ao extrair variações: $e');
    }

    return variations;
  }

  /// Extrair descrição HTML do produto
  static String extractProductDescription(Map<String, dynamic> productDetails) {
    try {
      final descriptionSources = [
        'description', 'productDescription', 'detailDesc',
        'aeItemDescription', 'htmlDescription', 'productDetail'
      ];

      for (String source in descriptionSources) {
        final desc = _findNestedValue(productDetails, source);
        if (desc != null && desc.toString().isNotEmpty) {
          return desc.toString();
        }
      }
    } catch (e) {
      print('❌ Erro ao extrair descrição: $e');
    }

    return '';
  }

  /// Buscar valor aninhado na estrutura de dados
  static dynamic _findNestedValue(Map<String, dynamic> data, String key) {
    // Busca direta
    if (data.containsKey(key)) {
      return data[key];
    }

    // Busca recursiva
    for (var value in data.values) {
      if (value is Map<String, dynamic>) {
        final result = _findNestedValue(value, key);
        if (result != null) return result;
      }
    }

    return null;
  }

  /// Extrair URL de imagem de diferentes formatos
  static String _extractImageUrl(dynamic imageData) {
    if (imageData is String) {
      return imageData.startsWith('http') ? imageData : 'https:$imageData';
    } else if (imageData is Map) {
      final urlFields = ['url', 'imageUrl', 'src', 'href', 'path'];
      for (String field in urlFields) {
        if (imageData[field] != null) {
          final url = imageData[field].toString();
          return url.startsWith('http') ? url : 'https:$url';
        }
      }
    }
    return '';
  }
}