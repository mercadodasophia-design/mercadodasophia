import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingService {
  static const String _baseUrl = 'https://service-api-aliexpress.mercadodasophia.com.br';
  
  // Buscar pedidos do usuário
  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      print('🔍 Buscando pedidos do usuário: $userId');
      
      // Buscar pedidos do Firebase
      final firestore = FirebaseFirestore.instance;
      final ordersSnapshot = await firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('📦 Encontrados ${ordersSnapshot.docs.length} pedidos no Firebase');
      
      final List<Order> orders = [];
      
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        print('📋 Dados do pedido ${doc.id}: ${jsonEncode(data)}');
        
        try {
          final order = Order.fromFirebaseData(doc.id, data);
          orders.add(order);
        } catch (e) {
          print('❌ Erro ao converter pedido ${doc.id}: $e');
        }
      }
      
      print('✅ Pedidos carregados com sucesso: ${orders.length}');
      return orders;
      
    } catch (e) {
      print('❌ Erro ao buscar pedidos do Firebase: $e');
      return [];
    }
  }
  
  // Buscar tracking de um pedido específico via API
  static Future<OrderTracking?> getOrderTracking(String orderId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/aliexpress/orders/$orderId/tracking');
      
      final response = await http.get(url);
      
      print('📡 Tracking request: $url');
      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return OrderTracking.fromJson(data['tracking_info']);
        } else {
          throw Exception(data['message'] ?? 'Erro ao buscar tracking');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao buscar tracking: $e');
      return null;
    }
  }
  
  // Buscar relações pagamento → pedido
  static Future<List<PaymentOrderRelation>> getPaymentOrderRelations() async {
    try {
      final url = Uri.parse('$_baseUrl/api/orders/relations');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return (data['relations'] as List)
              .map((item) => PaymentOrderRelation.fromJson(item))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Erro ao buscar relações: $e');
      return [];
    }
  }
}

// Modelos de dados
class Order {
  final String id;
  final String? aliexpressOrderId;
  final String status;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentStatus;
  final String shippingStatus;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final String? trackingCode;
  
  Order({
    required this.id,
    this.aliexpressOrderId,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.paymentStatus,
    required this.shippingStatus,
    required this.createdAt,
    this.estimatedDelivery,
    this.trackingCode,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      aliexpressOrderId: json['aliexpress_order_id'],
      status: json['status'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? '',
      shippingStatus: json['shipping_status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      estimatedDelivery: DateTime.tryParse(json['estimated_delivery'] ?? ''),
      trackingCode: json['tracking_code'],
    );
  }
  
  factory Order.fromFirebaseData(String orderId, Map<String, dynamic> data) {
    // Converter dados do Firebase para o formato da classe Order
    final items = (data['items'] as List?)
        ?.map((item) => OrderItem(
              title: item['title'] ?? item['name'] ?? 'Produto',
              quantity: item['quantity'] ?? 1,
              price: (item['price'] ?? 0).toDouble(),
              imageUrl: item['imageUrl'] ?? item['image'],
            ))
        .toList() ?? [];
    
    // Mapear status do Firebase para status da aplicação
    String status = 'pending';
    String shippingStatus = 'preparing';
    
    switch (data['status']) {
      case 'aguardando_pagamento':
        status = 'pending';
        shippingStatus = 'preparing';
        break;
      case 'pago':
        status = 'confirmed';
        shippingStatus = 'preparing';
        break;
      case 'em_andamento':
        status = 'processing';
        shippingStatus = 'preparing';
        break;
      case 'pedido_criado':
        status = 'confirmed';
        shippingStatus = 'shipped';
        break;
      case 'entregue':
        status = 'delivered';
        shippingStatus = 'delivered';
        break;
      case 'cancelado':
        status = 'cancelled';
        shippingStatus = 'exception';
        break;
      default:
        status = data['status'] ?? 'pending';
        shippingStatus = 'preparing';
    }
    
    return Order(
      id: orderId,
      aliexpressOrderId: data['aliexpressOrderId'],
      status: status,
      items: items,
      totalAmount: (data['total'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      shippingStatus: shippingStatus,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      estimatedDelivery: null, // Será calculado quando necessário
      trackingCode: data['trackingCode'],
    );
  }
  
  String get statusDisplayText {
    switch (status) {
      case 'pending': return 'Aguardando Pagamento';
      case 'confirmed': return 'Pedido Confirmado';
      case 'processing': return 'Processando';
      case 'shipped': return 'Enviado';
      case 'delivered': return 'Entregue';
      case 'cancelled': return 'Cancelado';
      default: return 'Status Desconhecido';
    }
  }
  
  String get shippingStatusDisplayText {
    switch (shippingStatus) {
      case 'preparing': return 'Preparando envio';
      case 'shipped': return 'Enviado';
      case 'in_transit': return 'Em trânsito';
      case 'delivered': return 'Entregue';
      case 'exception': return 'Problema na entrega';
      default: return 'Status desconhecido';
    }
  }
}

class OrderItem {
  final String title;
  final int quantity;
  final double price;
  final String? imageUrl;
  
  OrderItem({
    required this.title,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      title: json['title'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
    );
  }
}

class OrderTracking {
  final String orderId;
  final String status;
  final List<TrackingEvent> events;
  final String? trackingNumber;
  final String? carrierName;
  
  OrderTracking({
    required this.orderId,
    required this.status,
    required this.events,
    this.trackingNumber,
    this.carrierName,
  });
  
  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? '',
      events: (json['events'] as List?)
          ?.map((event) => TrackingEvent.fromJson(event))
          .toList() ?? [],
      trackingNumber: json['tracking_number'],
      carrierName: json['carrier_name'],
    );
  }
}

class TrackingEvent {
  final String status;
  final String description;
  final DateTime timestamp;
  final String? location;
  
  TrackingEvent({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
  });
  
  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      location: json['location'],
    );
  }
}

class PaymentOrderRelation {
  final String paymentId;
  final String externalReference;
  final String aliexpressOrderId;
  final DateTime createdAt;
  final String status;
  
  PaymentOrderRelation({
    required this.paymentId,
    required this.externalReference,
    required this.aliexpressOrderId,
    required this.createdAt,
    required this.status,
  });
  
  factory PaymentOrderRelation.fromJson(Map<String, dynamic> json) {
    return PaymentOrderRelation(
      paymentId: json['payment_id'] ?? '',
      externalReference: json['external_reference'] ?? '',
      aliexpressOrderId: json['aliexpress_order_id'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['created_at'] ?? 0) * 1000).round()
      ),
      status: json['status'] ?? '',
    );
  }
}
