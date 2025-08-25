import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Coleção de categorias
  CollectionReference get _categories => _firestore.collection('categorias');

  // Obter todas as categorias
  Future<List<String>> getCategories() async {
    try {
      final querySnapshot = await _categories.get();
      return querySnapshot.docs.map((doc) => doc.data() as String).toList();
    } catch (e) {
      print('Erro ao obter categorias: $e');
      return [];
    }
  }

  // Obter categorias por seção (ex: SexyShop)
  Future<List<String>> getCategoriesBySection(String section) async {
    try {
      final querySnapshot = await _categories
          .where('secao', isEqualTo: section)
          .get()
          .timeout(const Duration(seconds: 10));
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['nome'] as String;
      }).toList();
    } catch (e) {
      // Se a coleção não existe ou não há dados, retorna lista vazia
      print('Nenhuma categoria encontrada para a seção $section: $e');
      return [];
    }
  }

  // Obter categorias da seção SexyShop
  Future<List<String>> getSexyShopCategories() async {
    return await getCategoriesBySection('SexyShop');
  }

  // Adicionar categoria
  Future<String> addCategory(String categoryName, String section) async {
    try {
      final docRef = await _categories.add({
        'nome': categoryName,
        'secao': section,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar categoria: $e');
    }
  }

  // Deletar categoria
  Future<void> deleteCategory(String id) async {
    try {
      await _categories.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar categoria: $e');
    }
  }
} 