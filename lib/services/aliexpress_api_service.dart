import 'dart:convert';
import 'package:http/http.dart' as http;

class AliExpressProduct {
  final String id;
  final String title;
  final String price;
  final String originalPrice;
  final String image;
  final double rating;
  final int reviews;
  final String seller;
  final String aliexpressUrl;

  AliExpressProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.seller,
    required this.aliexpressUrl,
  });

  factory AliExpressProduct.fromJson(Map<String, dynamic> json) {
    return AliExpressProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? '',
      originalPrice: json['original_price'] ?? '',
      image: json['image'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      seller: json['seller'] ?? '',
      aliexpressUrl: json['aliexpress_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'original_price': originalPrice,
      'image': image,
      'rating': rating,
      'reviews': reviews,
      'seller': seller,
      'aliexpress_url': aliexpressUrl,
    };
  }
}

class AliExpressApiService {
  static const String baseUrl = 'https://service-api-aliexpress.mercadodasophia.com.br';
  
  // Buscar produtos do AliExpress
  static Future<List<AliExpressProduct>> searchProducts(String keywords) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/search?keywords=$keywords'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['products'] != null) {
          final List<dynamic> productsJson = data['products'];
          return productsJson
              .map((json) => AliExpressProduct.fromJson(json))
              .toList();
        }
      }
      
      throw Exception('Erro ao buscar produtos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Obter URL de autorização OAuth2
  static Future<String> getOAuthUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/aliexpress/oauth-url'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['auth_url'] ?? '';
      }
      
      throw Exception('Erro ao obter URL de autorização: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Verificar status da API
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Importar produto do AliExpress para o catálogo local
  static Future<Map<String, dynamic>> importProduct(String productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/aliexpress/import-product'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      throw Exception('Erro ao importar produto: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar produtos com OAuth2 (requer autenticação)
  static Future<List<AliExpressProduct>> getProductsWithOAuth({
    String keywords = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/aliexpress/products?keywords=$keywords&page=$page&page_size=$pageSize'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['products'] != null) {
          final List<dynamic> productsJson = data['products'];
          return productsJson
              .map((json) => AliExpressProduct.fromJson(json))
              .toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('AliExpress não autenticado. Faça login OAuth2 primeiro.');
      }
      
      throw Exception('Erro ao buscar produtos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
} 