class Banner {
  final String id;
  final String nome;
  final String image;
  final DateTime data;
  final String? linkProduto;
  final bool isAtivo;
  final String idAdmin;
  final String? secao;

  Banner({
    required this.id,
    required this.nome,
    required this.image,
    required this.data,
    this.linkProduto,
    required this.isAtivo,
    required this.idAdmin,
    this.secao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'image': image,
      'data': data.toIso8601String(),
      'linkProduto': linkProduto,
      'isAtivo': isAtivo,
      'idAdmin': idAdmin,
      'secao': secao,
    };
  }

  factory Banner.fromMap(Map<String, dynamic> map) {
    return Banner(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      image: map['image'] ?? '',
      data: DateTime.tryParse(map['data'] ?? '') ?? DateTime.now(),
      linkProduto: map['linkProduto'],
      isAtivo: map['isAtivo'] ?? true,
      idAdmin: map['idAdmin'] ?? '',
      secao: map['secao'],
    );
  }

  Banner copyWith({
    String? id,
    String? nome,
    String? image,
    DateTime? data,
    String? linkProduto,
    bool? isAtivo,
    String? idAdmin,
    String? secao,
  }) {
    return Banner(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      image: image ?? this.image,
      data: data ?? this.data,
      linkProduto: linkProduto ?? this.linkProduto,
      isAtivo: isAtivo ?? this.isAtivo,
      idAdmin: idAdmin ?? this.idAdmin,
      secao: secao ?? this.secao,
    );
  }
}
