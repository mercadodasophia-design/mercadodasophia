import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_variation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> images; // Lista de todas as imagens do produto
  final String category;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final bool isLocal; // Novo campo para identificar se é produto local ou importado
  final List<ProductVariation> variations; // Lista de variações/SKUs
  final bool hasVariations; // Indica se o produto tem variações
  
  // Campos para cálculo de frete
  final double? weight; // Peso em kg
  final double? length; // Comprimento em cm
  final double? height; // Altura em cm
  final double? width; // Largura em cm

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.images = const [],
    required this.category,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isLocal = true, // Por padrão é local
    this.variations = const [],
    this.weight,
    this.length,
    this.height,
    this.width,
  }) : hasVariations = variations.isNotEmpty;

  factory Product.fromJson(Map<String, dynamic> json) {
    List<ProductVariation> variations = [];
    if (json['variations'] != null) {
      variations = (json['variations'] as List)
          .map((v) => ProductVariation.fromJson(v))
          .toList();
    }

    // Processar lista de imagens
    List<String> images = [];
    if (json['images'] != null) {
      images = List<String>.from(json['images']);
    } else if (json['imageUrl'] != null) {
      // Se não há lista de imagens, usar a imagem principal
      images = [json['imageUrl']];
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: _parsePrice(json['price']),
      imageUrl: json['imageUrl'],
      images: images,
      category: json['category'],
      isAvailable: json['isAvailable'] ?? true,
      rating: _parseRating(json['rating']),
      reviewCount: _parseReviewCount(json['reviewCount']),
      isLocal: json['isLocal'] ?? true,
      variations: variations,
      weight: _parseDouble(json['weight']),
      length: _parseDouble(json['length']),
      height: _parseDouble(json['height']),
      width: _parseDouble(json['width']),
    );
  }

  // Construtor para produtos do Firestore
  factory Product.fromFirestore(DocumentSnapshot doc, {bool isLocal = true}) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<ProductVariation> variations = [];
    if (data['variations'] != null) {
      variations = _parseOrganizedVariations(data['variations']);
    }
    
    // Processar lista de imagens do Firestore
    List<String> images = [];
    if (data['images'] != null) {
      images = List<String>.from(data['images']);
    } else if (data['main_image'] != null || data['imageUrl'] != null || data['itemMainPic'] != null || data['mainImage'] != null) {
      // Se não há lista de imagens, usar a imagem principal
      final mainImage = data['main_image'] ?? data['imageUrl'] ?? data['itemMainPic'] ?? data['mainImage'] ?? '';
      if (mainImage.isNotEmpty) {
        images = [mainImage];
      }
    }

    return Product(
      id: doc.id,
      name: data['name'] ?? data['title'] ?? 'Produto sem nome',
      description: data['description'] ?? '',
      price: _parsePrice(data['price'] ?? data['targetSalePrice'] ?? 0.0),
      imageUrl: data['main_image'] ?? data['imageUrl'] ?? data['itemMainPic'] ?? data['mainImage'] ?? '',
      images: images,
      category: data['category'] ?? data['categoryName'] ?? 'Sem categoria',
      isAvailable: _calculateAvailability(data, variations),
      rating: _parseRating(data['rating'] ?? data['score'] ?? 0.0),
      reviewCount: _parseReviewCount(data['reviewCount'] ?? data['orders'] ?? 0),
      isLocal: isLocal,
      variations: variations,
      weight: _parseDouble(data['weight']),
      length: _parseDouble(data['length']),
      height: _parseDouble(data['height']),
      width: _parseDouble(data['width']),
    );
  }

  // Construtor para produtos do AliExpress
  factory Product.fromAliExpress(Map<String, dynamic> data, {bool isLocal = false}) {
    List<ProductVariation> variations = [];
    if (data['skuProps'] != null) {
      variations = _parseAliExpressVariations(data);
    }

    // Processar lista de imagens do AliExpress
    List<String> images = [];
    if (data['images'] != null) {
      images = List<String>.from(data['images']);
    } else if (data['itemMainPic'] != null || data['mainImage'] != null || data['imageUrl'] != null) {
      // Se não há lista de imagens, usar a imagem principal
      final mainImage = data['itemMainPic'] ?? data['mainImage'] ?? data['imageUrl'] ?? '';
      if (mainImage.isNotEmpty) {
        images = [mainImage];
      }
    }

    return Product(
      id: data['itemId']?.toString() ?? data['id']?.toString() ?? '',
      name: data['title'] ?? data['itemTitle'] ?? data['productTitle'] ?? 'Produto sem nome',
      description: data['description'] ?? '',
      price: _parsePrice(data['targetSalePrice'] ?? data['price'] ?? 0.0),
      imageUrl: data['itemMainPic'] ?? data['mainImage'] ?? data['imageUrl'] ?? '',
      images: images,
      category: data['category'] ?? 'Importado',
      isAvailable: true,
      rating: _parseRating(data['score'] ?? data['evaluateRate'] ?? 0.0),
      reviewCount: _parseReviewCount(data['orders'] ?? data['sales'] ?? 0),
      isLocal: isLocal,
      variations: variations,
      weight: _parseDouble(data['weight']),
      length: _parseDouble(data['length']),
      height: _parseDouble(data['height']),
      width: _parseDouble(data['width']),
    );
  }

  // Método para calcular disponibilidade considerando variações
  static bool _calculateAvailability(Map<String, dynamic> data, List<ProductVariation> variations) {
    // Se tem variações, verificar se pelo menos uma tem estoque
    if (variations.isNotEmpty) {
      return variations.any((variation) => variation.hasStock);
    }
    
    // Se não tem variações, verificar estoque principal
    final stock = data['stock'];
    if (stock != null) {
      if (stock is int) return stock > 0;
      if (stock is double) return stock > 0;
      if (stock is String) {
        final stockNum = double.tryParse(stock);
        return stockNum != null && stockNum > 0;
      }
    }
    
    // Se não tem informação de estoque, considerar disponível
    return true;
  }

  // Método para converter variações (organizadas ou planas) para formato padrão
  static List<ProductVariation> _parseOrganizedVariations(dynamic variationsData) {
    List<ProductVariation> variations = [];
    
    if (variationsData == null || variationsData is! List || variationsData.isEmpty) {
      return variations;
    }
    
    final firstItem = variationsData[0];
    if (firstItem is! Map<String, dynamic>) {
      return variations;
    }
    
    // Verificar se é formato organizado (por tamanho → cores)
    if (firstItem.containsKey('size') && firstItem.containsKey('colors')) {
      print('📋 Detectado formato organizado - processando por tamanho → cores');
      
      for (var sizeGroup in variationsData) {
        if (sizeGroup is Map<String, dynamic>) {
          final size = sizeGroup['size']?.toString();
          final colors = sizeGroup['colors'] as Map<String, dynamic>?;
          
          if (colors != null) {
            colors.forEach((colorName, colorData) {
              if (colorData is Map<String, dynamic>) {
                final skuId = colorData['sku_id']?.toString() ?? '';
                final price = _parsePrice(colorData['price'] ?? 0.0);
                final stock = _parseStock(colorData['stock']);
                
                                 if (skuId.isNotEmpty) {
                   // Verificar se size é realmente um tamanho ou se é null/igual à cor
                   String? finalSize = size;
                   if (size == null || size.isEmpty || size == colorName) {
                     finalSize = null; // Sem tamanho real
                   }
                   
                   variations.add(ProductVariation(
                     id: skuId,
                     productId: '',
                     color: colorName,
                     size: finalSize,
                     price: price,
                     stock: stock,
                     sku: skuId,
                   ));
                 }
              }
            });
          }
        }
      }
      
      print('✅ Variações organizadas processadas: ${variations.length} variações');
    } else if (firstItem.containsKey('color') && firstItem.containsKey('stock')) {
      // Formato plano (cada item tem color, size, stock diretamente)
      print('📋 Detectado formato plano - processando variações individuais');
      
      for (var variation in variationsData) {
        if (variation is Map<String, dynamic>) {
          final color = variation['color']?.toString() ?? '';
          final size = variation['size']?.toString() ?? '';
          final stock = _parseStock(variation['stock']);
          final price = _parsePrice(variation['price'] ?? 0.0);
          final skuId = variation['sku']?.toString() ?? '';
          
                     if (skuId.isNotEmpty) {
             // Verificar se size é realmente um tamanho ou se é igual à cor
             String? finalSize = size.isNotEmpty ? size : null;
             if (finalSize != null && finalSize == color) {
               finalSize = null; // Sem tamanho real
             }
             
             variations.add(ProductVariation(
               id: skuId,
               productId: '',
               color: color,
               size: finalSize,
               price: price,
               stock: stock,
               sku: skuId,
             ));
           }
        }
      }
      
      print('✅ Variações planas processadas: ${variations.length} variações');
    } else {
      print('⚠️ Formato de variações não reconhecido');
    }
    
    print('🔄 Total de variações: ${variations.length}');
    return variations;
  }

  // Método para parsear estoque
  static int _parseStock(dynamic stock) {
    if (stock == null) return 0;
    if (stock is int) return stock;
    if (stock is double) return stock.toInt();
    if (stock is String) {
      final stockNum = double.tryParse(stock);
      return stockNum?.toInt() ?? 0;
    }
    return 0;
  }

  // Método para parsear variações do AliExpress
  static List<ProductVariation> _parseAliExpressVariations(Map<String, dynamic> data) {
    List<ProductVariation> variations = [];
    
    if (data['skuProps'] == null) return variations;

    try {
      final skuProps = data['skuProps'] as List;
      final skuPrices = data['skuPrices'] as List?;
      final skuStocks = data['skuStocks'] as List?;

      for (int i = 0; i < skuProps.length; i++) {
        final prop = skuProps[i];
        final propName = prop['propName']?.toString().toLowerCase() ?? '';
        final propValues = prop['propValues'] as List? ?? [];

        for (int j = 0; j < propValues.length; j++) {
          final value = propValues[j];
          final valueName = value['name']?.toString() ?? '';
          
          // Determinar se é cor ou tamanho
          String? color;
          String? size;
          
          if (propName.contains('cor') || propName.contains('color')) {
            color = valueName;
          } else if (propName.contains('tamanho') || propName.contains('size')) {
            size = valueName;
          }

          // Calcular preço e estoque
          double price = _parsePrice(data['targetSalePrice'] ?? data['price'] ?? 0.0);
          int stock = 100; // Estoque padrão

          if (skuPrices != null && i < skuPrices.length) {
            final skuPrice = skuPrices[i];
            if (skuPrice['price'] != null) {
              price = _parsePrice(skuPrice['price']);
            }
          }

          if (skuStocks != null && i < skuStocks.length) {
            final skuStock = skuStocks[i];
            if (skuStock['stock'] != null) {
              stock = int.tryParse(skuStock['stock'].toString()) ?? 100;
            }
          }

          // Gerar SKU único
          final sku = '${data['itemId']}_${color ?? 'default'}_${size ?? 'default'}';

          variations.add(ProductVariation(
            id: '${data['itemId']}_$i',
            productId: data['itemId']?.toString() ?? '',
            color: color,
            size: size,
            price: price,
            stock: stock,
            imageUrl: value['imageUrl'],
            sku: sku,
          ));
        }
      }
    } catch (e) {
      print('Erro ao parsear variações do AliExpress: $e');
    }

    return variations;
  }

  // Métodos auxiliares para parsing
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      final cleanPrice = price.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      if (cleanPrice.isEmpty) return 0.0;
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) {
      final cleanRating = rating.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      if (cleanRating.isEmpty) return 0.0;
      return double.tryParse(cleanRating) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseReviewCount(dynamic count) {
    if (count == null) return 0;
    if (count is int) return count;
    if (count is double) return count.toInt();
    if (count is String) {
      final cleanCount = count.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanCount.isEmpty) return 0;
      return int.tryParse(cleanCount) ?? 0;
    }
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanValue = value.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      if (cleanValue.isEmpty) return null;
      return double.tryParse(cleanValue);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'images': images,
      'category': category,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'isLocal': isLocal,
      'variations': variations.map((v) => v.toJson()).toList(),
      'weight': weight,
      'length': length,
      'height': height,
      'width': width,
    };
  }

  // Métodos auxiliares para variações
  List<String> get availableColors {
    return variations
        .where((v) => v.color != null && v.hasStock)
        .map((v) => v.color!)
        .toSet()
        .toList();
  }

  List<String> get availableSizes {
    return variations
        .where((v) => v.size != null && v.hasStock)
        .map((v) => v.size!)
        .toSet()
        .toList();
  }

  double get minPrice {
    if (variations.isEmpty) return price;
    return variations.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (variations.isEmpty) return price;
    return variations.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  ProductVariation? getVariation({String? color, String? size}) {
    return variations.firstWhere(
      (v) => v.color == color && v.size == size,
      orElse: () => ProductVariation(
        id: '',
        productId: id,
        color: color,
        size: size,
        price: price,
        stock: 0,
        sku: '',
      ),
    );
  }

  // Getter para obter todas as imagens disponíveis
  List<String> get allImages {
    List<String> allImages = [];
    
    // Adicionar imagem principal se existir
    if (imageUrl.isNotEmpty) {
      allImages.add(imageUrl);
    }
    
    // Adicionar imagens da lista de imagens
    allImages.addAll(images);
    
    // Adicionar imagens das variações que têm imagens específicas
    for (var variation in variations) {
      if (variation.imageUrl != null && variation.imageUrl!.isNotEmpty) {
        allImages.add(variation.imageUrl!);
      }
    }
    
    // Remover duplicatas e retornar
    return allImages.toSet().toList();
  }
} 