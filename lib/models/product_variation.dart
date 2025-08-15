import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariation {
  final String id;
  final String productId;
  final String? color;
  final String? size;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isAvailable;
  final String sku; // Código único do SKU

  ProductVariation({
    required this.id,
    required this.productId,
    this.color,
    this.size,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.isAvailable = true,
    required this.sku,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      color: json['color'],
      size: json['size'],
      price: _parsePrice(json['price'] ?? 0.0),
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      sku: json['sku'] ?? '',
    );
  }

  factory ProductVariation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ProductVariation(
      id: doc.id,
      productId: data['productId'] ?? '',
      color: data['color'],
      size: data['size'],
      price: _parsePrice(data['price'] ?? 0.0),
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      sku: data['sku'] ?? '',
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'color': color,
      'size': size,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'sku': sku,
    };
  }

  // Gera um nome descritivo para a variação
  String get displayName {
    List<String> parts = [];
    if (color != null) parts.add(color!);
    if (size != null) parts.add(size!);
    return parts.isEmpty ? 'Padrão' : parts.join(' - ');
  }

  // Verifica se tem estoque
  bool get hasStock => stock > 0;

  // Verifica se a variação é válida (tem pelo menos cor ou tamanho)
  bool get isValid => color != null || size != null;
}

// Modelo para agrupar variações por características
class ProductVariationGroup {
  final String? color;
  final String? size;
  final List<ProductVariation> variations;
  final double minPrice;
  final double maxPrice;
  final int totalStock;
  final bool hasStock;

  ProductVariationGroup({
    this.color,
    this.size,
    required this.variations,
  }) : 
    minPrice = variations.map((v) => v.price).reduce((a, b) => a < b ? a : b),
    maxPrice = variations.map((v) => v.price).reduce((a, b) => a > b ? a : b),
    totalStock = variations.fold(0, (sum, v) => sum + v.stock),
    hasStock = variations.any((v) => v.hasStock);

  // Gera um nome descritivo para o grupo
  String get displayName {
    List<String> parts = [];
    if (color != null) parts.add(color!);
    if (size != null) parts.add(size!);
    return parts.isEmpty ? 'Padrão' : parts.join(' - ');
  }

  // Retorna a variação com menor preço
  ProductVariation? get cheapestVariation {
    if (variations.isEmpty) return null;
    return variations.reduce((a, b) => a.price < b.price ? a : b);
  }

  // Retorna a variação com maior preço
  ProductVariation? get mostExpensiveVariation {
    if (variations.isEmpty) return null;
    return variations.reduce((a, b) => a.price > b.price ? a : b);
  }
}
