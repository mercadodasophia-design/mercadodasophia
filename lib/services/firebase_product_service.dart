import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Coleções
  CollectionReference get _products => _firestore.collection('products');
  CollectionReference get _categories => _firestore.collection('categories');

  // Obter todos os produtos
  Stream<QuerySnapshot> getProductsStream({
    String? categoryId,
    bool? isActive,
    bool? isFeatured,
    bool? isOnSale,
    String? searchQuery,
    int limit = 400,
  }) {
    Query query = _products;

    // Filtrar por categoria
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // Filtrar por status ativo
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    // Filtrar por destaque
    if (isFeatured != null) {
      query = query.where('isFeatured', isEqualTo: isFeatured);
    }

    // Filtrar por oferta
    if (isOnSale != null) {
      query = query.where('isOnSale', isEqualTo: isOnSale);
    }

    // Busca por texto
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase());
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Obter produto por ID
  Future<DocumentSnapshot?> getProduct(String productId) async {
    try {
      final doc = await _products.doc(productId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('Erro ao obter produto: $e');
      return null;
    }
  }

  // Obter produtos por categoria
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _products
          .where('categoria', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'documentId': doc.id,
      }).toList();
    } catch (e) {
      print('Erro ao obter produtos por categoria: $e');
      return [];
    }
  }

  // Obter produtos da seção SexyShop
  Future<List<Map<String, dynamic>>> getSexyShopProducts() async {
    try {
      final querySnapshot = await _products
          .where('secao', isEqualTo: 'SexyShop')
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'documentId': doc.id,
      }).toList();
    } catch (e) {
      // Se a coleção não existe ou não há dados, retorna lista vazia
      print('Nenhum produto SexyShop encontrado: $e');
      return [];
    }
  }

  // Obter produtos por seção
  Future<List<Map<String, dynamic>>> getProductsBySection(String section) async {
    try {
      final querySnapshot = await _products
          .where('secao', isEqualTo: section)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'documentId': doc.id,
      }).toList();
    } catch (e) {
      print('Erro ao obter produtos da seção $section: $e');
      return [];
    }
  }

  // Obter produtos da loja (seção Loja)
  Future<List<Map<String, dynamic>>> getLojaProducts() async {
    return await getProductsBySection('Loja');
  }

  // Criar produto
  Future<String> createProduct(Map<String, dynamic> productData) async {
    try {
      // Adicionar timestamps
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      // Gerar keywords para busca
      productData['searchKeywords'] = _generateSearchKeywords(productData['name']);

      // Criar documento
      final docRef = await _products.add(productData);
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar produto: $e');
    }
  }

  // Atualizar produto
  Future<void> updateProduct(String productId, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Atualizar keywords se o nome mudou
      if (updateData.containsKey('name')) {
        updateData['searchKeywords'] = _generateSearchKeywords(updateData['name']);
      }

      await _products.doc(productId).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  // Deletar produto
  Future<void> deleteProduct(String productId) async {
    try {
      await _products.doc(productId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar produto: $e');
    }
  }

  // Importar produto do AliExpress
  Future<String> importAliExpressProduct(Map<String, dynamic> productData) async {
    try {
      // Adicionar campos específicos do AliExpress
      productData['importedFrom'] = 'aliexpress';
      productData['status'] = 'pending';
      productData['isActive'] = false;
      productData['isFeatured'] = false;
      productData['isOnSale'] = false;
      productData['stockQuantity'] = 0;

      return await createProduct(productData);
    } catch (e) {
      throw Exception('Erro ao importar produto: $e');
    }
  }

  // Upload de imagem (versão simulada para desenvolvimento)
  Future<String> uploadImage(String imageUrl, String productId) async {
    try {
      // Para desenvolvimento, vamos usar URLs simuladas
      await Future.delayed(const Duration(seconds: 1));
      
      // Retornar URL simulada baseada no productId
      return 'https://via.placeholder.com/400x400/007ACC/FFFFFF?text=Produto+$productId';
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  // Upload de múltiplas imagens
  Future<List<String>> uploadImages(List<String> imageUrls, String productId) async {
    try {
      final urls = <String>[];
      
      for (int i = 0; i < imageUrls.length; i++) {
        final url = await uploadImage(imageUrls[i], '$productId-$i');
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Erro ao fazer upload das imagens: $e');
    }
  }

  // Obter estatísticas dos produtos
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      final totalQuery = await _products.get();
      final activeQuery = await _products.where('isActive', isEqualTo: true).get();
      final featuredQuery = await _products.where('isFeatured', isEqualTo: true).get();
      final pendingQuery = await _products.where('status', isEqualTo: 'pending').get();
      final onSaleQuery = await _products.where('isOnSale', isEqualTo: true).get();

      return {
        'total': totalQuery.docs.length,
        'active': activeQuery.docs.length,
        'featured': featuredQuery.docs.length,
        'pending': pendingQuery.docs.length,
        'onSale': onSaleQuery.docs.length,
      };
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'active': 0,
        'featured': 0,
        'pending': 0,
        'onSale': 0,
      };
    }
  }

  // Gerar keywords para busca
  List<String> _generateSearchKeywords(String name) {
    final keywords = <String>{};
    keywords.add(name.toLowerCase());
    
    final words = name.toLowerCase().split(' ');
    for (final word in words) {
      if (word.length > 2) {
        keywords.add(word);
      }
    }
    
    return keywords.toList();
  }

  // Categorias
  Stream<QuerySnapshot> getCategoriesStream() {
    return _categories
        .orderBy('name')
        .snapshots();
  }

  Future<String> createCategory(Map<String, dynamic> categoryData) async {
    try {
      categoryData['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _categories.add(categoryData);
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar categoria: $e');
    }
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _categories.doc(categoryId).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar categoria: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categories.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar categoria: $e');
    }
  }

  // Aprovar produto
  Future<void> approveProduct(String productId) async {
    try {
      await _products.doc(productId).update({
        'status': 'active',
        'isActive': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao aprovar produto: $e');
    }
  }

  // Rejeitar produto
  Future<void> rejectProduct(String productId) async {
    try {
      await _products.doc(productId).update({
        'status': 'rejected',
        'isActive': false,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao rejeitar produto: $e');
    }
  }

  // Alternar destaque do produto
  Future<void> toggleFeatured(String productId, bool isFeatured) async {
    try {
      await _products.doc(productId).update({
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao alterar destaque do produto: $e');
    }
  }

  // Alternar status de oferta do produto
  Future<void> toggleOnSale(String productId, bool isOnSale) async {
    try {
      await _products.doc(productId).update({
        'isOnSale': isOnSale,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao alterar status de oferta do produto: $e');
    }
  }
} 