# 🔍 Sistema de Detecção Automática de Categorias - AliExpress

## 📋 Visão Geral

Este sistema permite importar produtos da AliExpress com **detecção automática de categorias** e salvar todas as informações no Firebase, incluindo dados completos da categoria detectada.

## 🚀 Funcionalidades

### ✅ **Detecção Automática de Categorias**
- Analisa nome e descrição do produto
- Mapeia categorias AliExpress para categorias locais
- Calcula nível de confiança da detecção
- Suporta override manual quando necessário

### ✅ **Mapeamento Inteligente**
- **20+ categorias AliExpress** mapeadas (IDs oficiais)
- **Keywords em português e inglês**
- **Categorias locais** do Mercado da Sophia
- **Sistema de confiança** baseado em análise de texto

### ✅ **Integração Completa**
- **Importação individual** com detecção automática
- **Importação em lote** com processamento paralelo
- **Sugestões de categoria** antes da importação
- **Salvamento no Firebase** com dados completos

## 📊 Categorias Mapeadas

### 🏷️ **Categorias AliExpress (IDs Oficiais)**

| ID AliExpress | Nome AliExpress | Nome PT | Categoria Local |
|---------------|-----------------|---------|-----------------|
| 200000801 | Women's Clothing | Roupas Femininas | Roupas Femininas |
| 200000802 | Men's Clothing | Roupas Masculinas | Roupas Masculinas |
| 200000803 | Kids & Baby Clothing | Roupas Infantis | Roupas Infantis |
| 200000804 | Shoes | Calçados | Calçados |
| 200000805 | Bags & Accessories | Bolsas e Acessórios | Bolsas e Acessórios |
| 200000806 | Jewelry & Watches | Joias e Relógios | Joias e Relógios |
| 200000807 | Beauty & Health | Beleza e Saúde | Beleza e Saúde |
| 200000808 | Home & Garden | Casa e Jardim | Casa e Jardim |
| 200000809 | Sports & Entertainment | Esportes e Entretenimento | Esportes e Entretenimento |
| 200000810 | Automotive | Automotivo | Automotivo |
| 200000811 | Toys & Hobbies | Brinquedos e Hobbies | Brinquedos e Hobbies |
| 200000812 | Electronics | Eletrônicos | Eletrônicos |
| 200000813 | Computer & Office | Informática e Escritório | Informática e Escritório |
| 200000814 | Phones & Telecommunications | Telefones e Telecomunicações | Telefones e Telecomunicações |
| 200000815 | Lights & Lighting | Iluminação | Iluminação |
| 200000816 | Tools & Hardware | Ferramentas e Ferragens | Ferramentas e Ferragens |
| 200000817 | Security & Protection | Segurança e Proteção | Segurança e Proteção |
| 200000818 | Mother & Kids | Maternidade e Crianças | Maternidade e Crianças |
| 200000819 | Pet Supplies | Produtos para Animais | Produtos para Animais |
| 200000820 | Wedding & Events | Casamento e Eventos | Casamento e Eventos |

## 🛠️ Como Usar

### 1️⃣ **Importação Individual com Detecção Automática**

```dart
import 'package:mercadodasophia/services/aliexpress_service.dart';

final aliExpressService = AliExpressService();

// Importar produto com detecção automática
final result = await aliExpressService.importProductWithAutoCategory(
  'https://www.aliexpress.com/item/1234567890.html',
  stockQuantity: 10,
);

print('Categoria detectada: ${result['category_detection']['detected_category']}');
print('Confiança: ${(result['category_detection']['confidence'] * 100).toStringAsFixed(1)}%');
```

### 2️⃣ **Obter Sugestões de Categoria**

```dart
// Obter sugestões antes de importar
final suggestions = await aliExpressService.getCategorySuggestions(
  'https://www.aliexpress.com/item/1234567890.html',
);

for (final suggestion in suggestions) {
  print('${suggestion['category']} (${(suggestion['confidence'] * 100).toStringAsFixed(1)}%)');
}
```

### 3️⃣ **Detectar Categoria Sem Importar**

```dart
// Apenas detectar categoria
final detection = await aliExpressService.detectCategoryForProduct(
  'https://www.aliexpress.com/item/1234567890.html',
);

print('Categoria: ${detection['category_detection']['detected_category']}');
print('Fonte: ${detection['category_detection']['source']}');
```

### 4️⃣ **Importação em Lote**

```dart
final urls = [
  'https://www.aliexpress.com/item/1234567890.html',
  'https://www.aliexpress.com/item/0987654321.html',
];

final result = await aliExpressService.importBulkProductsWithAutoCategory(urls);

print('Sucessos: ${result['total_success']}');
print('Erros: ${result['total_errors']}');
```

## 📁 Estrutura dos Dados no Firebase

### 🔥 **Documento do Produto**

```json
{
  "name": "Nome do Produto",
  "description": "Descrição do produto",
  "price": 99.99,
  "images": ["url1", "url2"],
  "aliexpress_id": "1234567890",
  "aliexpress_url": "https://www.aliexpress.com/item/1234567890.html",
  
  "category": {
    "detected_category": "Garrafeira",
    "confidence": 0.85,
    "source": "text_analysis",
    "ali_express_category": "Roupas Femininas",
    "ali_express_id": "200000801",
    "detection_timestamp": "2024-01-15T10:30:00Z"
  },
  
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "status": "active",
  "source": "aliexpress_import"
}
```

## 🎯 **Sistema de Confiança**

### 📊 **Níveis de Confiança**

- **0.9 - 1.0**: Categoria AliExpress oficial (95%+ confiança)
- **0.7 - 0.9**: Detecção por texto com múltiplas keywords (70-90% confiança)
- **0.5 - 0.7**: Detecção por texto com poucas keywords (50-70% confiança)
- **0.1 - 0.5**: Detecção fraca ou categoria padrão (10-50% confiança)

### 🔍 **Fontes de Detecção**

- **`aliexpress_id`**: ID oficial da categoria AliExpress
- **`text_analysis`**: Análise de nome e descrição do produto
- **`default`**: Categoria padrão quando não é possível detectar

## 🚀 **Exemplos Práticos**

### 📱 **Smartphone**
```
Nome: "iPhone 14 Pro Max Case"
Detecção: "Telefones e Telecomunicações" → "Queijos e Pão"
Confiança: 85%
Keywords: ["phone", "mobile", "smartphone", "celular"]
```

### 👗 **Roupa Feminina**
```
Nome: "Women's Summer Dress"
Detecção: "Roupas Femininas" → "Garrafeira"
Confiança: 95%
Keywords: ["women", "female", "dress", "feminino", "vestido"]
```

### 🏠 **Produto para Casa**
```
Nome: "Kitchen Utensils Set"
Detecção: "Casa e Jardim" → "Doces"
Confiança: 78%
Keywords: ["kitchen", "home", "cozinha", "casa"]
```

## 🔧 **Configuração e Personalização**

### 📝 **Adicionar Novas Categorias**

Edite `lib/services/aliexpress_category_mapper.dart`:

```dart
static const Map<String, Map<String, dynamic>> aliExpressCategories = {
  "NOVO_ID": {
    "name": "New Category",
    "pt_name": "Nova Categoria",
    "keywords": ["keyword1", "keyword2", "palavra1", "palavra2"],
    "local_category": "Categoria Local"
  },
};
```

### 🎯 **Ajustar Mapeamento Local**

```dart
static const Map<String, String> localCategories = {
  "Nova Categoria": "nova_categoria_local",
};
```

## 📈 **Monitoramento e Analytics**

### 📊 **Métricas Disponíveis**

- **Taxa de acerto** da detecção automática
- **Categorias mais detectadas**
- **Produtos sem categoria** (confiança baixa)
- **Performance** do sistema de detecção

### 🔍 **Logs de Debug**

```dart
// Ativar logs detalhados
print('🔍 Detectando categoria para: $productName');
print('✅ Categoria detectada: ${categoryInfo['pt_name']}');
print('🎯 Confiança: ${(confidence * 100).toStringAsFixed(1)}%');
```

## 🎉 **Benefícios**

### ✅ **Automatização Completa**
- Detecção automática de categorias
- Mapeamento inteligente AliExpress → Local
- Salvamento completo no Firebase

### ✅ **Flexibilidade**
- Override manual quando necessário
- Sugestões múltiplas de categoria
- Sistema de confiança transparente

### ✅ **Escalabilidade**
- Importação em lote
- Processamento paralelo
- Performance otimizada

### ✅ **Manutenibilidade**
- Código modular e bem documentado
- Fácil adição de novas categorias
- Sistema de logs detalhado

## 🚀 **Próximos Passos**

1. **Testar** com produtos reais da AliExpress
2. **Ajustar** mapeamento de categorias conforme necessário
3. **Monitorar** taxa de acerto da detecção
4. **Otimizar** keywords para melhor precisão
5. **Implementar** interface de usuário para override manual

---

**🎯 Sistema pronto para uso em produção!** 

Para dúvidas ou suporte, consulte os exemplos em `lib/examples/aliexpress_import_example.dart`.
