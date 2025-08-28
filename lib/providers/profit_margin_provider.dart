import 'package:flutter/foundation.dart';
import '../services/profit_margin_service.dart';

class ProfitMarginProvider with ChangeNotifier {
  double _generalMargin = 0.0;
  Map<String, double> _productMargins = {};
  bool _isLoading = true;
  String? _error;

  // Getters
  double get generalMargin => _generalMargin;
  Map<String, double> get productMargins => Map.unmodifiable(_productMargins);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isReady => !_isLoading && _error == null;

  /// Carrega todas as configurações de margem
  Future<void> loadMargins() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar margem geral e específicas em paralelo
      final results = await Future.wait([
        ProfitMarginService.getGeneralMargin(),
        ProfitMarginService.getProductMargins(),
      ]);

      _generalMargin = results[0] as double;
      _productMargins = results[1] as Map<String, double>;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar margens: $e';
        _isLoading = false;
      });
      print('❌ Erro ao carregar margens: $e');
    }
  }

  /// Obtém a margem aplicável para um produto específico
  double getProductMargin(String productId) {
    // Primeiro verificar se há margem específica
    if (_productMargins.containsKey(productId)) {
      return _productMargins[productId]!;
    }
    
    // Se não há margem específica, usar margem geral
    return _generalMargin;
  }

  /// Calcula o preço final com margem aplicada
  double calculateFinalPrice(double basePrice, String productId) {
    if (!isReady) return basePrice; // Retorna preço original se não está pronto
    
    final margin = getProductMargin(productId);
    final finalPrice = ProfitMarginService.calculateFinalPrice(basePrice, margin);
    
    return finalPrice;
  }

  /// Aplica margem em uma lista de produtos
  List<Map<String, dynamic>> applyMarginToProducts(List<Map<String, dynamic>> products) {
    if (!isReady) return products; // Retorna produtos originais se não está pronto

    return products.map((product) {
      final productId = product['id'] as String? ?? '';
      final basePrice = (product['preco'] ?? 0.0).toDouble();
      final finalPrice = calculateFinalPrice(basePrice, productId);
      final margin = getProductMargin(productId);

      return {
        ...product,
        'preco_original': basePrice,
        'preco': finalPrice,
        'margem_aplicada': margin,
      };
    }).toList();
  }

  /// Verifica se um produto tem margem específica
  bool hasSpecificMargin(String productId) {
    return _productMargins.containsKey(productId);
  }

  /// Obtém informações completas de margem para um produto
  Map<String, dynamic> getProductMarginInfo(String productId) {
    final hasSpecific = hasSpecificMargin(productId);
    final appliedMargin = getProductMargin(productId);

    return {
      'has_specific_margin': hasSpecific,
      'general_margin': _generalMargin,
      'specific_margin': hasSpecific ? _productMargins[productId] : null,
      'applied_margin': appliedMargin,
    };
  }

  /// Atualiza a margem geral
  Future<void> updateGeneralMargin(double margin) async {
    try {
      await ProfitMarginService.updateGeneralMargin(margin);
      _generalMargin = margin;
      notifyListeners();
      print('✅ Margem geral atualizada: ${margin.toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ Erro ao atualizar margem geral: $e');
      rethrow;
    }
  }

  /// Adiciona ou atualiza margem específica
  Future<void> updateProductMargin(String productId, double margin) async {
    try {
      await ProfitMarginService.updateProductMargin(productId, margin);
      _productMargins[productId] = margin;
      notifyListeners();
      print('✅ Margem específica atualizada: ${margin.toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ Erro ao atualizar margem específica: $e');
      rethrow;
    }
  }

  /// Remove margem específica
  Future<void> removeProductMargin(String productId) async {
    try {
      await ProfitMarginService.removeProductMargin(productId);
      _productMargins.remove(productId);
      notifyListeners();
      print('✅ Margem específica removida');
    } catch (e) {
      print('❌ Erro ao remover margem específica: $e');
      rethrow;
    }
  }

  /// Recarrega as margens
  Future<void> refresh() async {
    await loadMargins();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
