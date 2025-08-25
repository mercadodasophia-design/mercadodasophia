import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart' as product_model;

class ProductService {

  // Buscar produtos reais do Firebase usando a nova estrutura (apenas seção Loja)
  static Future<List<product_model.Product>> getProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .orderBy('data_post', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Buscar produtos por seção (Loja ou SexyShop)
  static Future<List<product_model.Product>> getProductsBySection(String section) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: section)
          .orderBy('data_post', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Buscar produtos da loja (seção Loja)
  static Future<List<product_model.Product>> getLojaProducts() async {
    return await getProductsBySection('Loja');
  }

  // Buscar produtos da SexyShop (seção SexyShop)
  static Future<List<product_model.Product>> getSexyShopProducts() async {
    return await getProductsBySection('SexyShop');
  }

  // Buscar produtos por categoria (apenas seção Loja)
  static Future<List<product_model.Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .where('categoria', isEqualTo: category)
          .orderBy('data_post', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Buscar categorias reais do Firebase (apenas seção Loja)
  static Future<List<String>> getCategories() async {
    try {
      // Buscar categorias únicas dos produtos da seção Loja
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoria = data['categoria'] as String?;
        if (categoria != null && categoria.isNotEmpty) {
          categories.add(categoria);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      // Retornar categorias padrão em caso de erro
      return [
        'Smartphones',
        'Computadores',
        'Roupas',
        'Casa & Jardim',
        'Automóveis',
        'Esportes',
        'Brinquedos',
        'Beleza',
        'Livros',
        'Ferramentas',
      ];
    }
  }

  // Buscar categorias por seção
  static Future<List<String>> getCategoriesBySection(String section) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: section)
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoria = data['categoria'] as String?;
        if (categoria != null && categoria.isNotEmpty) {
          categories.add(categoria);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Erro ao buscar categorias da seção $section: $e');
      return [];
    }
  }

  // Buscar produto por ID
  static Future<product_model.Product?> getProductById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(id)
          .get();

      if (doc.exists) {
        return product_model.Product.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar produto por ID: $e');
      return null;
    }
  }

  // Buscar produtos em destaque (com oferta) - apenas seção Loja
  static Future<List<product_model.Product>> getFeaturedProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .where('desconto_percentual', isGreaterThan: 0)
          .orderBy('desconto_percentual', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos em destaque: $e');
      return [];
    }
  }

  // Buscar produtos por marca (apenas seção Loja)
  static Future<List<product_model.Product>> getProductsByBrand(String brand) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .where('marca', isEqualTo: brand)
          .orderBy('data_post', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos por marca: $e');
      return [];
    }
  }

  // Buscar produtos por busca de texto (apenas seção Loja)
  static Future<List<product_model.Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .get();

      final results = <product_model.Product>[];
      final lowerQuery = query.toLowerCase();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final titulo = (data['titulo'] as String? ?? '').toLowerCase();
        final descricao = (data['descricao'] as String? ?? '').toLowerCase();
        final marca = (data['marca'] as String? ?? '').toLowerCase();
        final categoria = (data['categoria'] as String? ?? '').toLowerCase();

        if (titulo.contains(lowerQuery) ||
            descricao.contains(lowerQuery) ||
            marca.contains(lowerQuery) ||
            categoria.contains(lowerQuery)) {
          results.add(product_model.Product.fromMap(data, doc.id));
        }
      }

      return results;
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      return [];
    }
  }

  // Buscar produtos mais recentes (apenas seção Loja)
  static Future<List<product_model.Product>> getRecentProducts({int limit = 20}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .orderBy('data_post', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos recentes: $e');
      return [];
    }
  }

  // Buscar produtos com maior desconto (apenas seção Loja)
  static Future<List<product_model.Product>> getProductsWithDiscount({int limit = 20}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('secao', isEqualTo: 'Loja')
          .where('desconto_percentual', isGreaterThan: 0)
          .orderBy('desconto_percentual', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return product_model.Product.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos com desconto: $e');
      return [];
    }
  }
}