import 'product_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final Product product;
  final ProductVariation? variation;
  final int quantity;
  final double unitPrice;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    this.variation,
    required this.quantity,
    required this.unitPrice,
    required this.addedAt,
  });

  // Calcular preço total do item
  double get totalPrice => unitPrice * quantity;

  // Obter nome do item com variação
  String get displayName {
    if (variation != null) {
      return '${product.titulo} (${variation!.displayName})';
    }
    return product.titulo;
  }

  // Obter SKU do item
  String get sku {
    if (variation != null) {
      return variation!.sku;
    }
    return 'SKU-${product.id}';
  }

  // Verificar se o item ainda está disponível
  bool get isAvailable {
    if (variation != null) {
      return variation!.hasStock && quantity <= variation!.stock;
    }
    return product.isAvailable;
  }

  // Obter imagem do item
  String get imageUrl {
    if (variation != null && variation!.imageUrl != null) {
      return variation!.imageUrl!;
    }
    return product.images.isNotEmpty ? product.images.first : "";
  }

  // Factory para criar CartItem de JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromMap(json['product'] as Map<String, dynamic>, json['product']['id'] ?? ''),
      variation: json['variation'] != null 
          ? ProductVariation.fromJson(json['variation'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toMap(),
      'variation': variation?.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Factory para criar CartItem de Firestore
  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      product: Product.fromMap(data['product'] as Map<String, dynamic>, data['product']['id'] ?? ''),
      variation: data['variation'] != null 
          ? ProductVariation.fromJson(data['variation'] as Map<String, dynamic>)
          : null,
      quantity: data['quantity'] as int,
      unitPrice: (data['unitPrice'] as num).toDouble(),
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  // Converter para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'product': product.toMap(),
      'variation': variation?.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  // Criar cópia com quantidade atualizada
  CartItem copyWith({
    String? id,
    Product? product,
    ProductVariation? variation,
    int? quantity,
    double? unitPrice,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      variation: variation ?? this.variation,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartItem(id: $id, product: ${product.titulo}, variation: ${variation?.displayName}, quantity: $quantity, unitPrice: $unitPrice)';
  }
}
