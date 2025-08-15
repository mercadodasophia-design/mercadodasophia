import 'dart:convert';

class AliExpressCategoryMapper {
  // Mapeamento oficial das categorias AliExpress (baseado na documentação oficial)
  static const Map<String, Map<String, dynamic>> aliExpressCategories = {
    // Categorias principais (200000xxx)
    "200000801": {
      "name": "Women's Clothing",
      "pt_name": "Roupas Femininas",
      "keywords": ["women", "female", "dress", "skirt", "blouse", "shirt", "pants", "jeans", "feminino", "mulher", "vestido", "saia", "blusa", "calça"],
      "local_category": "Roupas Femininas"
    },
    "200000802": {
      "name": "Men's Clothing",
      "pt_name": "Roupas Masculinas", 
      "keywords": ["men", "male", "shirt", "pants", "jeans", "jacket", "suit", "masculino", "homem", "camisa", "calça", "jaqueta"],
      "local_category": "Roupas Masculinas"
    },
    "200000803": {
      "name": "Kids & Baby Clothing",
      "pt_name": "Roupas Infantis",
      "keywords": ["kids", "baby", "children", "child", "infant", "toddler", "criança", "bebê", "infantil", "menino", "menina"],
      "local_category": "Roupas Infantis"
    },
    "200000804": {
      "name": "Shoes",
      "pt_name": "Calçados",
      "keywords": ["shoes", "footwear", "sneakers", "boots", "sandals", "sapatos", "tênis", "botas", "sandálias", "calçado"],
      "local_category": "Calçados"
    },
    "200000805": {
      "name": "Bags & Accessories",
      "pt_name": "Bolsas e Acessórios",
      "keywords": ["bag", "purse", "handbag", "backpack", "wallet", "accessory", "bolsa", "mochila", "carteira", "acessório"],
      "local_category": "Bolsas e Acessórios"
    },
    "200000806": {
      "name": "Jewelry & Watches",
      "pt_name": "Joias e Relógios",
      "keywords": ["jewelry", "watch", "necklace", "ring", "bracelet", "joia", "relógio", "colar", "anel", "pulseira"],
      "local_category": "Joias e Relógios"
    },
    "200000807": {
      "name": "Beauty & Health",
      "pt_name": "Beleza e Saúde",
      "keywords": ["beauty", "health", "cosmetic", "skincare", "makeup", "beleza", "saúde", "cosmético", "maquiagem"],
      "local_category": "Beleza e Saúde"
    },
    "200000808": {
      "name": "Home & Garden",
      "pt_name": "Casa e Jardim",
      "keywords": ["home", "garden", "kitchen", "bathroom", "bedroom", "casa", "jardim", "cozinha", "banheiro", "quarto"],
      "local_category": "Casa e Jardim"
    },
    "200000809": {
      "name": "Sports & Entertainment",
      "pt_name": "Esportes e Entretenimento",
      "keywords": ["sports", "fitness", "exercise", "game", "entertainment", "esporte", "fitness", "exercício", "jogo"],
      "local_category": "Esportes e Entretenimento"
    },
    "200000810": {
      "name": "Automotive",
      "pt_name": "Automotivo",
      "keywords": ["car", "automotive", "vehicle", "auto", "carro", "automóvel", "veículo", "automotivo"],
      "local_category": "Automotivo"
    },
    "200000811": {
      "name": "Toys & Hobbies",
      "pt_name": "Brinquedos e Hobbies",
      "keywords": ["toy", "hobby", "game", "play", "brinquedo", "hobby", "jogo", "brincar"],
      "local_category": "Brinquedos e Hobbies"
    },
    "200000812": {
      "name": "Electronics",
      "pt_name": "Eletrônicos",
      "keywords": ["electronics", "electronic", "device", "gadget", "eletrônico", "dispositivo", "aparelho"],
      "local_category": "Eletrônicos"
    },
    "200000813": {
      "name": "Computer & Office",
      "pt_name": "Informática e Escritório",
      "keywords": ["computer", "laptop", "pc", "office", "desk", "computador", "notebook", "escritório", "mesa"],
      "local_category": "Informática e Escritório"
    },
    "200000814": {
      "name": "Phones & Telecommunications",
      "pt_name": "Telefones e Telecomunicações",
      "keywords": ["phone", "mobile", "smartphone", "telephone", "telefone", "celular", "smartphone"],
      "local_category": "Telefones e Telecomunicações"
    },
    "200000815": {
      "name": "Lights & Lighting",
      "pt_name": "Iluminação",
      "keywords": ["light", "lamp", "lighting", "led", "bulb", "luz", "lâmpada", "iluminação", "led"],
      "local_category": "Iluminação"
    },
    "200000816": {
      "name": "Tools & Hardware",
      "pt_name": "Ferramentas e Ferragens",
      "keywords": ["tool", "hardware", "screw", "nail", "ferramenta", "ferragem", "parafuso", "prego"],
      "local_category": "Ferramentas e Ferragens"
    },
    "200000817": {
      "name": "Security & Protection",
      "pt_name": "Segurança e Proteção",
      "keywords": ["security", "protection", "safety", "lock", "camera", "segurança", "proteção", "cadeado", "câmera"],
      "local_category": "Segurança e Proteção"
    },
    "200000818": {
      "name": "Mother & Kids",
      "pt_name": "Maternidade e Crianças",
      "keywords": ["mother", "baby", "pregnancy", "maternity", "mãe", "bebê", "gravidez", "maternidade"],
      "local_category": "Maternidade e Crianças"
    },
    "200000819": {
      "name": "Pet Supplies",
      "pt_name": "Produtos para Animais",
      "keywords": ["pet", "dog", "cat", "animal", "pet", "cachorro", "gato", "animal"],
      "local_category": "Produtos para Animais"
    },
    "200000820": {
      "name": "Wedding & Events",
      "pt_name": "Casamento e Eventos",
      "keywords": ["wedding", "event", "party", "celebration", "casamento", "evento", "festa", "celebração"],
      "local_category": "Casamento e Eventos"
    },
    

  };

  // Categorias locais do Mercado da Sophia
  static const Map<String, String> localCategories = {
    "Roupas Femininas": "roupas_femininas",
    "Roupas Masculinas": "roupas_masculinas", 
    "Roupas Infantis": "roupas_infantis",
    "Calçados": "calcados",
    "Bolsas e Acessórios": "bolsas_acessorios",
    "Joias e Relógios": "joias_relogios",
    "Beleza e Saúde": "beleza_saude",
    "Casa e Jardim": "casa_jardim",
    "Esportes e Entretenimento": "esportes_entretenimento",
    "Automotivo": "automotivo",
    "Brinquedos e Hobbies": "brinquedos_hobbies",
    "Eletrônicos": "eletronicos",
    "Informática e Escritório": "informatica_escritorio",
    "Telefones e Telecomunicações": "telefones_telecomunicacoes",
    "Iluminação": "iluminacao",
    "Ferramentas e Ferragens": "ferramentas_ferragens",
    "Segurança e Proteção": "seguranca_protecao",
    "Maternidade e Crianças": "maternidade_criancas",
    "Produtos para Animais": "produtos_animais",
    "Casamento e Eventos": "casamento_eventos",
  };

  /// Detectar categoria automaticamente baseada no nome e descrição do produto
  static Map<String, dynamic> detectCategory({
    required String productName,
    String? productDescription,
    String? aliExpressCategoryId,
  }) {
    print('🔍 Detectando categoria para: $productName');
    
    // Se temos o ID da categoria AliExpress, usar ele primeiro
    if (aliExpressCategoryId != null && aliExpressCategoryId.isNotEmpty) {
      final categoryInfo = aliExpressCategories[aliExpressCategoryId];
      if (categoryInfo != null) {
        print('✅ Categoria AliExpress encontrada: ${categoryInfo['pt_name']}');
        return {
          'detected_category': categoryInfo['local_category'],
          'confidence': 0.95,
          'source': 'aliexpress_id',
          'ali_express_category': categoryInfo['pt_name'],
          'ali_express_id': aliExpressCategoryId,
        };
      }
    }

    // Análise de texto para detectar categoria
    final textToAnalyze = '${productName.toLowerCase()} ${productDescription?.toLowerCase() ?? ''}';
    final scores = <String, double>{};

    // Calcular score para cada categoria
    for (final entry in aliExpressCategories.entries) {
      final categoryId = entry.key;
      final categoryInfo = entry.value;
      final keywords = List<String>.from(categoryInfo['keywords'] ?? []);
      
      double score = 0.0;
      
      for (final keyword in keywords) {
        if (textToAnalyze.contains(keyword.toLowerCase())) {
          score += 1.0;
          
          // Bonus para palavras exatas
          if (textToAnalyze.contains(' $keyword ') || 
              textToAnalyze.startsWith('$keyword ') || 
              textToAnalyze.endsWith(' $keyword')) {
            score += 0.5;
          }
        }
      }
      
      if (score > 0) {
        scores[categoryId] = score;
      }
    }

    // Encontrar a categoria com maior score
    if (scores.isNotEmpty) {
      final bestCategoryId = scores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      final bestCategoryInfo = aliExpressCategories[bestCategoryId]!;
      final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
      final confidence = (maxScore / 3.0).clamp(0.0, 1.0); // Normalizar para 0-1
      
      print('✅ Categoria detectada: ${bestCategoryInfo['pt_name']} (confiança: ${(confidence * 100).toStringAsFixed(1)}%)');
      
      return {
        'detected_category': bestCategoryInfo['local_category'],
        'confidence': confidence,
        'source': 'text_analysis',
        'ali_express_category': bestCategoryInfo['pt_name'],
        'ali_express_id': bestCategoryId,
        'scores': scores,
      };
    }

    // Categoria padrão se nada for detectado
    print('⚠️ Nenhuma categoria detectada, usando padrão');
    return {
      'detected_category': 'Eletrônicos',
      'confidence': 0.1,
      'source': 'default',
      'ali_express_category': 'Não detectado',
      'ali_express_id': null,
    };
  }

  /// Obter sugestões de categoria baseadas no produto
  static List<Map<String, dynamic>> getCategorySuggestions({
    required String productName,
    String? productDescription,
  }) {
    final detection = detectCategory(
      productName: productName,
      productDescription: productDescription,
    );
    
    final suggestions = <Map<String, dynamic>>[];
    
    // Adicionar categoria detectada como primeira sugestão
    suggestions.add({
      'category': detection['detected_category'],
      'confidence': detection['confidence'],
      'source': detection['source'],
      'ali_express_category': detection['ali_express_category'],
    });
    
    // Adicionar outras categorias com menor confiança
    if (detection['scores'] != null) {
      final scores = Map<String, double>.from(detection['scores']);
      scores.remove(detection['ali_express_id']);
      
      final sortedScores = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (int i = 0; i < sortedScores.length && i < 3; i++) {
        final entry = sortedScores[i];
        final categoryInfo = aliExpressCategories[entry.key]!;
        final confidence = (entry.value / 3.0).clamp(0.0, 1.0);
        
        suggestions.add({
          'category': categoryInfo['local_category'],
          'confidence': confidence,
          'source': 'text_analysis',
          'ali_express_category': categoryInfo['pt_name'],
        });
      }
    }
    
    return suggestions;
  }

  /// Mapear categoria AliExpress para categoria local
  static String mapToLocalCategory(String aliExpressCategoryId) {
    final categoryInfo = aliExpressCategories[aliExpressCategoryId];
    if (categoryInfo != null) {
      return categoryInfo['local_category'] ?? 'Eletrônicos';
    }
    return 'Eletrônicos'; // Categoria padrão
  }

  /// Obter todas as categorias AliExpress disponíveis
  static List<Map<String, dynamic>> getAllAliExpressCategories() {
    return aliExpressCategories.entries.map((entry) {
      return {
        'id': entry.key,
        'name': entry.value['name'],
        'pt_name': entry.value['pt_name'],
        'local_category': entry.value['local_category'],
      };
    }).toList();
  }

  /// Obter categorias locais disponíveis
  static List<String> getLocalCategories() {
    return localCategories.keys.toList();
  }
}
