import '../models/product.dart';
import '../models/product_variation.dart';
import '../services/shipping_service.dart';

class AliExpressShippingExample {
  // Exemplo de produto do AliExpress com ID real
  static Product createAliExpressProduct() {
    return Product(
      id: '1005001234567890', // ID real do AliExpress
      name: 'Smartphone Android 128GB',
      description: 'Smartphone Android com 128GB de armazenamento, câmera tripla e bateria de longa duração.',
      price: 899.90,
      imageUrl: 'https://example.com/smartphone.jpg',
      images: [
        'https://example.com/smartphone_front.jpg',
        'https://example.com/smartphone_back.jpg',
        'https://example.com/smartphone_side.jpg',
      ],
      category: 'Eletrônicos',
      weight: 0.3, // 300g
      length: 15.0, // 15cm
      height: 1.0, // 1cm
      width: 8.0, // 8cm
      variations: [
        // Variações de cor
        ProductVariation(
          id: '1005001234567890_black',
          productId: '1005001234567890',
          color: 'Preto',
          price: 899.90,
          stock: 50,
          sku: 'SMART-BLK-128',
        ),
        ProductVariation(
          id: '1005001234567890_blue',
          productId: '1005001234567890',
          color: 'Azul',
          price: 899.90,
          stock: 30,
          sku: 'SMART-BLU-128',
        ),
      ],
    );
  }

  // Exemplo de cálculo de frete
  static Future<void> testShippingCalculation() async {
    final product = createAliExpressProduct();
    final shippingService = ShippingService();
    
    print('=== Teste de Cálculo de Frete AliExpress ===');
    print('Produto: ${product.name}');
    print('ID: ${product.id}');
    print('Peso: ${product.weight}kg');
    print('Dimensões: ${product.length}x${product.width}x${product.height}cm');
    
    try {
      // Calcular frete para diferentes CEPs
      final ceps = ['01001000', '20040020', '90020060']; // SP, RJ, RS
      
      for (final cep in ceps) {
        print('\n--- CEP: $cep ---');
        
        final result = await shippingService.calculateShipping(
          product: product,
          cep: cep,
        );
        
        if (result['success']) {
          final shippingOptions = result['shipping'] as List<dynamic>?;
          if (shippingOptions != null) {
            print('✅ ${shippingOptions.length} opções de frete encontradas:');
            
            for (final option in shippingOptions) {
              final serviceName = option['service_name'] ?? 'Frete';
              final price = option['price'] ?? 0.0;
              final days = option['estimated_days'] ?? 0;
              final carrier = option['carrier'] ?? '';
              
              print('  📦 $serviceName');
              print('     Preço: R\$ ${price.toStringAsFixed(2)}');
              print('     Prazo: $days dias úteis');
              print('     Transportadora: $carrier');
            }
          }
        } else {
          print('❌ Erro: ${result['error']}');
        }
      }
    } catch (e) {
      print('❌ Erro no teste: $e');
    }
  }

  // Exemplo de como integrar com a página de detalhes
  static Future<Map<String, dynamic>> getProductWithShipping(String productId, String cep) async {
    // 1. Buscar detalhes do produto do AliExpress
    // 2. Calcular frete
    // 3. Retornar dados completos
    
    final product = createAliExpressProduct(); // Em produção, buscar do AliExpress
    final shippingService = ShippingService();
    
    final shippingResult = await shippingService.calculateShipping(
      product: product,
      cep: cep,
    );
    
    return {
      'product': product,
      'shipping': shippingResult,
      'cep': cep,
    };
  }
}
