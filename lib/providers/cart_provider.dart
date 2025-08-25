import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/product_model.dart';


class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  double _shippingCost = 0.0;

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  
  // Calcular total do carrinho
  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  // Calcular total de itens
  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Verificar se há itens indisponíveis
  bool get hasUnavailableItems {
    return _items.any((item) => !item.isAvailable);
  }

  // Obter itens indisponíveis
  List<CartItem> get unavailableItems {
    return _items.where((item) => !item.isAvailable).toList();
  }

  // Custo do frete
  double get shippingCost => _shippingCost;

  // Calcular frete para CEP específico
  Future<Map<String, dynamic>> calculateShipping(String cep) async {
    try {
      // Verificar se há produtos no carrinho
      if (_items.isEmpty) {
        _shippingCost = 0.0;
        notifyListeners();
        return {
          'value': 0.0,
          'delivery_days': 12,
          'delivery_date': DateTime.now().add(Duration(days: 12)),
          'cep': cep,
          'available': true,
          'message': 'Carrinho vazio',
        };
      }

      // Verificar se algum produto tem frete gratuito (freteInfo nulo)
      bool hasFreeShipping = _items.any((item) => 
        item.product.freightInfo == null || 
        item.product.freightInfo!.isEmpty ||
        item.product.freightInfo!['value'] == null ||
        item.product.freightInfo!['value'] == 0.0
      );

      if (hasFreeShipping) {
        // Se qualquer produto tem frete gratuito, frete é gratuito
        _shippingCost = 0.0;
        notifyListeners();
        
        return {
          'value': 0.0,
          'delivery_days': 12,
          'delivery_date': DateTime.now().add(Duration(days: 12)),
          'cep': cep,
          'available': true,
          'message': 'Frete Grátis',
        };
      }

      // Se não há frete gratuito, usar o valor do produto com maior frete
      double maxShippingValue = 0.0;
      
      for (final item in _items) {
        if (item.product.freightInfo != null && 
            item.product.freightInfo!['value'] != null) {
          final freightValue = (item.product.freightInfo!['value'] as num).toDouble();
          if (freightValue > maxShippingValue) {
            maxShippingValue = freightValue;
          }
        }
      }

      // Atualizar custo do frete
      _shippingCost = maxShippingValue;
      notifyListeners();

      return {
        'value': maxShippingValue,
        'delivery_days': 12,
        'delivery_date': DateTime.now().add(Duration(days: 12)),
        'cep': cep,
        'available': true,
        'message': 'Frete calculado',
      };

    } catch (e) {
      _shippingCost = 0.0;
      notifyListeners();
      
      return {
        'value': 0.0,
        'delivery_days': 12,
        'delivery_date': DateTime.now().add(Duration(days: 12)),
        'cep': cep,
        'available': false,
        'error': 'Erro ao calcular frete: $e',
      };
    }
  }

  // Calcular frete gratuito (quando produto tem frete nulo)
  void setFreeShipping() {
    _shippingCost = 0.0;
    notifyListeners();
  }

  // Inicializar carrinho
  Future<void> initializeCart() async {
    _setLoading(true);
    _clearError();
    
    try {
      if (_auth.currentUser != null) {
        // Usuário logado - carregar do Firebase
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final cartCollection = userDoc.collection('cart');
        
        final querySnapshot = await cartCollection.get();
        
        _items = querySnapshot.docs.map((doc) {
          return CartItem.fromFirestore(doc.data(), doc.id);
        }).toList();
      } else {
        // Usuário não logado - carregar do armazenamento local
        await _loadLocalCart();
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar carrinho: $e');
      _setLoading(false);
    }
  }

    // Adicionar item ao carrinho
  Future<bool> addItem(Product product, {ProductVariation? variation, int quantity = 1}) async {
    // Verificar se o usuário está logado
    final isLoggedIn = _auth.currentUser != null;

    // Verificar disponibilidade
    if (variation != null) {
      if (!variation.hasStock || quantity > variation.stock) {
        _setError('Quantidade indisponível para esta variação');
        return false;
      }
    } else {
      if (!product.isAvailable) {
        _setError('Produto indisponível');
        return false;
      }
    }

    try {
      if (isLoggedIn) {
        // Usuário logado - usar Firebase
        return await _addItemToFirebase(product, variation, quantity);
      } else {
        // Usuário não logado - usar armazenamento local
        return await _addItemToLocal(product, variation, quantity);
      }
    } catch (e) {
      _setError('Erro ao adicionar item: $e');
      return false;
    }
  }

  // Adicionar item ao Firebase (usuário logado)
  Future<bool> _addItemToFirebase(Product product, ProductVariation? variation, int quantity) async {
    final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
    final cartCollection = userDoc.collection('cart');
    
    // Verificar se o item já existe
    final existingItem = _findExistingItem(product, variation);
    
    if (existingItem != null) {
      // Atualizar quantidade do item existente
      final newQuantity = existingItem.quantity + quantity;
      
      if (variation != null && newQuantity > variation.stock) {
        _setError('Quantidade total excede o estoque disponível');
        return false;
      }
      
      await _updateItemQuantity(existingItem.id, newQuantity);
      return true;
    } else {
      // Adicionar novo item
      final cartItem = CartItem(
        id: '', // Será definido pelo Firestore
        product: product,
        variation: variation,
        quantity: quantity,
        unitPrice: variation?.price ?? (product.descontoPercentual != null && product.descontoPercentual! > 0 ? product.preco * (1 - (product.descontoPercentual! / 100)) : product.preco),
        addedAt: DateTime.now(),
      );
      
      final docRef = await cartCollection.add(cartItem.toFirestore());
      
      // Adicionar à lista local
      _items.add(cartItem.copyWith(id: docRef.id));
      _clearError();
      notifyListeners();
      return true;
    }
  }

  // Adicionar item ao armazenamento local (usuário não logado)
  Future<bool> _addItemToLocal(Product product, ProductVariation? variation, int quantity) async {
    // Verificar se o item já existe
    final existingItem = _findExistingItem(product, variation);
    
    if (existingItem != null) {
      // Atualizar quantidade do item existente
      final newQuantity = existingItem.quantity + quantity;
      
      if (variation != null && newQuantity > variation.stock) {
        _setError('Quantidade total excede o estoque disponível');
        return false;
      }
      
      // Atualizar quantidade localmente
      final index = _items.indexWhere((item) => item.id == existingItem.id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
        await _saveLocalCart();
        _clearError();
        notifyListeners();
        return true;
      }
    } else {
      // Adicionar novo item
      final cartItem = CartItem(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}', // ID local único
        product: product,
        variation: variation,
        quantity: quantity,
        unitPrice: variation?.price ?? (product.descontoPercentual != null && product.descontoPercentual! > 0 ? product.preco * (1 - (product.descontoPercentual! / 100)) : product.preco),
        addedAt: DateTime.now(),
      );
      
      // Adicionar à lista local
      _items.add(cartItem);
      await _saveLocalCart();
      _clearError();
      notifyListeners();
      return true;
    }
    
    return false;
  }

  // Salvar carrinho local
  Future<void> _saveLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items.map((item) => item.toJson()).toList();
      await prefs.setString('local_cart', jsonEncode(cartData));
    } catch (e) {
      print('Erro ao salvar carrinho local: $e');
    }
  }

  // Carregar carrinho local
  Future<void> _loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('local_cart');
      
      if (cartString != null) {
        final cartData = jsonDecode(cartString) as List<dynamic>;
        _items = cartData.map((data) => CartItem.fromJson(data)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar carrinho local: $e');
    }
  }

  // Remover item do carrinho
  Future<bool> removeItem(String itemId) async {
    try {
      if (_auth.currentUser != null) {
        // Usuário logado - remover do Firebase
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final cartCollection = userDoc.collection('cart');
        
        await cartCollection.doc(itemId).delete();
      }
      
      // Remover da lista local
      _items.removeWhere((item) => item.id == itemId);
      
      // Se não está logado, salvar carrinho local
      if (_auth.currentUser == null) {
        await _saveLocalCart();
      }
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao remover item: $e');
      return false;
    }
  }

  // Atualizar quantidade de um item
  Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return removeItem(itemId);
    }

    try {
      if (_auth.currentUser != null) {
        // Usuário logado - atualizar no Firebase
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final cartCollection = userDoc.collection('cart');
        
        await cartCollection.doc(itemId).update({
          'quantity': newQuantity,
        });
      }
      
      // Atualizar na lista local
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
      
      // Se não está logado, salvar carrinho local
      if (_auth.currentUser == null) {
        await _saveLocalCart();
      }
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar quantidade: $e');
      return false;
    }
  }

  // Limpar carrinho
  Future<bool> clearCart() async {
    try {
      if (_auth.currentUser != null) {
        // Usuário logado - limpar do Firebase
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final cartCollection = userDoc.collection('cart');
        
        final batch = _firestore.batch();
        for (final item in _items) {
          batch.delete(cartCollection.doc(item.id));
        }
        await batch.commit();
      }
      
      // Limpar lista local
      _items.clear();
      
      // Se não está logado, salvar carrinho local vazio
      if (_auth.currentUser == null) {
        await _saveLocalCart();
      }
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao limpar carrinho: $e');
      return false;
    }
  }

  // Remover itens indisponíveis
  Future<bool> removeUnavailableItems() async {
    final unavailableItems = this.unavailableItems;
    if (unavailableItems.isEmpty) return true;

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final cartCollection = userDoc.collection('cart');
      
      final batch = _firestore.batch();
      for (final item in unavailableItems) {
        batch.delete(cartCollection.doc(item.id));
      }
      await batch.commit();
      
      _items.removeWhere((item) => !item.isAvailable);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao remover itens indisponíveis: $e');
      return false;
    }
  }

  // Verificar disponibilidade de todos os itens
  Future<void> checkAvailability() async {
    // Aqui você pode implementar uma verificação em tempo real
    // com o backend para confirmar estoque atual
    notifyListeners();
  }

  // Migrar carrinho local para Firebase quando usuário fizer login
  Future<void> migrateLocalCartToFirebase() async {
    if (_auth.currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('local_cart');
      
      if (cartString != null) {
        final cartData = jsonDecode(cartString) as List<dynamic>;
        final localItems = cartData.map((data) => CartItem.fromJson(data)).toList();
        
        if (localItems.isNotEmpty) {
          // Adicionar itens locais ao Firebase
          final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
          final cartCollection = userDoc.collection('cart');
          
          for (final item in localItems) {
            await cartCollection.add(item.toFirestore());
          }
          
          // Limpar carrinho local
          await prefs.remove('local_cart');
          
          // Recarregar carrinho do Firebase
          await initializeCart();
        }
      }
    } catch (e) {
      print('Erro ao migrar carrinho local: $e');
    }
  }

  // Métodos auxiliares
  CartItem? _findExistingItem(Product product, ProductVariation? variation) {
    try {
      return _items.firstWhere(
        (item) => 
          item.product.id == product.id && 
          item.variation?.id == variation?.id,
      );
    } catch (e) {
      // Item não encontrado
      return null;
    }
  }

  Future<void> _updateItemQuantity(String itemId, int newQuantity) async {
    final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
    final cartCollection = userDoc.collection('cart');
    
    await cartCollection.doc(itemId).update({
      'quantity': newQuantity,
    });
    
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Definir custo do frete
  void setShippingCost(double cost) {
    _shippingCost = cost;
    notifyListeners();
  }

  // Método para limpar estado (útil para logout)
  void clear() {
    _items.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Verificar se há pedidos aprovados e limpar carrinho se necessário
  Future<bool> checkAndClearCartIfPaymentApproved() async {
    if (_auth.currentUser == null) return false;
    
    try {
      // Buscar pedidos aprovados do usuário nos últimos 30 minutos
      final thirtyMinutesAgo = DateTime.now().subtract(Duration(minutes: 30));
      
      final ordersQuery = _firestore
          .collection('orders')
          .where('customer_email', isEqualTo: _auth.currentUser!.email)
          .where('status', isEqualTo: 'pagamento_aprovado')
          .where('created_at', isGreaterThan: thirtyMinutesAgo.toIso8601String())
          .limit(1);
      
      final ordersSnapshot = await ordersQuery.get();
      
      if (ordersSnapshot.docs.isNotEmpty) {
        // Há pedidos aprovados recentemente, limpar carrinho
        clear();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erro ao verificar pedidos aprovados: $e');
      return false;
    }
  }
}
