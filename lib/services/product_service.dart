import '../models/product.dart';
import 'firebase_product_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  static final FirebaseProductService _firebaseService = FirebaseProductService();

  // Buscar produtos reais do Firebase
  static Future<List<Product>> getProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'published')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromFirestore(doc, isLocal: false);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      return [];
    }
  }

  // Buscar produtos por categoria
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'published')
          .where('category', isEqualTo: category)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc, isLocal: false);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos por categoria: $e');
      return [];
    }
  }

  // Buscar categorias reais do Firebase
  static Future<List<String>> getCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return data['name'] as String;
      }).toList();
    } catch (e) {
      print('Erro ao buscar categorias: $e');
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

  // Buscar produto por ID
  static Future<Product?> getProductById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(id)
          .get();

      if (doc.exists) {
        return Product.fromFirestore(doc, isLocal: false);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar produto por ID: $e');
      return null;
    }
  }

  // Buscar produtos em destaque
  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'published')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc, isLocal: false);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos em destaque: $e');
      return [];
    }
  }

  // Buscar produtos em oferta
  static Future<List<Product>> getOnSaleProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'published')
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc, isLocal: false);
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos em oferta: $e');
      return [];
    }
  }
} 