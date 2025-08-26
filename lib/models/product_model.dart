class ProductVariation {
  final String skuId;
  final String? color;
  final String? size;
  final String? image; // link ou firebase storage
  final double preco;

  ProductVariation({
    required this.skuId,
    this.color,
    this.size,
    this.image,
    required this.preco,
  });

  Map<String, dynamic> toMap() {
    return {
      'sku_id': skuId,
      'cor': color,
      'tamanho': size,
      'image': image,
      'preco': preco,
    };
  }

  factory ProductVariation.fromMap(Map<String, dynamic> map) {
    return ProductVariation(
      skuId: map['sku_id'] ?? '',
      color: map['cor'],
      size: map['tamanho'],
      image: map['image'],
      preco: (map['preco'] ?? 0.0).toDouble(),
    );
  }

  // Getters para compatibilidade
  double get price => preco;
  bool get hasStock => true; // Por padrão sempre tem estoque
  int get stock => 999; // Estoque infinito por padrão
  String get id => skuId; // Usar skuId como id
  String get sku => skuId;
  String get imageUrl => image ?? '';
  String get displayName {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (size != null && size!.isNotEmpty) parts.add(size!);
    return parts.isEmpty ? 'Padrão' : parts.join(' - ');
  }

  // Compatibilidade com código antigo
  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }
}

class Product {
  final String? id;
  final String? aliexpressId;
  final List<String> images;
  final String titulo;
  final List<ProductVariation> variacoes;
  final String descricao;
  final double preco;
  final double? oferta;
  final double? descontoPercentual;
  final String marca;
  final String tipo;
  final String origem;
  final String categoria;
  final DateTime dataPost;
  final String idAdmin;
  final String? envio; // Campo para indicar tipo de envio (ex: "grátis", "pago")
  final String? secao; // Campo para indicar seção (ex: "Loja", "SexyShop")

  // Campos para compatibilidade com código antigo
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final double? weight;
  final double? length;
  final double? height;
  final double? width;
  final double? diameter; // Diâmetro para produtos cilíndricos
  final String? formato; // 'caixa' ou 'pacote'
  final Map<String, dynamic>? freightInfo;

  Product({
    this.id,
    this.aliexpressId,
    required this.images,
    required this.titulo,
    required this.variacoes,
    required this.descricao,
    required this.preco,
    this.oferta,
    this.descontoPercentual,
    required this.marca,
    required this.tipo,
    required this.origem,
    required this.categoria,
    required this.dataPost,
    required this.idAdmin,
    this.envio,
    this.secao,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.weight,
    this.length,
    this.height,
    this.width,
    this.diameter,
    this.formato,
    this.freightInfo,
  });

  // Getters para compatibilidade com código antigo
  String get name => titulo;
  String get description => descricao;
  double get price => preco;
  String get category => categoria;
  String get imageUrl => images.isNotEmpty ? images.first : '';
  List<ProductVariation> get variations => variacoes;
  bool get hasVariations => variacoes.isNotEmpty;
  
  // Getter para verificar se tem entrega grátis
  bool get hasFreeShipping {
    if (envio == null) return false;
    final envioLower = envio!.toLowerCase();
    return envioLower == 'grátis' || 
           envioLower == 'gratis' || 
           envioLower == 'free' ||
           envioLower == 'entrega gratis' ||
           envioLower == 'entrega grátis' ||
           envioLower.contains('gratis') ||
           envioLower.contains('grátis') ||
           envioLower.contains('free');
  }

  // Getters adicionais para compatibilidade
  List<String> get allImages => images;
  
  double get minPrice {
    if (variacoes.isEmpty) return preco;
    return variacoes.map((v) => v.preco).reduce((a, b) => a < b ? a : b);
  }
  
  double get maxPrice {
    if (variacoes.isEmpty) return preco;
    return variacoes.map((v) => v.preco).reduce((a, b) => a > b ? a : b);
  }

  // Métodos para compatibilidade
  List<String> get availableColors {
    final colors = <String>{};
    for (var variacao in variacoes) {
      if (variacao.color != null && variacao.color!.isNotEmpty) {
        colors.add(variacao.color!);
      }
    }
    return colors.toList();
  }

  List<String> get availableSizes {
    final sizes = <String>{};
    for (var variacao in variacoes) {
      if (variacao.size != null && variacao.size!.isNotEmpty) {
        sizes.add(variacao.size!);
      }
    }
    return sizes.toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'aliexpress_id': aliexpressId,
      'images': images,
      'titulo': titulo,
      'variacoes': variacoes.map((v) => v.toMap()).toList(),
      'descricao': descricao,
      'preco': preco,
      'oferta': oferta,
      'desconto_percentual': descontoPercentual,
      'marca': marca,
      'tipo': tipo,
      'origem': origem,
      'categoria': categoria,
      'data_post': dataPost.toIso8601String(),
      'id_admin': idAdmin,
      'envio': envio,
      'secao': secao,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'weight': weight,
      'length': length,
      'height': height,
      'width': width,
      'diameter': diameter,
      'formato': formato,
      'freightInfo': freightInfo,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      aliexpressId: map['aliexpress_id'],
      images: List<String>.from(map['images'] ?? []),
      titulo: map['titulo'] ?? '',
      variacoes: (map['variacoes'] as List<dynamic>?)
          ?.map((v) => ProductVariation.fromMap(v))
          .toList() ?? [],
      descricao: map['descricao'] ?? '',
      preco: (map['preco'] ?? 0.0).toDouble(),
      oferta: map['oferta']?.toDouble(),
      descontoPercentual: map['desconto_percentual']?.toDouble(),
      marca: map['marca'] ?? '',
      tipo: map['tipo'] ?? '',
      origem: map['origem'] ?? '',
      categoria: map['categoria'] ?? '',
      dataPost: _parseDateTime(map['data_post']),
      idAdmin: map['id_admin'] ?? '',
      envio: map['envio'],
      secao: map['secao'],
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      weight: map['weight']?.toDouble(),
      length: map['length']?.toDouble(),
      height: map['height']?.toDouble(),
      width: map['width']?.toDouble(),
      diameter: map['diameter']?.toDouble(),
      formato: map['formato'],
      freightInfo: map['freightInfo'] as Map<String, dynamic>?,
    );
  }

  // Compatibilidade com código antigo
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMap(json, json['id'] ?? '');
  }

  factory Product.fromFirestore(dynamic doc, {bool isLocal = true}) {
    if (doc is Map<String, dynamic>) {
      return Product.fromMap(doc, doc['id'] ?? '');
    }
    // Se for DocumentSnapshot
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  Product copyWith({
    String? id,
    String? aliexpressId,
    List<String>? images,
    String? titulo,
    List<ProductVariation>? variacoes,
    String? descricao,
    double? preco,
    double? oferta,
    double? descontoPercentual,
    String? marca,
    String? tipo,
    String? origem,
    String? categoria,
    DateTime? dataPost,
    String? idAdmin,
    String? envio,
    String? secao,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    double? weight,
    double? length,
    double? height,
    double? width,
    Map<String, dynamic>? freightInfo,
  }) {
    return Product(
      id: id ?? this.id,
      aliexpressId: aliexpressId ?? this.aliexpressId,
      images: images ?? this.images,
      titulo: titulo ?? this.titulo,
      variacoes: variacoes ?? this.variacoes,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      oferta: oferta ?? this.oferta,
      descontoPercentual: descontoPercentual ?? this.descontoPercentual,
      marca: marca ?? this.marca,
      tipo: tipo ?? this.tipo,
      origem: origem ?? this.origem,
      categoria: categoria ?? this.categoria,
      dataPost: dataPost ?? this.dataPost,
      idAdmin: idAdmin ?? this.idAdmin,
      envio: envio ?? this.envio,
      secao: secao ?? this.secao,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      height: height ?? this.height,
      width: width ?? this.width,
      freightInfo: freightInfo ?? this.freightInfo,
    );
  }

  // Método auxiliar para parse seguro de DateTime
  static DateTime _parseDateTime(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    } catch (e) {
      print('Erro ao fazer parse da data: $e');
      return DateTime.now();
    }
  }
}
