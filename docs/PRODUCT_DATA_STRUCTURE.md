# Estrutura de Dados dos Produtos

## 📋 Visão Geral

Este documento descreve a estrutura completa dos dados de produtos implementada no sistema e-commerce Mercado da Sophia.

## 🗂️ Estrutura no Firestore

### Coleção: `products`
Cada documento representa um produto único com ID automático do Firestore.

## 📊 Estrutura do Documento

### Campos Principais

```json
{
  "aliexpress_id": "string | null",
  "images": ["string"],
  "titulo": "string",
  "variacoes": [
    {
      "sku_id": "string",
      "cor": "string | null",
      "tamanho": "string | null", 
      "image": "string | null",
      "preco": "number"
    }
  ],
  "descricao": "string",
  "preco": "number",
  "oferta": "number | null",
  "desconto_percentual": "number | null",
  "marca": "string",
  "tipo": "string",
  "origem": "string",
  "categoria": "string",
  "data_post": "timestamp",
  "id_admin": "string",
  "envio": "string | null"
}
```

## 🔍 Detalhamento dos Campos

### Informações Básicas
- **`aliexpress_id`**: ID do produto no AliExpress (opcional)
- **`images`**: Array de URLs das imagens do produto
- **`titulo`**: Título/nome do produto
- **`descricao`**: Descrição detalhada do produto (HTML/rich text)

### Preços e Ofertas
- **`preco`**: Preço base do produto (obrigatório)
- **`oferta`**: Preço com desconto (opcional)
- **`desconto_percentual`**: Percentual de desconto (opcional)

### Categorização
- **`marca`**: Marca do produto
- **`tipo`**: Tipo/categoria do produto
- **`origem`**: Origem do produto (ex: "Importado", "Nacional")
- **`categoria`**: Categoria principal do produto
- **`envio`**: Tipo de envio (ex: "grátis", "pago", "free")

### Variações
- **`variacoes`**: Array de variações do produto
  - **`sku_id`**: ID único da variação
  - **`cor`**: Cor da variação (opcional)
  - **`tamanho`**: Tamanho da variação (opcional)
  - **`image`**: Imagem específica da variação (opcional)
  - **`preco`**: Preço específico da variação

### Metadados
- **`data_post`**: Data de criação do produto
- **`id_admin`**: ID do administrador que criou o produto

## 🏗️ Modelo Flutter

### ProductVariation
```dart
class ProductVariation {
  final String skuId;
  final String? color;
  final String? size;
  final String? image;
  final double preco;
}
```

### Product
```dart
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
  final String? envio;
}
```

## 🔄 Conversões

### Para Firestore (toMap)
```dart
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
  };
}
```

### Do Firestore (fromMap)
```dart
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
    dataPost: DateTime.parse(map['data_post'] ?? DateTime.now().toIso8601String()),
    idAdmin: map['id_admin'] ?? '',
    envio: map['envio'],
  );
}
```

## 📱 Uso na Loja

### Exemplo de Produto na Loja
```dart
// Buscar produtos do Firestore
final products = await FirebaseFirestore.instance
    .collection('products')
    .orderBy('data_post', descending: true)
    .get();

// Converter para objetos Product
final productList = products.docs
    .map((doc) => Product.fromMap(doc.data(), doc.id))
    .toList();
```

### Exemplo de Variação
```dart
// Mostrar variações disponíveis
for (var variacao in product.variacoes) {
  print('SKU: ${variacao.skuId}');
  print('Cor: ${variacao.color}');
  print('Tamanho: ${variacao.size}');
  print('Preço: R\$ ${variacao.preco}');
}
```

## 🎯 Casos de Uso

### 1. Produto Simples (sem variações)
```json
{
  "titulo": "Camiseta Básica",
  "images": ["url1", "url2"],
  "variacoes": [],
  "preco": 29.90,
  "categoria": "Roupas"
}
```

### 2. Produto com Variações
```json
{
  "titulo": "Tênis Esportivo",
  "images": ["url1", "url2", "url3"],
  "variacoes": [
    {
      "sku_id": "tenis_azul_40",
      "cor": "Azul",
      "tamanho": "40",
      "preco": 89.90
    },
    {
      "sku_id": "tenis_azul_41", 
      "cor": "Azul",
      "tamanho": "41",
      "preco": 89.90
    }
  ],
  "preco": 89.90,
  "categoria": "Calçados"
}
```

### 3. Produto com Oferta
```json
{
  "titulo": "Smartphone",
  "preco": 999.90,
  "oferta": 799.90,
  "desconto_percentual": 20.0,
  "categoria": "Eletrônicos"
}
```

### 4. Produto com Entrega Grátis
```json
{
  "titulo": "Camiseta Premium",
  "preco": 89.90,
  "categoria": "Roupas",
  "envio": "grátis"
}
```

## 🔧 Regras de Negócio

1. **Preços**: Sempre em números (double)
2. **Imagens**: URLs válidas ou Firebase Storage paths
3. **Variações**: Cada variação deve ter SKU único
4. **Categorias**: Usar categorias padronizadas
5. **Datas**: Sempre em formato ISO 8601
6. **Ofertas**: Percentual calculado automaticamente pela loja
7. **Envio**: Campo opcional que indica tipo de envio ("grátis", "pago", "free")

## 📝 Notas Importantes

- A loja calcula automaticamente o preço com desconto baseado no `desconto_percentual`
- Variações podem ter preços diferentes do produto base
- Imagens das variações substituem a imagem principal quando selecionadas
- Todos os campos obrigatórios devem ser preenchidos no painel admin
- A estrutura é compatível com web e mobile
- O campo `envio` com valor "grátis" ou "free" exibe "Entrega Grátis" nos cards de produtos






