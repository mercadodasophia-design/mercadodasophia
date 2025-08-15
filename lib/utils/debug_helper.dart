import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/user_location.dart';
import '../providers/location_provider.dart';
import '../services/shipping_service.dart';

class DebugHelper {
  // Testar parsing de produtos
  static void testProductParsing() {
    print('=== TESTE DE PARSING DE PRODUTOS ===');
    
    // Teste com dados válidos
    try {
      final validProduct = Product.fromJson({
        'id': 'test_001',
        'name': 'Produto Teste',
        'description': 'Descrição do produto',
        'price': 99.99,
        'imageUrl': 'https://example.com/image.jpg',
        'category': 'Teste',
        'rating': 4.5,
        'reviewCount': 100,
      });
      print('✅ Produto válido criado: ${validProduct.name}');
    } catch (e) {
      print('❌ Erro ao criar produto válido: $e');
    }
    
         // Teste com dados inválidos (strings vazias)
     try {
       final invalidProduct = Product.fromJson({
         'id': 'test_002',
         'name': 'Produto Inválido',
         'description': 'Descrição do produto',
         'price': '', // String vazia
         'imageUrl': 'https://example.com/image.jpg',
         'category': 'Teste',
         'rating': '', // String vazia
         'reviewCount': '', // String vazia
         'weight': '', // String vazia
         'length': '', // String vazia
         'height': '', // String vazia
         'width': '', // String vazia
       });
       print('✅ Produto inválido tratado: ${invalidProduct.name}');
       print('   Preço: ${invalidProduct.price}');
       print('   Rating: ${invalidProduct.rating}');
       print('   Reviews: ${invalidProduct.reviewCount}');
       print('   Peso: ${invalidProduct.weight}');
       print('   Dimensões: ${invalidProduct.length}x${invalidProduct.height}x${invalidProduct.width}');
     } catch (e) {
       print('❌ Erro ao tratar produto inválido: $e');
     }
    
    // Teste com dados nulos
    try {
      final nullProduct = Product.fromJson({
        'id': 'test_003',
        'name': 'Produto Nulo',
        'description': 'Descrição do produto',
        'price': null,
        'imageUrl': 'https://example.com/image.jpg',
        'category': 'Teste',
        'rating': null,
        'reviewCount': null,
      });
      print('✅ Produto com nulos tratado: ${nullProduct.name}');
      print('   Preço: ${nullProduct.price}');
      print('   Rating: ${nullProduct.rating}');
      print('   Reviews: ${nullProduct.reviewCount}');
    } catch (e) {
      print('❌ Erro ao tratar produto com nulos: $e');
    }
  }
  
     // Testar localização
   static void testLocationProvider(LocationProvider locationProvider) {
     print('=== TESTE DE LOCALIZAÇÃO ===');
     
     try {
       final address = locationProvider.getFormattedAddress();
       print('✅ Endereço formatado: $address');
     } catch (e) {
       print('❌ Erro ao formatar endereço: $e');
     }
     
     try {
       final hasLocation = locationProvider.hasLocation;
       print('✅ Tem localização: $hasLocation');
     } catch (e) {
       print('❌ Erro ao verificar localização: $e');
     }
     
     try {
       final hasSavedAddress = locationProvider.hasSavedAddress;
       print('✅ Tem endereço salvo: $hasSavedAddress');
     } catch (e) {
       print('❌ Erro ao verificar endereço salvo: $e');
     }
   }

   // Testar parsing de UserLocation
   static void testUserLocationParsing() {
     print('=== TESTE DE PARSING DE USERLOCATION ===');
     
     try {
       final validLocation = UserLocation.fromMap({
         'latitude': 40.7128,
         'longitude': -74.0060,
         'address': 'New York, NY',
       });
       print('✅ Localização válida criada: ${validLocation.coordinatesString}');
     } catch (e) {
       print('❌ Erro ao criar localização válida: $e');
     }
     
     try {
       final invalidLocation = UserLocation.fromMap({
         'latitude': '', // String vazia
         'longitude': '', // String vazia
         'address': 'Test Address',
       });
       print('✅ Localização inválida tratada: ${invalidLocation.coordinatesString}');
     } catch (e) {
       print('❌ Erro ao tratar localização inválida: $e');
     }
   }
  
     // Testar cálculo de frete
   static Future<void> testShippingCalculation() async {
     print('=== TESTE DE CÁLCULO DE FRETE ===');
     
     final shippingService = ShippingService();
     
     // Criar produto de teste
     final testProduct = Product(
       id: 'test_shipping_001',
       name: 'Produto Teste Frete',
       description: 'Produto para teste de frete',
       price: 50.0,
       imageUrl: 'https://example.com/image.jpg',
       category: 'Teste',
       weight: 0.5,
       length: 20.0,
       height: 5.0,
       width: 15.0,
     );
     
           try {
        final result = await shippingService.calculateShipping(
          product: testProduct,
          cep: '01001000',
        );
        
        if (result['success']) {
          print('✅ Cálculo de frete bem-sucedido');
          print('   CEP: ${result['cep']}');
          print('   Endereço: ${result['address']}');
          
          final shippingOptions = result['shipping'] as List<dynamic>?;
          if (shippingOptions != null) {
            print('   Opções de frete: ${shippingOptions.length}');
            for (final option in shippingOptions) {
              final serviceName = option['service_name'] ?? 'Frete';
              final price = option['price'] ?? 0.0;
              final deliveryTime = option['estimated_days'] ?? 0;
              final carrier = option['carrier'] ?? '';
              print('     - $serviceName: R\$ $price (${deliveryTime} dias) via $carrier');
            }
          }
        } else {
          print('❌ Erro no cálculo de frete: ${result['error'] ?? result['message']}');
          print('   ⚠️  API de frete indisponível - necessário configurar corretamente');
        }
      } catch (e) {
        print('❌ Erro ao calcular frete: $e');
        print('   ⚠️  Verificar configuração da API de frete');
      }
   }
  
     // Executar todos os testes
   static Future<void> runAllTests(LocationProvider locationProvider) async {
     print('\n🚀 INICIANDO TESTES DE DEBUG');
     print('=' * 50);
     
     testProductParsing();
     print('');
     
     testUserLocationParsing();
     print('');
     
     testLocationProvider(locationProvider);
     print('');
     
     await testShippingCalculation();
     print('');
     
     print('✅ TODOS OS TESTES CONCLUÍDOS');
     print('=' * 50);
   }
}
