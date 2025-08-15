/// Resultado da validação
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

class ProductValidationService {

  /// Validar produto antes da publicação
  static ValidationResult validateProduct(Map<String, dynamic> product) {
    List<String> errors = [];
    List<String> warnings = [];

    // 1. Validação de campos obrigatórios
    _validateRequiredFields(product, errors);

    // 2. Validação de imagens
    _validateImages(product, errors, warnings);

    // 3. Validação de preços
    _validatePrices(product, errors, warnings);

    // 4. Validação de variações
    _validateVariations(product, errors, warnings);

    // 5. Validação de estoque
    _validateStock(product, errors, warnings);

    // 6. Validação de SEO
    _validateSEO(product, warnings);

    bool isValid = errors.isEmpty;

    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validar campos obrigatórios
  static void _validateRequiredFields(Map<String, dynamic> product, List<String> errors) {
    // Nome do produto
    if (product['name'] == null || product['name'].toString().trim().isEmpty) {
      errors.add('Nome do produto é obrigatório');
    } else if (product['name'].toString().length < 3) {
      errors.add('Nome do produto deve ter pelo menos 3 caracteres');
    }

    // Descrição
    if (product['description'] == null || product['description'].toString().trim().isEmpty) {
      errors.add('Descrição do produto é obrigatória');
    } else if (product['description'].toString().length < 10) {
      errors.add('Descrição deve ter pelo menos 10 caracteres');
    }

    // Categoria
    if (product['category'] == null || product['category'].toString().trim().isEmpty) {
      errors.add('Categoria é obrigatória');
    }

    // Preço
    if (product['price'] == null || product['price'] <= 0) {
      errors.add('Preço deve ser maior que zero');
    }
  }

  /// Validar imagens
  static void _validateImages(Map<String, dynamic> product, List<String> errors, List<String> warnings) {
    List<String> images = [];
    
    // Imagens existentes
    if (product['images'] != null && product['images'] is List) {
      images.addAll(List<String>.from(product['images']));
    }
    
    // Imagens selecionadas (se houver)
    if (product['selected_images'] != null && product['selected_images'] is List) {
      // Contar imagens selecionadas
      int selectedCount = product['selected_images'].length;
      if (selectedCount > 0) {
        // Simular URLs para imagens selecionadas
        for (int i = 0; i < selectedCount; i++) {
          images.add('selected_image_$i');
        }
      }
    }

    if (images.isEmpty) {
      errors.add('Pelo menos uma imagem é obrigatória');
    } else if (images.length < 2) {
      warnings.add('Recomendamos pelo menos 2 imagens para melhor apresentação');
    } else if (images.length > 10) {
      warnings.add('Máximo recomendado é 10 imagens por produto');
    }
  }

  /// Validar preços
  static void _validatePrices(Map<String, dynamic> product, List<String> errors, List<String> warnings) {
    double? price = product['price']?.toDouble();
    double? originalPrice = product['original_price']?.toDouble();

    if (price == null || price <= 0) {
      errors.add('Preço deve ser maior que zero');
      return;
    }

    if (originalPrice != null && originalPrice > 0) {
      if (originalPrice <= price) {
        errors.add('Preço original deve ser maior que o preço de venda');
      } else {
        double discount = ((originalPrice - price) / originalPrice) * 100;
        if (discount > 90) {
          warnings.add('Desconto muito alto (${discount.toStringAsFixed(1)}%). Verifique se está correto.');
        }
      }
    }

    if (price > 10000) {
      warnings.add('Preço muito alto. Verifique se está correto.');
    }
  }

  /// Validar variações
  static void _validateVariations(Map<String, dynamic> product, List<String> errors, List<String> warnings) {
    List<dynamic> variations = product['variations'] ?? [];
    
    if (variations.isNotEmpty) {
      for (int i = 0; i < variations.length; i++) {
        Map<String, dynamic> variation = variations[i];
        
        // Validar nome da variação
        if (variation['name'] == null || variation['name'].toString().trim().isEmpty) {
          errors.add('Variação ${i + 1}: Nome é obrigatório');
        }
        
        // Validar preço da variação
        if (variation['price'] == null || variation['price'] <= 0) {
          errors.add('Variação ${i + 1}: Preço deve ser maior que zero');
        }
        
        // Validar estoque da variação
        if (variation['stock'] == null || variation['stock'] < 0) {
          errors.add('Variação ${i + 1}: Estoque deve ser zero ou maior');
        }
      }
      
      // Verificar se há variações com estoque zero
      int zeroStockCount = variations.where((v) => (v['stock'] ?? 0) == 0).length;
      if (zeroStockCount > 0) {
        warnings.add('$zeroStockCount variação(ões) com estoque zero');
      }
    }
  }

  /// Validar estoque
  static void _validateStock(Map<String, dynamic> product, List<String> errors, List<String> warnings) {
    List<dynamic> variations = product['variations'] ?? [];
    
    if (variations.isEmpty) {
      // Produto sem variações
      int stock = product['stock'] ?? 0;
      if (stock < 0) {
        errors.add('Estoque não pode ser negativo');
      } else if (stock == 0) {
        warnings.add('Produto sem estoque disponível');
      }
    } else {
      // Produto com variações
      int totalStock = 0;
      int zeroStockVariations = 0;
      
      for (var variation in variations) {
        int stock = variation['stock'] ?? 0;
        totalStock += stock;
        if (stock == 0) zeroStockVariations++;
      }
      
      if (totalStock == 0) {
        warnings.add('Produto sem estoque disponível');
      }
      
      if (zeroStockVariations == variations.length) {
        warnings.add('Todas as variações estão sem estoque');
      }
    }
  }

  /// Validar SEO
  static void _validateSEO(Map<String, dynamic> product, List<String> warnings) {
    // Título SEO
    String? seoTitle = product['seo_title'];
    if (seoTitle == null || seoTitle.trim().isEmpty) {
      warnings.add('Título SEO não definido (usará o nome do produto)');
    } else if (seoTitle.length > 60) {
      warnings.add('Título SEO muito longo (máximo 60 caracteres)');
    }

    // Descrição SEO
    String? seoDescription = product['seo_description'];
    if (seoDescription == null || seoDescription.trim().isEmpty) {
      warnings.add('Descrição SEO não definida');
    } else if (seoDescription.length > 160) {
      warnings.add('Descrição SEO muito longa (máximo 160 caracteres)');
    }

    // Palavras-chave
    List<String> keywords = [];
    var keywordsData = product['keywords'];
    if (keywordsData != null) {
      if (keywordsData is List) {
        keywords = List<String>.from(keywordsData);
      } else if (keywordsData is String) {
        // Se for string, dividir por vírgula
        keywords = keywordsData.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    
    if (keywords.isEmpty) {
      warnings.add('Palavras-chave não definidas');
    } else if (keywords.length > 10) {
      warnings.add('Muitas palavras-chave (máximo 10)');
    }
  }

  /// Validar se o produto pode ser publicado
  static bool canPublish(Map<String, dynamic> product) {
    ValidationResult result = validateProduct(product);
    return result.isValid;
  }

  /// Obter resumo da validação
  static String getValidationSummary(ValidationResult result) {
    if (result.isValid) {
      if (result.warnings.isEmpty) {
        return '✅ Produto válido para publicação';
      } else {
        return '✅ Produto válido (${result.warnings.length} aviso(s))';
      }
    } else {
      return '❌ ${result.errors.length} erro(s) encontrado(s)';
    }
  }
}
