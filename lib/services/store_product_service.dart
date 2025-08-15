import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class StoreProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _apiBaseUrl = 'https://mercadodasophia-api.onrender.com/api';

  // Buscar produtos combinando locais e importados
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    int limit = 50,
  }) async {
    try {
      List<Product> allProducts = [];

      // 1. Buscar produtos locais do Firebase
      final localProducts = await _getLocalProducts(searchQuery: searchQuery, limit: limit ~/ 2);
      allProducts.addAll(localProducts);

      // 2. Buscar produtos importados do AliExpress
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final importedProducts = await _getImportedProducts(searchQuery: searchQuery, limit: limit ~/ 2);
        allProducts.addAll(importedProducts);
      }

      // 3. Ordenar por relevância
      allProducts.sort((a, b) {
        if (a.isLocal && !b.isLocal) return -1;
        if (!a.isLocal && b.isLocal) return 1;
        return b.rating.compareTo(a.rating);
      });

      return allProducts;
    } catch (e) {
      print('❌ Erro ao buscar produtos: $e');
      return [];
    }
  }

  // Buscar produtos locais do Firebase
  Future<List<Product>> _getLocalProducts({
    String? searchQuery,
    int limit = 25,
  }) async {
    try {
      Query query = _firestore.collection('products')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'published');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase());
      }

      final snapshot = await query.limit(limit).get();
      
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc, isLocal: true);
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar produtos locais: $e');
      return [];
    }
  }

  // Buscar produtos importados do AliExpress
  Future<List<Product>> _getImportedProducts({
    required String searchQuery,
    int limit = 25,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/aliexpress/products?q=${Uri.encodeComponent(searchQuery)}&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final productsData = data['data']['aliexpress_ds_text_search_response']['data']['products']['selection_search_product'];
          
          return productsData.map<Product>((productData) {
            return Product.fromAliExpress(productData, isLocal: false);
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Erro ao buscar produtos importados: $e');
      return [];
    }
  }
}
