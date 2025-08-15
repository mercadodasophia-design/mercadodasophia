import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/product_variation.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

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

  // Inicializar carrinho
  Future<void> initializeCart() async {
    if (_auth.currentUser == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final cartCollection = userDoc.collection('cart');
      
      final querySnapshot = await cartCollection.get();
      
      _items = querySnapshot.docs.map((doc) {
        return CartItem.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar carrinho: $e');
      _setLoading(false);
    }
  }

    // Adicionar item ao carrinho
  Future<bool> addItem(Product product, {ProductVariation? variation, int quantity = 1}) async {
    if (_auth.currentUser == null) {
      _setError('Usuário não autenticado. Faça login para adicionar itens ao carrinho.');
      return false;
    }

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
          unitPrice: variation?.price ?? product.price,
          addedAt: DateTime.now(),
        );
        
        final docRef = await cartCollection.add(cartItem.toFirestore());
        
        // Adicionar à lista local
        _items.add(cartItem.copyWith(id: docRef.id));
        _clearError();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Erro ao adicionar item: $e');
      return false;
    }
  }

  // Remover item do carrinho
  Future<bool> removeItem(String itemId) async {
    if (_auth.currentUser == null) return false;

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final cartCollection = userDoc.collection('cart');
      
      await cartCollection.doc(itemId).delete();
      
      _items.removeWhere((item) => item.id == itemId);
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
    if (_auth.currentUser == null) return false;
    if (newQuantity <= 0) {
      return removeItem(itemId);
    }

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final cartCollection = userDoc.collection('cart');
      
      await cartCollection.doc(itemId).update({
        'quantity': newQuantity,
      });
      
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
        _clearError();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Erro ao atualizar quantidade: $e');
      return false;
    }
  }

  // Limpar carrinho
  Future<bool> clearCart() async {
    if (_auth.currentUser == null) return false;

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final cartCollection = userDoc.collection('cart');
      
      final batch = _firestore.batch();
      for (final item in _items) {
        batch.delete(cartCollection.doc(item.id));
      }
      await batch.commit();
      
      _items.clear();
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

  // Método para limpar estado (útil para logout)
  void clear() {
    _items.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
