# 🚚 Configuração do Sistema de Frete

## 📋 **Visão Geral**

O sistema de frete foi configurado para usar sua API própria em vez da API dos Correios. Ele suporta produtos do AliExpress e calcula frete baseado nas dimensões e peso dos produtos.

## ⚙️ **Configuração**

### 1. **URL da API**
Edite o arquivo `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Ajuste para sua URL de produção
  static const String baseUrl = 'http://localhost:5000'; // ou https://sua-api.com
  
  // Endpoints
  static const String shippingQuote = '/shipping/quote';
  // ... outros endpoints
}
```

### 2. **Backend (Python/Node.js)**
Certifique-se de que sua API está rodando e acessível no endpoint `/shipping/quote`.

**Estrutura esperada da requisição:**
```json
{
  "destination_cep": "01001000",
  "items": [
    {
      "product_id": "1005001234567890",
      "quantity": 1,
      "weight": 0.3,
      "price": 899.90,
      "length": 15.0,
      "height": 1.0,
      "width": 8.0
    }
  ],
  "product_id": "1005001234567890"
}
```

**Estrutura esperada da resposta:**
```json
{
  "success": true,
  "data": [
    {
      "service_code": "OWN_ECONOMY",
      "service_name": "Entrega Padrão (Loja)",
      "carrier": "Correios/Parceiro",
      "price": 19.9,
      "currency": "BRL",
      "estimated_days": 12,
      "origin_cep": "01001-000",
      "destination_cep": "01001000",
      "notes": "Cálculo de frete próprio"
    },
    {
      "service_code": "OWN_EXPRESS",
      "service_name": "Entrega Expressa (Loja)",
      "carrier": "Parceiro Expresso",
      "price": 29.9,
      "currency": "BRL",
      "estimated_days": 5,
      "origin_cep": "01001-000",
      "destination_cep": "01001000",
      "notes": "Cálculo de frete próprio"
    }
  ]
}
```

## 🛠️ **Como Usar**

### 1. **No Widget de Cálculo de Frete**
O widget `ShippingCalculatorWidget` já está configurado para usar sua API:

```dart
ShippingCalculatorWidget(
  product: product,
  onShippingSelected: (cost) {
    setState(() {
      _shippingCost = cost;
    });
  },
)
```

### 2. **Programaticamente**
```dart
final shippingService = ShippingService();

final result = await shippingService.calculateShipping(
  product: product,
  cep: '01001000',
);

if (result['success']) {
  final shippingOptions = result['shipping'] as List<dynamic>;
  // Processar opções de frete
}
```

### 3. **Com Produtos do AliExpress**
```dart
// Produto com ID do AliExpress
final product = Product(
  id: '1005001234567890', // ID real do AliExpress
  name: 'Smartphone Android',
  price: 899.90,
  weight: 0.3, // Peso em kg
  length: 15.0, // Comprimento em cm
  height: 1.0,  // Altura em cm
  width: 8.0,   // Largura em cm
  // ... outros campos
);

// Calcular frete
final shippingResult = await shippingService.calculateShipping(
  product: product,
  cep: '01001000',
);
```

## 🔧 **Funcionalidades**

### ✅ **Implementado**
- ✅ Cálculo de frete via API própria
- ✅ Validação de CEP via ViaCEP
- ✅ Múltiplas opções de frete
- ✅ Integração com produtos do AliExpress
- ✅ Interface de usuário completa
- ✅ Dimensões e peso dos produtos
- ✅ Tratamento de erros sem fallbacks fictícios

### 🎯 **Próximos Passos**
1. **Configurar URL de produção** no `ApiConfig`
2. **Testar com produtos reais** do AliExpress
3. **Implementar cache** de cotações de frete
4. **Adicionar mais opções** de frete se necessário

## 🧪 **Testes**

### Executar Teste de Frete
```dart
import '../examples/aliexpress_shipping_example.dart';

// Testar cálculo de frete
await AliExpressShippingExample.testShippingCalculation();
```

### Testar com Diferentes CEPs
```dart
final ceps = ['01001000', '20040020', '90020060']; // SP, RJ, RS

for (final cep in ceps) {
  final result = await shippingService.calculateShipping(
    product: product,
    cep: cep,
  );
  print('CEP $cep: ${result['success']}');
}
```

## ⚠️ **IMPORTANTE: API Obrigatória**

**A API de frete é OBRIGATÓRIA para o funcionamento do sistema.**
- Não há fallbacks com valores fictícios
- Se a API falhar, o cálculo de frete não funcionará
- É necessário garantir 100% de disponibilidade da API em produção

## 🚨 **Troubleshooting**

### Erro de Conexão
- Verifique se a API está rodando
- Confirme a URL no `ApiConfig`
- Teste a conectividade da rede
- **A API deve estar 100% disponível**

### Erro de CEP
- Verifique se o CEP está no formato correto (8 dígitos)
- Confirme se o CEP existe no ViaCEP

### Erro de Produto
- Verifique se o produto tem dimensões definidas
- Confirme se o `product_id` está correto

## 📞 **Suporte**

Para dúvidas ou problemas:
1. Verifique os logs do console
2. Teste a API diretamente
3. Confirme a configuração do `ApiConfig`
