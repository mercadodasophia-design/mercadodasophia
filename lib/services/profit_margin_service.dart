import 'package:cloud_firestore/cloud_firestore.dart';

class ProfitMarginService {
  static const String _generalMarginDoc = 'financial';
  static const String _productMarginsDoc = 'product_margins';
  
  /// Carrega a margem de lucro geral da loja
  static Future<double> getGeneralMargin() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(_generalMarginDoc)
          .get();
      
      if (doc.exists) {
        return (doc.data()?['general_margin'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('❌ Erro ao carregar margem geral: $e');
      return 0.0;
    }
  }
  
  /// Carrega as margens específicas de produtos
  static Future<Map<String, double>> getProductMargins() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(_productMarginsDoc)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return Map<String, double>.from(data);
      }
      return {};
    } catch (e) {
      print('❌ Erro ao carregar margens específicas: $e');
      return {};
    }
  }
  
  /// Calcula o preço final com margem de lucro aplicada
  static double calculateFinalPrice(double basePrice, double marginPercentage) {
    if (marginPercentage <= 0) return basePrice;
    return basePrice * (1 + marginPercentage / 100);
  }
  
  /// Obtém a margem aplicável para um produto específico
  static Future<double> getProductMargin(String productId) async {
    try {
      // Primeiro verificar se há margem específica
      final productMargins = await getProductMargins();
      if (productMargins.containsKey(productId)) {
        return productMargins[productId]!;
      }
      
      // Se não há margem específica, usar margem geral
      return await getGeneralMargin();
    } catch (e) {
      print('❌ Erro ao obter margem do produto: $e');
      return 0.0;
    }
  }
  
  /// Aplica margem de lucro em um preço base
  static Future<double> applyMarginToPrice(double basePrice, String productId) async {
    try {
      final margin = await getProductMargin(productId);
      return calculateFinalPrice(basePrice, margin);
    } catch (e) {
      print('❌ Erro ao aplicar margem: $e');
      return basePrice;
    }
  }
  
  /// Aplica margem de lucro em uma lista de produtos
  static Future<List<Map<String, dynamic>>> applyMarginToProducts(
    List<Map<String, dynamic>> products
  ) async {
    try {
      final generalMargin = await getGeneralMargin();
      final productMargins = await getProductMargins();
      
      return products.map((product) {
        final productId = product['id'] as String? ?? '';
        final basePrice = (product['preco'] ?? 0.0).toDouble();
        
        // Verificar se há margem específica
        final margin = productMargins[productId] ?? generalMargin;
        final finalPrice = calculateFinalPrice(basePrice, margin);
        
        return {
          ...product,
          'preco_original': basePrice,
          'preco': finalPrice,
          'margem_aplicada': margin,
        };
      }).toList();
    } catch (e) {
      print('❌ Erro ao aplicar margem em produtos: $e');
      return products;
    }
  }
  
  /// Verifica se um produto tem margem específica
  static Future<bool> hasSpecificMargin(String productId) async {
    try {
      final productMargins = await getProductMargins();
      return productMargins.containsKey(productId);
    } catch (e) {
      print('❌ Erro ao verificar margem específica: $e');
      return false;
    }
  }
  
  /// Obtém informações completas de margem para um produto
  static Future<Map<String, dynamic>> getProductMarginInfo(String productId) async {
    try {
      final generalMargin = await getGeneralMargin();
      final productMargins = await getProductMargins();
      final hasSpecific = productMargins.containsKey(productId);
      final appliedMargin = hasSpecific ? productMargins[productId]! : generalMargin;
      
      return {
        'has_specific_margin': hasSpecific,
        'general_margin': generalMargin,
        'specific_margin': hasSpecific ? productMargins[productId] : null,
        'applied_margin': appliedMargin,
      };
    } catch (e) {
      print('❌ Erro ao obter informações de margem: $e');
      return {
        'has_specific_margin': false,
        'general_margin': 0.0,
        'specific_margin': null,
        'applied_margin': 0.0,
      };
    }
  }
  
  /// Atualiza a margem geral da loja
  static Future<void> updateGeneralMargin(double margin) async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(_generalMarginDoc)
          .set({
        'general_margin': margin,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Margem geral atualizada: ${margin.toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ Erro ao atualizar margem geral: $e');
      rethrow;
    }
  }
  
  /// Adiciona ou atualiza margem específica de um produto
  static Future<void> updateProductMargin(String productId, double margin) async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(_productMarginsDoc)
          .set({
        productId: margin,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Margem específica atualizada para produto $productId: ${margin.toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ Erro ao atualizar margem específica: $e');
      rethrow;
    }
  }
  
  /// Remove margem específica de um produto
  static Future<void> removeProductMargin(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(_productMarginsDoc)
          .update({
        productId: FieldValue.delete(),
      });
      
      print('✅ Margem específica removida para produto $productId');
    } catch (e) {
      print('❌ Erro ao remover margem específica: $e');
      rethrow;
    }
  }
}
