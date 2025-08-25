# TODO: FINALIZAÇÃO DO CARRINHO - MERCADO DA SOPHIA

## 📋 RESUMO EXECUTIVO

Este documento detalha o que já está funcionando e o que precisa ser implementado para completar o fluxo de finalização de compras no Mercado da Sophia.

## ✅ O QUE JÁ ESTÁ FUNCIONANDO

### 1. CARRINHO DE COMPRAS
- ✅ Adicionar/remover itens
- ✅ Calcular subtotal, frete e total
- ✅ Persistência local (SharedPreferences)
- ✅ Validação de estoque
- ✅ Interface responsiva (web/mobile)
- ✅ Limpar carrinho
- ✅ Remover itens indisponíveis

### 2. TELA DE CHECKOUT
- ✅ Autenticação obrigatória
- ✅ Seleção de método de pagamento (PIX, Cartão, Boleto)
- ✅ Resumo do pedido
- ✅ Cálculo de frete
- ✅ Validação de endereço
- ✅ Redirecionamento para MercadoPago

### 3. SERVIÇOS DE PAGAMENTO
- ✅ `PaymentService` implementado
- ✅ Criação de preferência de pagamento
- ✅ Verificação de status do pagamento
- ✅ Salvamento de pedido no Firebase
- ✅ Criação de pedido AliExpress

### 4. RASTREAMENTO DE PEDIDOS
- ✅ `OrderTrackingService` implementado
- ✅ Tela "Minhas Compras" funcional
- ✅ Filtros por status
- ✅ Histórico de pedidos

## ❌ O QUE FALTA IMPLEMENTAR

### 1. WEBHOOK DO MERCADOPAGO (CRÍTICO)
**Status:** ✅ IMPLEMENTADO
**Prioridade:** 🔴 ALTA
**Arquivo:** API Python (Flask)

**Descrição:**
O webhook é essencial para receber notificações quando o pagamento for aprovado. Sem isso, não sabemos quando finalizar o pedido.

**O que implementar:**
```python
# Endpoint na API Python
@app.route('/api/payment/webhook', methods=['POST'])
def mercadopago_webhook():
    # 1. Validar assinatura do webhook
    # 2. Processar notificação
    # 3. Atualizar status do pedido
    # 4. Criar pedido AliExpress
    # 5. Enviar confirmação
```

**Dados necessários:**
- Payment ID
- Status do pagamento
- Order ID
- Dados do cliente

### 2. FLUXO COMPLETO DE FINALIZAÇÃO
**Status:** ✅ IMPLEMENTADO
**Prioridade:** 🔴 ALTA
**Arquivo:** `lib/services/payment_service.dart`

**Descrição:**
Após pagamento aprovado, completar todo o fluxo de finalização.

**O que implementar:**
```dart
// 1. Verificar status do pagamento
// 2. Se aprovado:
//    - Criar pedido AliExpress
//    - Atualizar status no Firebase
//    - Limpar carrinho do usuário
//    - Enviar confirmação por email
//    - Redirecionar para tela de sucesso
```

### 3. VALIDAÇÕES DE SEGURANÇA
**Status:** ✅ IMPLEMENTADO
**Prioridade:** 🟡 MÉDIA
**Arquivo:** `lib/screens/checkout_screen.dart`

**Descrição:**
Validações adicionais antes de finalizar a compra.

**O que implementar:**
- ✅ Verificar se produtos ainda estão disponíveis
- ✅ Validar endereço de entrega
- ✅ Verificar limite de crédito/estoque
- ✅ Validar dados do cliente
- ✅ Verificar se preços não mudaram

### 4. TRATAMENTO DE ERROS
**Status:** ✅ IMPLEMENTADO
**Prioridade:** 🟡 MÉDIA
**Arquivo:** `lib/screens/checkout_screen.dart`

**Descrição:**
Tratamento robusto de erros durante o processo de finalização.

**O que implementar:**
- ✅ Pagamento recusado
- ✅ Timeout de pagamento
- ✅ Falha na criação do pedido AliExpress
- ✅ Erro de rede
- ✅ Dados inválidos

### 5. NOTIFICAÇÕES
**Status:** ✅ IMPLEMENTADO
**Prioridade:** 🟢 BAIXA
**Arquivo:** `lib/services/notification_service.dart`

**Descrição:**
Sistema de notificações para manter o usuário informado.

**O que implementar:**
- ✅ Email de confirmação
- ✅ Push notification
- ✅ Status em tempo real
- ✅ Notificação de rastreamento

## 🔧 IMPLEMENTAÇÃO DETALHADA

### FASE 1: WEBHOOK DO MERCADOPAGO ✅ IMPLEMENTADO

#### 1.1 Endpoint na API Python
```python
# app.py ou routes/payment.py
@app.route('/api/payment/webhook', methods=['POST'])
def mercadopago_webhook():
    try:
        # Validar assinatura do webhook
        signature = request.headers.get('X-Signature')
        if not validate_webhook_signature(request.data, signature):
            return jsonify({'error': 'Invalid signature'}), 401
        
        # Processar dados do webhook
        data = request.get_json()
        payment_id = data.get('data', {}).get('id')
        status = data.get('data', {}).get('status')
        
        # Buscar pedido no Firebase
        order = get_order_by_payment_id(payment_id)
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        # Atualizar status do pedido
        if status == 'approved':
            # Criar pedido AliExpress
            aliexpress_order = create_aliexpress_order(order)
            
            # Atualizar Firebase
            update_order_status(order['id'], 'pagamento_aprovado', aliexpress_order)
            
            # Enviar email de confirmação
            send_confirmation_email(order)
            
        elif status == 'rejected':
            update_order_status(order['id'], 'pagamento_recusado')
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        logger.error(f"Webhook error: {e}")
        return jsonify({'error': 'Internal server error'}), 500
```

#### 1.2 Configuração no MercadoPago
- URL do webhook: `https://service-api-aliexpress.mercadodasophia.com.br/api/payment/webhook`
- Eventos: `payment.created`, `payment.updated`, `payment.cancelled`

### FASE 2: FLUXO COMPLETO DE FINALIZAÇÃO ✅ IMPLEMENTADO

#### 2.1 Atualizar PaymentService
```dart
// lib/services/payment_service.dart

// Novo método para verificar status e finalizar
static Future<bool> checkPaymentAndFinalize(String paymentId) async {
  try {
    // 1. Verificar status do pagamento
    final status = await getPaymentStatus(paymentId);
    if (status == null || !status.isApproved) {
      return false;
    }
    
    // 2. Buscar dados do pedido no Firebase
    final order = await getOrderByPaymentId(paymentId);
    if (order == null) {
      return false;
    }
    
    // 3. Criar pedido AliExpress
    final aliexpressOrder = await createAliExpressOrder(
      paymentId: paymentId,
      items: order['items'],
      shippingAddress: order['shipping_address'],
    );
    
    if (aliexpressOrder != null) {
      // 4. Atualizar status no Firebase
      await updateOrderStatus(order['id'], 'pedido_criado', aliexpressOrder);
      
      // 5. Limpar carrinho do usuário
      await clearUserCart(order['customer_email']);
      
      return true;
    }
    
    return false;
  } catch (e) {
    print('❌ Erro ao finalizar pedido: $e');
    return false;
  }
}
```

#### 2.2 Atualizar CheckoutScreen
```dart
// lib/screens/checkout_screen.dart

// Adicionar polling para verificar status
Future<void> _pollPaymentStatus(String paymentId) async {
  int attempts = 0;
  const maxAttempts = 30; // 5 minutos
  
  while (attempts < maxAttempts) {
    await Future.delayed(const Duration(seconds: 10));
    
    final status = await PaymentService.getPaymentStatus(paymentId);
    if (status?.isApproved == true) {
      // Finalizar pedido
      final success = await PaymentService.checkPaymentAndFinalize(paymentId);
      if (success) {
        _showSuccessScreen();
        return;
      }
    } else if (status?.isRejected == true) {
      _showRejectedScreen();
      return;
    }
    
    attempts++;
  }
  
  _showTimeoutScreen();
}
```

### FASE 3: VALIDAÇÕES DE SEGURANÇA

#### 3.1 Validações no Checkout
```dart
// lib/screens/checkout_screen.dart

Future<bool> _validateOrder(CartProvider cartProvider) async {
  try {
    // 1. Verificar disponibilidade dos produtos
    for (final item in cartProvider.items) {
      final product = await ProductService.getProduct(item.product.id);
      if (product == null || !product.isAvailable) {
        throw Exception('Produto ${item.product.name} não está mais disponível');
      }
    }
    
    // 2. Validar endereço
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    if (!addressProvider.hasAddress) {
      throw Exception('Endereço de entrega não informado');
    }
    
    // 3. Verificar se preços não mudaram
    final currentTotal = cartProvider.totalPrice;
    if (currentTotal != _originalTotal) {
      throw Exception('Preços foram atualizados. Atualize seu carrinho.');
    }
    
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
    return false;
  }
}
```

### FASE 4: TRATAMENTO DE ERROS

#### 4.1 Tela de Erro de Pagamento
```dart
// lib/screens/payment_error_screen.dart

class PaymentErrorScreen extends StatelessWidget {
  final String error;
  final String paymentId;
  
  const PaymentErrorScreen({
    required this.error,
    required this.paymentId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Erro no Pagamento')),
      body: Center(
        child: Column(
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            Text('Erro: $error'),
            ElevatedButton(
              onPressed: () => _retryPayment(context),
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### FASE 5: NOTIFICAÇÕES

#### 5.1 Serviço de Notificações
```dart
// lib/services/notification_service.dart

class NotificationService {
  // Enviar email de confirmação
  static Future<bool> sendConfirmationEmail(Order order) async {
    // Implementar envio de email
  }
  
  // Enviar push notification
  static Future<bool> sendPushNotification(String userId, String message) async {
    // Implementar push notification
  }
  
  // Atualizar status em tempo real
  static Stream<OrderStatus> getOrderStatusStream(String orderId) {
    // Implementar stream do Firebase
  }
}
```

## 📊 ESTRUTURA DE DADOS

### Pedido no Firebase
```json
{
  "id": "order_123456789",
  "payment_id": "mp_123456789",
  "customer_email": "cliente@email.com",
  "customer_name": "Nome do Cliente",
  "items": [
    {
      "id": "product_123",
      "title": "Nome do Produto",
      "quantity": 2,
      "unit_price": 29.90,
      "total_price": 59.80,
      "variation": {
        "color": "Azul",
        "size": "M"
      }
    }
  ],
  "shipping_address": {
    "street": "Rua Exemplo",
    "number": "123",
    "complement": "Apto 45",
    "neighborhood": "Centro",
    "city": "São Paulo",
    "state": "SP",
    "zip_code": "01234-567"
  },
  "total_amount": 89.80,
  "shipping_cost": 30.00,
  "status": "aguardando_pagamento",
  "created_at": "2024-01-01T10:00:00Z",
  "updated_at": "2024-01-01T10:00:00Z",
  "aliexpress_order_id": null,
  "admin_notes": "",
  "approved_by": null,
  "approved_at": null
}
```

## 🚀 ORDEM DE IMPLEMENTAÇÃO

1. **FASE 1:** ✅ Webhook do MercadoPago (CRÍTICO) - IMPLEMENTADO
2. **FASE 2:** ✅ Fluxo completo de finalização - IMPLEMENTADO
3. **FASE 3:** ✅ Validações de segurança - IMPLEMENTADO
4. **FASE 4:** ✅ Tratamento de erros - IMPLEMENTADO
5. **FASE 5:** ✅ Notificações - IMPLEMENTADO

## 🧪 TESTES NECESSÁRIOS

1. **Teste de Pagamento Aprovado:**
   - Simular webhook de pagamento aprovado
   - Verificar criação do pedido AliExpress
   - Verificar limpeza do carrinho

2. **Teste de Pagamento Recusado:**
   - Simular webhook de pagamento recusado
   - Verificar atualização de status

3. **Teste de Timeout:**
   - Simular timeout de pagamento
   - Verificar tratamento adequado

4. **Teste de Validações:**
   - Produto indisponível
   - Endereço inválido
   - Preços alterados

## 📝 NOTAS IMPORTANTES

- O webhook é **CRÍTICO** para o funcionamento
- Implementar logs detalhados para debug
- Considerar implementar retry automático
- Testar em ambiente de sandbox primeiro
- Documentar todos os status possíveis
- Implementar monitoramento de erros

## 🔗 ARQUIVOS ENVOLVIDOS

### Frontend (Flutter)
- `lib/screens/checkout_screen.dart`
- `lib/services/payment_service.dart`
- `lib/services/notification_service.dart` (criar)
- `lib/screens/payment_error_screen.dart` (criar)

### Backend (Python)
- `app.py` ou `routes/payment.py`
- `services/mercadopago_service.py`
- `services/order_service.py`

### Firebase
- Collection: `orders`
- Collection: `payments`
- Collection: `notifications`

## 🎯 PRÓXIMOS PASSOS

1. **Testar o webhook** em ambiente de sandbox
2. **Implementar validações de segurança** no checkout
3. **Criar telas de erro** para pagamentos recusados
4. **Implementar sistema de notificações**
5. **Testar fluxo completo** em produção
