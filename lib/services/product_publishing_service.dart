import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/image_upload_service.dart';
import '../services/product_validation_service.dart';

/// Resultado da publicação
class PublishingResult {
  final bool success;
  final String? productId;
  final List<String> errors;
  final List<String> warnings;
  final String message;

  PublishingResult({
    required this.success,
    this.productId,
    required this.errors,
    required this.warnings,
    required this.message,
  });
}

class ProductPublishingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Publicar produto completo
  static Future<PublishingResult> publishProduct(
    Map<String, dynamic> productData,
    List<File> selectedImages,
  ) async {
    try {
      // 1. VALIDAÇÃO
      ValidationResult validation = ProductValidationService.validateProduct(productData);
      
      if (!validation.isValid) {
        return PublishingResult(
          success: false,
          errors: validation.errors,
          warnings: validation.warnings,
          message: 'Produto não pode ser publicado devido a erros de validação',
        );
      }

      // 2. GERAR ID DO PRODUTO
      String productId = _generateProductId();
      
      // 3. UPLOAD DE IMAGENS
      List<String> uploadedImageUrls = [];
      if (selectedImages.isNotEmpty) {
        try {
          uploadedImageUrls = await ImageUploadService.uploadImages(
            selectedImages,
            productId,
          );
        } catch (e) {
          return PublishingResult(
            success: false,
            errors: ['Erro no upload de imagens: $e'],
            warnings: validation.warnings,
            message: 'Falha no upload de imagens',
          );
        }
      }

      // 4. PREPARAR DADOS DO PRODUTO
      Map<String, dynamic> finalProductData = _prepareProductData(
        productData,
        uploadedImageUrls,
        productId,
      );

      // 5. SALVAR NO FIRESTORE
      await _saveProductToFirestore(finalProductData, productId);

      // 6. LOG DE PUBLICAÇÃO
      await _logPublishing(productId, finalProductData);

      return PublishingResult(
        success: true,
        productId: productId,
        errors: [],
        warnings: validation.warnings,
        message: 'Produto publicado com sucesso!',
      );

    } catch (e) {
      return PublishingResult(
        success: false,
        errors: ['Erro interno: $e'],
        warnings: [],
        message: 'Erro inesperado durante a publicação',
      );
    }
  }

  /// Gerar ID único para o produto
  static String _generateProductId() {
    return 'produto_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Gerar string aleatória
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(DateTime.now().microsecond % chars.length)),
    );
  }

  /// Preparar dados finais do produto
  static Map<String, dynamic> _prepareProductData(
    Map<String, dynamic> originalData,
    List<String> imageUrls,
    String productId,
  ) {
    // Combinar imagens existentes com novas
    List<String> allImages = [];
    
    // Imagens existentes
    if (originalData['images'] != null && originalData['images'] is List) {
      allImages.addAll(List<String>.from(originalData['images']));
    }
    
    // Novas imagens
    allImages.addAll(imageUrls);

    // Preparar dados finais
    Map<String, dynamic> finalData = Map<String, dynamic>.from(originalData);
    
    finalData['id'] = productId;
    finalData['images'] = allImages;
    finalData['main_image'] = allImages.isNotEmpty ? allImages.first : null;
    finalData['status'] = 'published';
    finalData['published_at'] = FieldValue.serverTimestamp();
    finalData['published_by'] = _auth.currentUser?.uid ?? 'unknown';
    finalData['version'] = 1;
    finalData['created_at'] = FieldValue.serverTimestamp();
    finalData['updated_at'] = FieldValue.serverTimestamp();
    
    // Remover dados temporários
    finalData.remove('selected_images');
    finalData.remove('has_unsaved_changes');
    finalData.remove('session_id');

    return finalData;
  }

  /// Salvar produto no Firestore
  static Future<void> _saveProductToFirestore(
    Map<String, dynamic> productData,
    String productId,
  ) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .set(productData);
    } catch (e) {
      throw Exception('Erro ao salvar produto no Firestore: $e');
    }
  }

  /// Log de publicação
  static Future<void> _logPublishing(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await _firestore
          .collection('publishing_logs')
          .add({
        'product_id': productId,
        'product_name': productData['name'],
        'published_by': _auth.currentUser?.uid ?? 'unknown',
        'published_at': FieldValue.serverTimestamp(),
        'status': 'success',
        'images_count': (productData['images'] as List?)?.length ?? 0,
        'has_variations': (productData['variations'] as List?)?.isNotEmpty ?? false,
      });
         } catch (e) {
       // Log silencioso para erro de log
     }
  }

  /// Atualizar produto existente
  static Future<PublishingResult> updateProduct(
    String productId,
    Map<String, dynamic> productData,
    List<File> newImages,
  ) async {
    try {
      // 1. VALIDAÇÃO
      ValidationResult validation = ProductValidationService.validateProduct(productData);
      
      if (!validation.isValid) {
        return PublishingResult(
          success: false,
          errors: validation.errors,
          warnings: validation.warnings,
          message: 'Produto não pode ser atualizado devido a erros de validação',
        );
      }

      // 2. UPLOAD DE NOVAS IMAGENS
      List<String> newImageUrls = [];
      if (newImages.isNotEmpty) {
        newImageUrls = await ImageUploadService.uploadImages(
          newImages,
          productId,
        );
      }

      // 3. PREPARAR DADOS ATUALIZADOS
      Map<String, dynamic> updatedData = Map<String, dynamic>.from(productData);
      
      // Combinar imagens existentes com novas
      List<String> allImages = [];
      if (updatedData['images'] != null && updatedData['images'] is List) {
        allImages.addAll(List<String>.from(updatedData['images']));
      }
      allImages.addAll(newImageUrls);
      
      updatedData['images'] = allImages;
      updatedData['main_image'] = allImages.isNotEmpty ? allImages.first : null;
      updatedData['updated_at'] = FieldValue.serverTimestamp();
      updatedData['version'] = (updatedData['version'] ?? 0) + 1;

      // 4. ATUALIZAR NO FIRESTORE
      await _firestore
          .collection('products')
          .doc(productId)
          .update(updatedData);

      return PublishingResult(
        success: true,
        productId: productId,
        errors: [],
        warnings: validation.warnings,
        message: 'Produto atualizado com sucesso!',
      );

    } catch (e) {
      return PublishingResult(
        success: false,
        errors: ['Erro ao atualizar produto: $e'],
        warnings: [],
        message: 'Erro inesperado durante a atualização',
      );
    }
  }

  /// Deletar produto
  static Future<bool> deleteProduct(String productId) async {
    try {
      // 1. Buscar produto para obter URLs das imagens
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!doc.exists) {
        return false;
      }

      Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
      List<String> imageUrls = List<String>.from(productData['images'] ?? []);

      // 2. Deletar imagens do Storage
      if (imageUrls.isNotEmpty) {
        await ImageUploadService.deleteImages(imageUrls);
      }

      // 3. Deletar documento do Firestore
      await _firestore
          .collection('products')
          .doc(productId)
          .delete();

      return true;
         } catch (e) {
       return false;
     }
  }

  /// Verificar se produto pode ser publicado
  static Future<bool> canPublish(Map<String, dynamic> productData) async {
    ValidationResult result = ProductValidationService.validateProduct(productData);
    return result.isValid;
  }

  /// Obter estatísticas de publicação
  static Future<Map<String, dynamic>> getPublishingStats() async {
    try {
      QuerySnapshot publishedProducts = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'publicado')
          .get();

      QuerySnapshot draftProducts = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'aguardando-revisao')
          .get();

      return {
        'published_count': publishedProducts.docs.length,
        'draft_count': draftProducts.docs.length,
        'total_count': publishedProducts.docs.length + draftProducts.docs.length,
      };
    } catch (e) {
      return {
        'published_count': 0,
        'draft_count': 0,
        'total_count': 0,
        'error': e.toString(),
      };
    }
  }
}
