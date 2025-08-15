import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  static const String _baseUrl = 'https://service-api-aliexpress.mercadodasophia.com.br';
  
  // Criar preferência de pagamento via Mercado Pago
  static Future<PaymentPreference?> createPaymentPreference({
    required String orderId,
    required double totalAmount,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? shippingAddress,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/payment/process');
      
      final payload = {
        'order_id': orderId,
        'total_amount': totalAmount,
        'items': items,
        'customer_info': {
          'email': customerEmail,
          'name': customerName.split(' ').first,
          'surname': customerName.split(' ').length > 1 
              ? customerName.split(' ').sublist(1).join(' ')
              : '',
          'phone': {
            'area_code': customerPhone.length >= 11 ? customerPhone.substring(0, 2) : '85',
            'number': customerPhone.length >= 11 ? customerPhone.substring(2) : customerPhone,
          }
        },
        'shipping_address': shippingAddress,
      };
      
      print('🔄 Enviando dados de pagamento: ${jsonEncode(payload)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return PaymentPreference.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Erro desconhecido');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao criar preferência de pagamento: $e');
      rethrow;
    }
  }
  
  // Verificar status do pagamento
  static Future<PaymentStatus?> getPaymentStatus(String paymentId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/payment/mp/payment/$paymentId');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return PaymentStatus.fromJson(data['payment_data']);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao verificar status do pagamento: $e');
      return null;
    }
  }
  
  // Salvar pedido no Firebase após pagamento aprovado (chamado pelo webhook)
  static Future<bool> saveOrderToFirebase({
    required String paymentId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required double totalAmount,
    required String customerEmail,
    required String customerName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      final orderData = {
        'payment_id': paymentId,
        'customer_email': customerEmail,
        'customer_name': customerName,
        'items': items,
        'shipping_address': shippingAddress,
        'total_amount': totalAmount,
        'status': 'aguardando_envio', // Status inicial
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'aliexpress_order_id': null,
        'admin_notes': '',
        'approved_by': null,
        'approved_at': null,
      };
      
      await firestore.collection('orders').add(orderData);
      
      print('✅ Pedido salvo no Firebase com status: aguardando_envio');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar pedido no Firebase: $e');
      return false;
    }
  }

  // Criar pedido AliExpress após pagamento aprovado
  static Future<AliExpressOrder?> createAliExpressOrder({
    required String paymentId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/payment/complete/$paymentId');
      
      final payload = {
        'items': items,
        'address': shippingAddress,
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return AliExpressOrder.fromJson(data);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao criar pedido AliExpress: $e');
      return null;
    }
  }
}

// Modelos de dados
class PaymentPreference {
  final String preferenceId;
  final String initPoint;
  final String? sandboxInitPoint;
  final String orderId;
  
  PaymentPreference({
    required this.preferenceId,
    required this.initPoint,
    this.sandboxInitPoint,
    required this.orderId,
  });
  
  factory PaymentPreference.fromJson(Map<String, dynamic> json) {
    return PaymentPreference(
      preferenceId: json['preference_id'] ?? '',
      initPoint: json['init_point'] ?? '',
      sandboxInitPoint: json['sandbox_init_point'],
      orderId: json['order_id'] ?? '',
    );
  }
}

class PaymentStatus {
  final String id;
  final String status;
  final String statusDetail;
  final double transactionAmount;
  final String currencyId;
  final String? externalReference;
  
  PaymentStatus({
    required this.id,
    required this.status,
    required this.statusDetail,
    required this.transactionAmount,
    required this.currencyId,
    this.externalReference,
  });
  
  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      statusDetail: json['status_detail'] ?? '',
      transactionAmount: (json['transaction_amount'] ?? 0).toDouble(),
      currencyId: json['currency_id'] ?? 'BRL',
      externalReference: json['external_reference'],
    );
  }
  
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

class AliExpressOrder {
  final String orderId;
  final String orderNumber;
  final String status;
  final List<AliExpressOrderItem> items;
  
  AliExpressOrder({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.items,
  });
  
  factory AliExpressOrder.fromJson(Map<String, dynamic> json) {
    return AliExpressOrder(
      orderId: json['order_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => AliExpressOrderItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class AliExpressOrderItem {
  final String productId;
  final String title;
  final int quantity;
  final double price;
  
  AliExpressOrderItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
  });
  
  factory AliExpressOrderItem.fromJson(Map<String, dynamic> json) {
    return AliExpressOrderItem(
      productId: json['product_id'] ?? '',
      title: json['title'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
