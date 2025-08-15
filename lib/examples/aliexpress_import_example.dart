import '../services/aliexpress_service.dart';

class AliExpressImportExample {
  static final AliExpressService _aliExpressService = AliExpressService();

  /// Exemplo de importação individual com detecção automática de categoria
  static Future<void> importSingleProductExample() async {
    try {
      const productUrl = 'https://www.aliexpress.com/item/1234567890.html';
      
      print('🚀 Iniciando importação com detecção automática de categoria...');
      
      // Importar produto com detecção automática
      final result = await _aliExpressService.importProductWithAutoCategory(
        productUrl,
        priceOverride: null, // Usar preço original
        stockQuantity: 10,   // Definir estoque inicial
      );
      
      print('✅ Produto importado com sucesso!');
      print('📦 Nome: ${result['name']}');
      print('💰 Preço: R\$ ${result['price']}');
      print('🏷️ Categoria detectada: ${result['category_detection']['detected_category']}');
      print('🎯 Confiança: ${(result['category_detection']['confidence'] * 100).toStringAsFixed(1)}%');
      print('📊 Fonte: ${result['category_detection']['source']}');
      
    } catch (e) {
      print('❌ Erro na importação: $e');
    }
  }

  /// Exemplo de obtenção de sugestões de categoria antes da importação
  static Future<void> getCategorySuggestionsExample() async {
    try {
      const productUrl = 'https://www.aliexpress.com/item/1234567890.html';
      
      print('🔍 Obtendo sugestões de categoria...');
      
      // Obter sugestões de categoria
      final suggestions = await _aliExpressService.getCategorySuggestions(productUrl);
      
      print('✅ Sugestões encontradas:');
      for (int i = 0; i < suggestions.length; i++) {
        final suggestion = suggestions[i];
        print('${i + 1}. ${suggestion['category']} (${(suggestion['confidence'] * 100).toStringAsFixed(1)}% confiança)');
        print('   Fonte: ${suggestion['source']}');
        print('   Categoria AliExpress: ${suggestion['ali_express_category']}');
        print('');
      }
      
    } catch (e) {
      print('❌ Erro ao obter sugestões: $e');
    }
  }

  /// Exemplo de detecção de categoria sem importar
  static Future<void> detectCategoryExample() async {
    try {
      const productUrl = 'https://www.aliexpress.com/item/1234567890.html';
      
      print('🔍 Detectando categoria sem importar...');
      
      // Detectar categoria
      final result = await _aliExpressService.detectCategoryForProduct(productUrl);
      
      final productDetails = result['product_details'];
      final categoryDetection = result['category_detection'];
      
      print('✅ Detecção concluída:');
      print('📦 Produto: ${productDetails['name']}');
      print('🏷️ Categoria: ${categoryDetection['detected_category']}');
      print('🎯 Confiança: ${(categoryDetection['confidence'] * 100).toStringAsFixed(1)}%');
      print('📊 Fonte: ${categoryDetection['source']}');
      print('🌐 Categoria AliExpress: ${categoryDetection['ali_express_category']}');
      
    } catch (e) {
      print('❌ Erro na detecção: $e');
    }
  }

  /// Exemplo de importação em lote com detecção automática
  static Future<void> bulkImportExample() async {
    try {
      final productUrls = [
        'https://www.aliexpress.com/item/1234567890.html',
        'https://www.aliexpress.com/item/0987654321.html',
        'https://www.aliexpress.com/item/1122334455.html',
      ];
      
      print('🚀 Iniciando importação em lote com detecção automática...');
      
      // Importar produtos em lote
      final result = await _aliExpressService.importBulkProductsWithAutoCategory(productUrls);
      
      print('✅ Importação em lote concluída:');
      print('📊 Total processado: ${result['total_processed']}');
      print('✅ Sucessos: ${result['total_success']}');
      print('❌ Erros: ${result['total_errors']}');
      
      // Mostrar detalhes dos sucessos
      if (result['success'].isNotEmpty) {
        print('\n📦 Produtos importados com sucesso:');
        for (final success in result['success']) {
          final productResult = success['result'];
          final categoryDetection = productResult['category_detection'];
          print('- ${productResult['name']} → ${categoryDetection['detected_category']} (${(categoryDetection['confidence'] * 100).toStringAsFixed(1)}%)');
        }
      }
      
      // Mostrar detalhes dos erros
      if (result['errors'].isNotEmpty) {
        print('\n❌ Erros encontrados:');
        for (final error in result['errors']) {
          print('- ${error['url']}: ${error['error']}');
        }
      }
      
    } catch (e) {
      print('❌ Erro na importação em lote: $e');
    }
  }

  /// Exemplo completo de workflow de importação
  static Future<void> completeWorkflowExample() async {
    try {
      const productUrl = 'https://www.aliexpress.com/item/1234567890.html';
      
      print('🚀 Workflow completo de importação com detecção de categoria');
      print('=' * 60);
      
      // 1. Detectar categoria primeiro
      print('\n1️⃣ Detectando categoria...');
      final detectionResult = await _aliExpressService.detectCategoryForProduct(productUrl);
      final categoryDetection = detectionResult['category_detection'];
      
      print('   Categoria detectada: ${categoryDetection['detected_category']}');
      print('   Confiança: ${(categoryDetection['confidence'] * 100).toStringAsFixed(1)}%');
      
      // 2. Obter sugestões alternativas
      print('\n2️⃣ Obtendo sugestões alternativas...');
      final suggestions = await _aliExpressService.getCategorySuggestions(productUrl);
      
      print('   Sugestões disponíveis:');
      for (int i = 0; i < suggestions.length && i < 3; i++) {
        final suggestion = suggestions[i];
        print('   ${i + 1}. ${suggestion['category']} (${(suggestion['confidence'] * 100).toStringAsFixed(1)}%)');
      }
      
      // 3. Importar produto com categoria detectada
      print('\n3️⃣ Importando produto...');
      final importResult = await _aliExpressService.importProductWithAutoCategory(
        productUrl,
        stockQuantity: 5,
      );
      
      print('   ✅ Produto importado com sucesso!');
      print('   📦 Nome: ${importResult['name']}');
      print('   💰 Preço: R\$ ${importResult['price']}');
      print('   🏷️ Categoria final: ${importResult['category_detection']['detected_category']}');
      print('   💾 Salvo no Firebase com dados completos da categoria');
      
      print('\n🎉 Workflow concluído com sucesso!');
      
    } catch (e) {
      print('❌ Erro no workflow: $e');
    }
  }
}
