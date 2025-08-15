import '../models/product.dart';
import '../models/product_variation.dart';

class ProductWithVariationsExample {
  // Exemplo de produto com variações de cor e tamanho
  static Product createTShirtExample() {
    return Product(
      id: 'tshirt_001',
      name: 'Camiseta Básica Premium',
      description: 'Camiseta de algodão 100% com corte moderno e confortável. Disponível em várias cores e tamanhos.',
      price: 49.90, // Preço base
      imageUrl: 'https://example.com/tshirt.jpg',
      images: [
        'https://example.com/tshirt_front.jpg',
        'https://example.com/tshirt_back.jpg',
        'https://example.com/tshirt_detail.jpg',
        'https://example.com/tshirt_fit.jpg',
      ],
      category: 'Roupas',
      weight: 0.2, // 200g
      length: 20.0, // 20cm
      height: 2.0, // 2cm
      width: 15.0, // 15cm
      variations: [
        // Variações por cor e tamanho
        ProductVariation(
          id: 'tshirt_001_black_p',
          productId: 'tshirt_001',
          color: 'Preto',
          size: 'P',
          price: 49.90,
          stock: 15,
          sku: 'TSHIRT-BLK-P',
        ),
        ProductVariation(
          id: 'tshirt_001_black_m',
          productId: 'tshirt_001',
          color: 'Preto',
          size: 'M',
          price: 49.90,
          stock: 25,
          sku: 'TSHIRT-BLK-M',
        ),
        ProductVariation(
          id: 'tshirt_001_black_g',
          productId: 'tshirt_001',
          color: 'Preto',
          size: 'G',
          price: 49.90,
          stock: 20,
          sku: 'TSHIRT-BLK-G',
        ),
        ProductVariation(
          id: 'tshirt_001_white_p',
          productId: 'tshirt_001',
          color: 'Branco',
          size: 'P',
          price: 49.90,
          stock: 10,
          sku: 'TSHIRT-WHT-P',
        ),
        ProductVariation(
          id: 'tshirt_001_white_m',
          productId: 'tshirt_001',
          color: 'Branco',
          size: 'M',
          price: 49.90,
          stock: 18,
          sku: 'TSHIRT-WHT-M',
        ),
        ProductVariation(
          id: 'tshirt_001_white_g',
          productId: 'tshirt_001',
          color: 'Branco',
          size: 'G',
          price: 49.90,
          stock: 12,
          sku: 'TSHIRT-WHT-G',
        ),
        ProductVariation(
          id: 'tshirt_001_blue_p',
          productId: 'tshirt_001',
          color: 'Azul',
          size: 'P',
          price: 54.90, // Preço diferente para azul
          stock: 8,
          sku: 'TSHIRT-BLU-P',
        ),
        ProductVariation(
          id: 'tshirt_001_blue_m',
          productId: 'tshirt_001',
          color: 'Azul',
          size: 'M',
          price: 54.90,
          stock: 15,
          sku: 'TSHIRT-BLU-M',
        ),
        ProductVariation(
          id: 'tshirt_001_blue_g',
          productId: 'tshirt_001',
          color: 'Azul',
          size: 'G',
          price: 54.90,
          stock: 10,
          sku: 'TSHIRT-BLU-G',
        ),
      ],
    );
  }

  // Exemplo de produto apenas com cores (sem tamanhos)
  static Product createPhoneCaseExample() {
    return Product(
      id: 'case_001',
      name: 'Capa para iPhone 15',
      description: 'Capa protetora de silicone premium para iPhone 15. Disponível em várias cores vibrantes.',
      price: 29.90,
      imageUrl: 'https://example.com/phonecase.jpg',
      images: [
        'https://example.com/phonecase_front.jpg',
        'https://example.com/phonecase_back.jpg',
        'https://example.com/phonecase_side.jpg',
      ],
      category: 'Acessórios',
      weight: 0.1, // 100g
      length: 15.0, // 15cm
      height: 1.0, // 1cm
      width: 8.0, // 8cm
      variations: [
        ProductVariation(
          id: 'case_001_black',
          productId: 'case_001',
          color: 'Preto',
          price: 29.90,
          stock: 50,
          sku: 'CASE-BLK',
        ),
        ProductVariation(
          id: 'case_001_white',
          productId: 'case_001',
          color: 'Branco',
          price: 29.90,
          stock: 45,
          sku: 'CASE-WHT',
        ),
        ProductVariation(
          id: 'case_001_red',
          productId: 'case_001',
          color: 'Vermelho',
          price: 34.90, // Preço premium para vermelho
          stock: 30,
          sku: 'CASE-RED',
        ),
        ProductVariation(
          id: 'case_001_blue',
          productId: 'case_001',
          color: 'Azul',
          price: 29.90,
          stock: 35,
          sku: 'CASE-BLU',
        ),
      ],
    );
  }

  // Exemplo de produto apenas com tamanhos (sem cores)
  static Product createSneakersExample() {
    return Product(
      id: 'sneakers_001',
      name: 'Tênis Esportivo Comfort',
      description: 'Tênis esportivo com tecnologia de amortecimento avançada. Disponível em vários tamanhos.',
      price: 199.90,
      imageUrl: 'https://example.com/sneakers.jpg',
      images: [
        'https://example.com/sneakers_front.jpg',
        'https://example.com/sneakers_side.jpg',
        'https://example.com/sneakers_back.jpg',
        'https://example.com/sneakers_sole.jpg',
      ],
      category: 'Calçados',
      weight: 0.8, // 800g
      length: 30.0, // 30cm
      height: 12.0, // 12cm
      width: 10.0, // 10cm
      variations: [
        ProductVariation(
          id: 'sneakers_001_36',
          productId: 'sneakers_001',
          size: '36',
          price: 199.90,
          stock: 8,
          sku: 'SNEAKERS-36',
        ),
        ProductVariation(
          id: 'sneakers_001_37',
          productId: 'sneakers_001',
          size: '37',
          price: 199.90,
          stock: 12,
          sku: 'SNEAKERS-37',
        ),
        ProductVariation(
          id: 'sneakers_001_38',
          productId: 'sneakers_001',
          size: '38',
          price: 199.90,
          stock: 15,
          sku: 'SNEAKERS-38',
        ),
        ProductVariation(
          id: 'sneakers_001_39',
          productId: 'sneakers_001',
          size: '39',
          price: 199.90,
          stock: 20,
          sku: 'SNEAKERS-39',
        ),
        ProductVariation(
          id: 'sneakers_001_40',
          productId: 'sneakers_001',
          size: '40',
          price: 199.90,
          stock: 25,
          sku: 'SNEAKERS-40',
        ),
        ProductVariation(
          id: 'sneakers_001_41',
          productId: 'sneakers_001',
          size: '41',
          price: 199.90,
          stock: 18,
          sku: 'SNEAKERS-41',
        ),
        ProductVariation(
          id: 'sneakers_001_42',
          productId: 'sneakers_001',
          size: '42',
          price: 199.90,
          stock: 15,
          sku: 'SNEAKERS-42',
        ),
        ProductVariation(
          id: 'sneakers_001_43',
          productId: 'sneakers_001',
          size: '43',
          price: 199.90,
          stock: 10,
          sku: 'SNEAKERS-43',
        ),
        ProductVariation(
          id: 'sneakers_001_44',
          productId: 'sneakers_001',
          size: '44',
          price: 199.90,
          stock: 8,
          sku: 'SNEAKERS-44',
        ),
      ],
    );
  }

  // Exemplo de produto sem variações
  static Product createSimpleProductExample() {
    return Product(
      id: 'book_001',
      name: 'Livro: A Arte da Programação',
      description: 'Livro completo sobre programação e desenvolvimento de software.',
      price: 89.90,
      imageUrl: 'https://example.com/book.jpg',
      images: [
        'https://example.com/book_cover.jpg',
        'https://example.com/book_back.jpg',
        'https://example.com/book_pages.jpg',
      ],
      category: 'Livros',
      weight: 0.5, // 500g
      length: 25.0, // 25cm
      height: 3.0, // 3cm
      width: 18.0, // 18cm
      // Sem variações
    );
  }

  // Método para obter todos os exemplos
  static List<Product> getAllExamples() {
    return [
      createTShirtExample(),
      createPhoneCaseExample(),
      createSneakersExample(),
      createSimpleProductExample(),
    ];
  }

  // Método para testar o sistema de variações
  static void testVariations() {
    final tshirt = createTShirtExample();
    
    print('=== Teste do Sistema de Variações ===');
    print('Produto: ${tshirt.name}');
    print('Tem variações: ${tshirt.hasVariations}');
    print('Preço mínimo: R\$ ${tshirt.minPrice}');
    print('Preço máximo: R\$ ${tshirt.maxPrice}');
    print('Cores disponíveis: ${tshirt.availableColors}');
    print('Tamanhos disponíveis: ${tshirt.availableSizes}');
    print('Total de variações: ${tshirt.variations.length}');
    
    print('\n=== Variações ===');
    for (final variation in tshirt.variations) {
      print('SKU: ${variation.sku}');
      print('  Cor: ${variation.color}');
      print('  Tamanho: ${variation.size}');
      print('  Preço: R\$ ${variation.price}');
      print('  Estoque: ${variation.stock}');
      print('  Tem estoque: ${variation.hasStock}');
      print('---');
    }
  }
}
