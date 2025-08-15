import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String paymentId;
  final String customerEmail;
  final String customerName;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> shippingAddress;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? aliexpressOrderId;
  final String adminNotes;
  final String? approvedBy;
  final DateTime? approvedAt;

  Order({
    required this.id,
    required this.paymentId,
    required this.customerEmail,
    required this.customerName,
    required this.items,
    required this.shippingAddress,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.aliexpressOrderId,
    this.adminNotes = '',
    this.approvedBy,
    this.approvedAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Order(
      id: doc.id,
      paymentId: data['payment_id'] ?? '',
      customerEmail: data['customer_email'] ?? '',
      customerName: data['customer_name'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      shippingAddress: Map<String, dynamic>.from(data['shipping_address'] ?? {}),
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'aguardando_envio',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      aliexpressOrderId: data['aliexpress_order_id'],
      adminNotes: data['admin_notes'] ?? '',
      approvedBy: data['approved_by'],
      approvedAt: data['approved_at'] != null 
          ? (data['approved_at'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'customer_email': customerEmail,
      'customer_name': customerName,
      'items': items,
      'shipping_address': shippingAddress,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'aliexpress_order_id': aliexpressOrderId,
      'admin_notes': adminNotes,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
    };
  }

  Order copyWith({
    String? id,
    String? paymentId,
    String? customerEmail,
    String? customerName,
    List<Map<String, dynamic>>? items,
    Map<String, dynamic>? shippingAddress,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? aliexpressOrderId,
    String? adminNotes,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return Order(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      customerEmail: customerEmail ?? this.customerEmail,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aliexpressOrderId: aliexpressOrderId ?? this.aliexpressOrderId,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  // Status helpers
  bool get isPendingApproval => status == 'aguardando_envio';
  bool get isApproved => status == 'aprovado';
  bool get isRejected => status == 'rejeitado';
  bool get isShipped => status == 'enviado';
  bool get isDelivered => status == 'entregue';

  // Status display
  String get statusDisplay {
    switch (status) {
      case 'aguardando_envio':
        return 'Aguardando Envio';
      case 'aprovado':
        return 'Aprovado';
      case 'rejeitado':
        return 'Rejeitado';
      case 'enviado':
        return 'Enviado';
      case 'entregue':
        return 'Entregue';
      default:
        return status;
    }
  }

  // Status color
  int get statusColor {
    switch (status) {
      case 'aguardando_envio':
        return 0xFFFFA500; // Orange
      case 'aprovado':
        return 0xFF4CAF50; // Green
      case 'rejeitado':
        return 0xFFF44336; // Red
      case 'enviado':
        return 0xFF2196F3; // Blue
      case 'entregue':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}

