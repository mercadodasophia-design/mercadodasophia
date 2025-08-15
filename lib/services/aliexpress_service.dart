import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'aliexpress_category_mapper.dart';

class AliExpressService {
  // API principal - Funcionando
  static const String _apiBaseUrl = 'https://service-api-aliexpress.mercadodasophia.com.br/api';
  
  // Headers para requisições
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Buscar produtos via API Express (REAL)
  Future<List<Map<String, dynamic>>> searchProducts(String query, {
    String sortBy = 'rating',
    int page = 1,
    int limit = 400,
  }) async {
    try {
      print('🔍 Searching products: $query (page: $page, sort: $sortBy)');
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/search?keywords=${Uri.encodeComponent(query)}&category_id=2&page=$page&page_size=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final products = List<Map<String, dynamic>>.from(data['products']);
          print('✅ Found ${products.length} products');
          return products;
        } else {
          print('❌ API Error: ${data['message']}');
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        print('❌ API Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Search error: $e');
      throw Exception('Search failed: $e');
    }
  }

  // Obter detalhes do produto via API Express (REAL)
  Future<Map<String, dynamic>> getProductDetails(String productUrl) async {
    try {
      print('📦 Getting product details: $productUrl');
      
      // Extrair ID do produto da URL
      String productId = productUrl;
      if (productUrl.contains('aliexpress.com/item/')) {
        productId = productUrl.split('/item/').last.split('.html').first;
      }
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/product/$productId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Product details loaded');
          return data['product'];
        } else {
          print('❌ API Error: ${data['message']}');
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        print('❌ API Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Product details error: $e');
      throw Exception('Product details failed: $e');
    }
  }

  // Importar produto individual
  Future<Map<String, dynamic>> importProduct(String productUrl, {
    String? categoryId,
    double? priceOverride,
    int stockQuantity = 0,
  }) async {
    try {
      print('📦 Importing product: $productUrl');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/import'),
        headers: _headers,
        body: json.encode({
          'url': productUrl,
          'categoryId': categoryId,
          'priceOverride': priceOverride,
          'stockQuantity': stockQuantity,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Product imported successfully');
        return result;
      } else {
        print('❌ Import API Error: ${response.statusCode}');
        throw Exception('Failed to import product');
      }
    } catch (e) {
      print('❌ Import error: $e');
      throw Exception('Import failed: $e');
    }
  }

  // Importar produto com detecção automática de categoria
  Future<Map<String, dynamic>> importProductWithAutoCategory(String productUrl, {
    String? categoryId,
    double? priceOverride,
    int stockQuantity = 0,
  }) async {
    try {
      print('📦 Importing product with auto category detection: $productUrl');
      
      // 1. Obter detalhes do produto da AliExpress
      final productDetails = await getProductDetails(productUrl);
      
      // 2. Detectar categoria automaticamente
      final categoryDetection = AliExpressCategoryMapper.detectCategory(
        productName: productDetails['name'] ?? '',
        productDescription: productDetails['description'] ?? '',
        aliExpressCategoryId: productDetails['category_id'] ?? productDetails['aliexpress_category_id'],
      );
      
      print('🔍 Categoria detectada: ${categoryDetection['detected_category']} (${(categoryDetection['confidence'] * 100).toStringAsFixed(1)}% confiança)');
      
      // 3. Preparar dados para importação com categoria
      final importData = {
        'url': productUrl,
        'categoryId': categoryId, // Usar categoria manual se fornecida
        'priceOverride': priceOverride,
        'stockQuantity': stockQuantity,
        'detected_category': categoryDetection, // Salvar dados da detecção
      };
      
      // 4. Fazer importação via API
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/import'),
        headers: _headers,
        body: json.encode(importData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // 5. Salvar produto no Firebase com categoria completa
        await _saveProductToFirebase(result, categoryDetection);
        
        print('✅ Product imported successfully with category detection');
        return {
          ...result,
          'category_detection': categoryDetection,
        };
      } else {
        print('❌ Import API Error: ${response.statusCode}');
        throw Exception('Failed to import product');
      }
    } catch (e) {
      print('❌ Import error: $e');
      throw Exception('Import failed: $e');
    }
  }

  // Salvar produto no Firebase com categoria completa
  Future<void> _saveProductToFirebase(Map<String, dynamic> productData, Map<String, dynamic> categoryDetection) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Preparar dados do produto para Firebase
      final productForFirebase = {
        'name': productData['name'] ?? '',
        'description': productData['description'] ?? '',
        'price': productData['price'] ?? 0.0,
        'original_price': productData['original_price'],
        'images': productData['images'] ?? [],
        'main_image': productData['main_image'],
        'stock_quantity': productData['stock_quantity'] ?? 0,
        'aliexpress_id': productData['aliexpress_id'],
        'aliexpress_url': productData['aliexpress_url'],
        'aliexpress_rating': productData['aliexpress_rating'],
        'aliexpress_reviews_count': productData['aliexpress_reviews_count'],
        'aliexpress_sales_count': productData['aliexpress_sales_count'],
        
        // Dados da categoria detectada
        'category': {
          'detected_category': categoryDetection['detected_category'],
          'confidence': categoryDetection['confidence'],
          'source': categoryDetection['source'],
          'ali_express_category': categoryDetection['ali_express_category'],
          'ali_express_id': categoryDetection['ali_express_id'],
          'detection_timestamp': FieldValue.serverTimestamp(),
        },
        
        // Metadados
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'status': 'active',
        'source': 'aliexpress_import',
      };
      
      // Salvar no Firestore
      await firestore.collection('products').add(productForFirebase);
      
      print('✅ Product saved to Firebase with category data');
    } catch (e) {
      print('❌ Error saving to Firebase: $e');
      // Não falhar a importação se o Firebase falhar
    }
  }

  // Importar produtos em lote
  Future<Map<String, dynamic>> importBulkProducts(List<String> productUrls, {
    String? categoryId,
    double priceMultiplier = 1.5,
  }) async {
    try {
      print('📦 Bulk importing ${productUrls.length} products');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/import/bulk'),
        headers: _headers,
        body: json.encode({
          'urls': productUrls,
          'categoryId': categoryId,
          'priceMultiplier': priceMultiplier,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Bulk import completed: ${result['imported']} products');
        return result;
      } else {
        print('❌ Bulk import API Error: ${response.statusCode}');
        throw Exception('Failed to import products in bulk');
      }
    } catch (e) {
      print('❌ Bulk import error: $e');
      throw Exception('Bulk import failed: $e');
    }
  }

  // Importar produtos em lote com detecção automática de categoria
  Future<Map<String, dynamic>> importBulkProductsWithAutoCategory(List<String> productUrls, {
    double priceMultiplier = 1.5,
  }) async {
    try {
      print('📦 Bulk importing ${productUrls.length} products with auto category detection');
      
      final results = <String, dynamic>{
        'success': <Map<String, dynamic>>[],
        'errors': <Map<String, dynamic>>[],
        'total_processed': 0,
        'total_success': 0,
        'total_errors': 0,
      };
      
      for (final productUrl in productUrls) {
        try {
          results['total_processed'] = (results['total_processed'] as int) + 1;
          
          final result = await importProductWithAutoCategory(
            productUrl,
            priceOverride: null,
            stockQuantity: 0,
          );
          
          (results['success'] as List<Map<String, dynamic>>).add({
            'url': productUrl,
            'result': result,
          });
          results['total_success'] = (results['total_success'] as int) + 1;
          
          print('✅ Imported: $productUrl');
        } catch (e) {
          (results['errors'] as List<Map<String, dynamic>>).add({
            'url': productUrl,
            'error': e.toString(),
          });
          results['total_errors'] = (results['total_errors'] as int) + 1;
          
          print('❌ Failed to import: $productUrl - $e');
        }
      }
      
      print('✅ Bulk import with auto category completed: ${results['total_success']} success, ${results['total_errors']} errors');
      return results;
    } catch (e) {
      print('❌ Bulk import with auto category error: $e');
      throw Exception('Bulk import with auto category failed: $e');
    }
  }

  // Verificar preço e estoque via API Express
  Future<Map<String, dynamic>> checkPriceAndStock(String productUrl) async {
    try {
      final productDetails = await getProductDetails(productUrl);
      
      return {
        'price': productDetails['price'],
        'originalPrice': productDetails['originalPrice'],
        'stockAvailable': true, // Simulado
        'lastChecked': DateTime.now().toIso8601String(),
        'aliexpressId': productDetails['aliexpressId'],
      };
    } catch (e) {
      print('❌ Price/stock check error: $e');
      return {
        'price': r'R$ 0,00',
        'originalPrice': r'R$ 0,00',
        'stockAvailable': false,
        'lastChecked': DateTime.now().toIso8601String(),
        'aliexpressId': 'unknown',
      };
    }
  }

  // Sincronizar produtos importados
  Future<void> syncImportedProducts(List<String> productUrls) async {
    try {
      print('🔄 Syncing ${productUrls.length} products');
      
      for (int i = 0; i < productUrls.length; i++) {
        final url = productUrls[i];
        print('🔄 Syncing ${i + 1}/${productUrls.length}: $url');
        
        final productData = await getProductDetails(url);
        await _updateProductInFirestore(productData);
        
        // Rate limiting
        await Future.delayed(const Duration(seconds: 1));
      }
      
      print('✅ Sync completed');
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  // Atualizar produto no Firestore
  Future<void> _updateProductInFirestore(Map<String, dynamic> productData) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final productId = productData['id'] ?? 'unknown';
      
      await firestore.collection('products').doc(productId).update({
        'price': productData['price'],
        'originalPrice': productData['originalPrice'],
        'lastSync': FieldValue.serverTimestamp(),
        'stockAvailable': true,
        'aliexpressId': productData['aliexpressId'],
        'aliexpressUrl': productData['url'],
      });
      
      print('✅ Updated product: $productId');
    } catch (e) {
      print('❌ Firestore update error: $e');
    }
  }

  // Obter produtos em tendência (REAL)
  Future<List<Map<String, dynamic>>> getTrendingProducts() async {
    try {
      print('🔥 Getting trending products');
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/trending'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = List<Map<String, dynamic>>.from(data['products']);
        
        print('✅ Found ${products.length} trending products');
        return products;
      } else {
        print('❌ Trending API Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Trending error: $e');
      throw Exception('Trending products failed: $e');
    }
  }

  // Obter categorias (REAL)
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      print('📂 Getting categories');
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/categories'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = List<Map<String, dynamic>>.from(data['categories']);
        
        print('✅ Found ${categories.length} categories');
        return categories;
      } else {
        print('❌ Categories API Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Categories error: $e');
      throw Exception('Categories failed: $e');
    }
  }

  // Obter estatísticas da API (REAL)
  Future<Map<String, dynamic>> getApiStats() async {
    try {
      print('📊 Getting API stats');
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final stats = json.decode(response.body);
        print('✅ API stats loaded');
        return stats;
      } else {
        print('❌ Stats API Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Stats error: $e');
      throw Exception('API stats failed: $e');
    }
  }

  // Extrair ID do produto da URL
  String _extractProductId(String url) {
    final match = RegExp(r'item/(\d+)\.html').firstMatch(url);
    return match?.group(1) ?? 'unknown';
  }

  // Obter sugestões de categoria para um produto
  Future<List<Map<String, dynamic>>> getCategorySuggestions(String productUrl) async {
    try {
      print('🔍 Getting category suggestions for: $productUrl');
      
      // Obter detalhes do produto
      final productDetails = await getProductDetails(productUrl);
      
      // Obter sugestões usando o mapper
      final suggestions = AliExpressCategoryMapper.getCategorySuggestions(
        productName: productDetails['name'] ?? '',
        productDescription: productDetails['description'] ?? '',
      );
      
      print('✅ Found ${suggestions.length} category suggestions');
      return suggestions;
    } catch (e) {
      print('❌ Error getting category suggestions: $e');
      throw Exception('Failed to get category suggestions: $e');
    }
  }

  // Detectar categoria para um produto sem importar
  Future<Map<String, dynamic>> detectCategoryForProduct(String productUrl) async {
    try {
      print('🔍 Detecting category for: $productUrl');
      
      // Obter detalhes do produto
      final productDetails = await getProductDetails(productUrl);
      
      // Detectar categoria
      final categoryDetection = AliExpressCategoryMapper.detectCategory(
        productName: productDetails['name'] ?? '',
        productDescription: productDetails['description'] ?? '',
        aliExpressCategoryId: productDetails['category_id'] ?? productDetails['aliexpress_category_id'],
      );
      
      print('✅ Category detected: ${categoryDetection['detected_category']}');
      return {
        'product_details': productDetails,
        'category_detection': categoryDetection,
      };
    } catch (e) {
      print('❌ Error detecting category: $e');
      throw Exception('Failed to detect category: $e');
    }
  }

  // Traduzir atributos de produtos
  Future<List<Map<String, dynamic>>> translateAttributes(List<dynamic> attributes) async {
    try {
      print('🔤 Translating ${attributes.length} attributes');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/aliexpress/translate-attributes'),
        headers: _headers,
        body: json.encode({
          'attributes': attributes,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final translatedAttributes = List<Map<String, dynamic>>.from(data['translated_attributes']);
          print('✅ Translated ${translatedAttributes.length} attributes');
          return translatedAttributes;
        } else {
          print('❌ Translation API Error: ${data['message']}');
          throw Exception('Translation API returned error: ${data['message']}');
        }
      } else {
        print('❌ Translation API Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Translation error: $e');
      throw Exception('Translation failed: $e');
    }
  }

  // Traduzir atributos de um produto específico
  Future<Map<String, dynamic>> translateProductAttributes(Map<String, dynamic> productData) async {
    try {
      print('🔤 Translating product attributes');
      
      // Extrair atributos do produto
      List<dynamic> attributes = [];
      
      // Verificar se há variações com atributos
      if (productData['variations'] != null) {
        for (var variation in productData['variations']) {
          if (variation['attributes'] != null) {
            attributes.addAll(variation['attributes']);
          }
        }
      }
      
      // Verificar se há atributos diretos no produto
      if (productData['attributes'] != null) {
        attributes.addAll(productData['attributes']);
      }
      
      if (attributes.isEmpty) {
        print('⚠️ No attributes found to translate');
        return productData;
      }
      
      // Traduzir atributos
      final translatedAttributes = await translateAttributes(attributes);
      
      // Atualizar produto com atributos traduzidos
      final updatedProduct = Map<String, dynamic>.from(productData);
      
      // Substituir atributos nas variações
      if (updatedProduct['variations'] != null) {
        for (int i = 0; i < updatedProduct['variations'].length; i++) {
          if (updatedProduct['variations'][i]['attributes'] != null) {
            updatedProduct['variations'][i]['translated_attributes'] = translatedAttributes;
          }
        }
      }
      
      // Adicionar atributos traduzidos ao produto
      updatedProduct['translated_attributes'] = translatedAttributes;
      
      print('✅ Product attributes translated successfully');
      return updatedProduct;
      
    } catch (e) {
      print('❌ Product attributes translation error: $e');
      return productData; // Retornar produto original em caso de erro
    }
  }

  // Traduzir nome de atributo localmente (fallback)
  String translateAttributeName(String attributeName) {
    final translations = {
      'material': 'Material',
      'origin': 'Origem',
      'brand': 'Marca',
      'model': 'Modelo',
      'size': 'Tamanho',
      'color': 'Cor',
      'weight': 'Peso',
      'dimensions': 'Dimensões',
      'warranty': 'Garantia',
      'certification': 'Certificação',
      'age group': 'Faixa Etária',
      'gender': 'Gênero',
      'theme': 'Tema',
      'type': 'Tipo',
      'condition': 'Condição',
      'package': 'Embalagem',
      'feature': 'Característica',
      'style': 'Estilo',
      'pattern': 'Padrão',
      'season': 'Estação',
      'occasion': 'Ocasião',
      'target audience': 'Público-Alvo',
      'recommended age': 'Idade Recomendada',
      'chemical high-em cause': 'Químico Alto-em Causa',
      'item type': 'Tipo de Item',
      'bjd/sd attribute': 'Atributo BJD/SD',
      'form': 'Forma',
      'number of model': 'Número do Modelo',
      'characteristics': 'Características',
      'manufacturer serial number': 'Número de Série do Fabricante',
      'warning': 'Aviso',
      'choice': 'Escolha',
    };
    
    final lowerName = attributeName.toLowerCase();
    return translations[lowerName] ?? 
           attributeName.split(' ')
               .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
               .join(' ');
  }
} 