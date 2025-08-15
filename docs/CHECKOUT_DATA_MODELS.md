# 📊 Modelos de Dados para Checkout - Mercado da Sophia

## 🎯 Objetivo
Este documento define os modelos de dados necessários para implementar o sistema de checkout completo.

---

## 📝 MODELOS PRINCIPAIS

### 1. Customer (Cliente)
```dart
class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String cpfCnpj;
  final String? password; // Para criar conta
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final Map<String, dynamic> preferences;
  
  // Endereços salvos
  final List<Address> addresses;
  
  // Preferências de contato
  final String preferredContactMethod; // 'email', 'whatsapp', 'phone'
  final bool marketingConsent;
}
```

### 2. Address (Endereço)
```dart
class Address {
  final String id;
  final String customerId;
  final String cep;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String country;
  final bool isDefault;
  final String label; // 'Casa', 'Trabalho', etc.
}
```

### 3. Order (Pedido)
```dart
class Order {
  final String id;
  final String customerId;
  final String orderNumber; // Número do pedido para o cliente
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double total;
  final String? couponCode;
  final double discountAmount;
  final PaymentInfo payment;
  final ShippingInfo shipping;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata; // Dados extras
}
```

### 4. OrderItem (Item do Pedido)
```dart
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? variationId;
  final String? variationName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
}
```

### 5. Payment (Pagamento)
```dart
class Payment {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? transactionId;
  final DateTime? paidAt;
  final Map<String, dynamic> paymentData; // Dados específicos do método
  
  // Para cartão
  final String? cardLastDigits;
  final String? cardBrand;
  final int? installments;
  
  // Para Pix
  final String? pixCode;
  final DateTime? pixExpiration;
  
  // Para boleto
  final String? boletoCode;
  final DateTime? boletoExpiration;
}
```

### 6. Shipping (Envio)
```dart
class Shipping {
  final String id;
  final String orderId;
  final String addressId;
  final String method; // 'standard', 'express', 'pickup'
  final double cost;
  final int estimatedDays;
  final String? trackingCode;
  final ShippingStatus status;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? notes;
}
```

---

## 🔧 ENUMS E TIPOS

### OrderStatus
```dart
enum OrderStatus {
  pending,      // Aguardando pagamento
  paid,         // Pago
  processing,   // Processando
  shipped,      // Enviado
  delivered,    // Entregue
  cancelled,    // Cancelado
  returned,     // Devolvido
}
```

### PaymentMethod
```dart
enum PaymentMethod {
  pix,
  creditCard,
  debitCard,
  boleto,
  paypal,
}
```

### PaymentStatus
```dart
enum PaymentStatus {
  pending,      // Aguardando
  processing,   // Processando
  approved,     // Aprovado
  declined,     // Recusado
  refunded,     // Reembolsado
}
```

### ShippingStatus
```dart
enum ShippingStatus {
  pending,      // Aguardando envio
  shipped,      // Enviado
  inTransit,    // Em trânsito
  delivered,    // Entregue
  returned,     // Devolvido
}
```

---

## 📊 FIREBASE COLLECTIONS

### Estrutura das Collections

#### customers
```json
{
  "id": "customer_123",
  "name": "João Silva",
  "email": "joao@email.com",
  "phone": "(11) 99999-9999",
  "cpfCnpj": "123.456.789-00",
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLogin": "2024-01-15T10:30:00Z",
  "isActive": true,
  "preferences": {
    "contactMethod": "whatsapp",
    "marketingConsent": true
  }
}
```

#### addresses
```json
{
  "id": "address_456",
  "customerId": "customer_123",
  "cep": "01234-567",
  "street": "Rua das Flores",
  "number": "123",
  "complement": "Apto 45",
  "neighborhood": "Centro",
  "city": "São Paulo",
  "state": "SP",
  "country": "Brasil",
  "isDefault": true,
  "label": "Casa"
}
```

#### orders
```json
{
  "id": "order_789",
  "customerId": "customer_123",
  "orderNumber": "MS2024001",
  "status": "pending",
  "subtotal": 150.00,
  "shippingCost": 15.00,
  "total": 165.00,
  "couponCode": "DESCONTO10",
  "discountAmount": 15.00,
  "createdAt": "2024-01-15T14:30:00Z",
  "metadata": {
    "ip": "192.168.1.1",
    "userAgent": "Mozilla/5.0...",
    "source": "web"
  }
}
```

#### order_items
```json
{
  "id": "item_001",
  "orderId": "order_789",
  "productId": "produto_123",
  "productName": "Produto Exemplo",
  "variationId": "var_456",
  "variationName": "Cor Azul",
  "sku": "PROD-001-AZUL",
  "quantity": 2,
  "unitPrice": 75.00,
  "totalPrice": 150.00
}
```

#### payments
```json
{
  "id": "payment_001",
  "orderId": "order_789",
  "method": "pix",
  "status": "approved",
  "amount": 165.00,
  "transactionId": "pix_123456",
  "paidAt": "2024-01-15T14:35:00Z",
  "paymentData": {
    "pixCode": "00020126580014br.gov.bcb.pix0136...",
    "pixExpiration": "2024-01-15T15:35:00Z"
  }
}
```

#### shipping
```json
{
  "id": "shipping_001",
  "orderId": "order_789",
  "addressId": "address_456",
  "method": "standard",
  "cost": 15.00,
  "estimatedDays": 7,
  "trackingCode": "BR123456789BR",
  "status": "shipped",
  "shippedAt": "2024-01-16T10:00:00Z"
}
```

---

## 🔒 SEGURANÇA E VALIDAÇÃO

### Dados Sensíveis
- **CPF/CNPJ**: Armazenado criptografado
- **Cartão**: Apenas token, nunca dados completos
- **Senha**: Hash bcrypt
- **Telefone**: Formato padronizado

### Validações
```dart
// CPF/CNPJ
bool isValidCpfCnpj(String value)

// CEP
bool isValidCep(String value)

// E-mail
bool isValidEmail(String value)

// Telefone
bool isValidPhone(String value)

// Cartão
bool isValidCardNumber(String value)
bool isValidCardExpiry(String value)
bool isValidCvv(String value)
```

---

## 🚀 PRÓXIMOS PASSOS

### Implementação
1. **Criar modelos** em `lib/models/`
2. **Implementar validações** em `lib/utils/validators.dart`
3. **Criar serviços** em `lib/services/`
4. **Implementar telas** em `lib/screens/checkout/`
5. **Configurar Firebase** com as collections

### Integrações
- **Mercado Pago** para pagamentos
- **Correios API** para cálculo de frete
- **ViaCEP API** para validação de endereços
- **E-mail service** para notificações

---

*Este documento será atualizado conforme o desenvolvimento avança.*







