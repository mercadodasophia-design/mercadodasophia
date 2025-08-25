import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Enviar email de confirmação (simulado)
  static Future<bool> sendConfirmationEmail(Map<String, dynamic> order) async {
    try {
      // Em produção, integrar com serviço de email (SendGrid, Mailgun, etc.)
      print('📧 Email de confirmação enviado para: ${order['customer_email']}');
      print('📧 Pedido: ${order['id']} - Total: R\$ ${order['total_amount']}');
      
      // Salvar no Firebase para histórico
      await _firestore.collection('notifications').add({
        'type': 'email_confirmation',
        'order_id': order['id'],
        'customer_email': order['customer_email'],
        'status': 'sent',
        'created_at': FieldValue.serverTimestamp(),
        'content': {
          'subject': 'Pedido Confirmado - Mercado da Sophia',
          'body': 'Seu pedido foi confirmado e está sendo processado.',
        },
      });
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar email de confirmação: $e');
      return false;
    }
  }

  // Enviar push notification (simulado)
  static Future<bool> sendPushNotification(String userId, String message) async {
    try {
      // Em produção, integrar com Firebase Cloud Messaging (FCM)
      print('📱 Push notification enviado para: $userId');
      print('📱 Mensagem: $message');
      
      // Salvar no Firebase para histórico
      await _firestore.collection('notifications').add({
        'type': 'push_notification',
        'user_id': userId,
        'status': 'sent',
        'created_at': FieldValue.serverTimestamp(),
        'content': {
          'title': 'Mercado da Sophia',
          'body': message,
        },
      });
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar push notification: $e');
      return false;
    }
  }

  // Atualizar status em tempo real
  static Stream<Map<String, dynamic>> getOrderStatusStream(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return {};
    });
  }

  // Enviar notificação de rastreamento
  static Future<bool> sendTrackingNotification(Map<String, dynamic> order) async {
    try {
      final message = 'Seu pedido ${order['id']} foi enviado! Acompanhe o rastreamento.';
      
      // Enviar push notification
      if (order['customer_id'] != null) {
        await sendPushNotification(order['customer_id'], message);
      }
      
      // Enviar email de rastreamento
      await sendTrackingEmail(order);
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar notificação de rastreamento: $e');
      return false;
    }
  }

  // Enviar email de rastreamento
  static Future<bool> sendTrackingEmail(Map<String, dynamic> order) async {
    try {
      print('📧 Email de rastreamento enviado para: ${order['customer_email']}');
      print('📧 Pedido: ${order['id']} - Código de rastreamento: ${order['tracking_code']}');
      
      // Salvar no Firebase para histórico
      await _firestore.collection('notifications').add({
        'type': 'tracking_email',
        'order_id': order['id'],
        'customer_email': order['customer_email'],
        'status': 'sent',
        'created_at': FieldValue.serverTimestamp(),
        'content': {
          'subject': 'Pedido Enviado - Mercado da Sophia',
          'body': 'Seu pedido foi enviado! Acompanhe o rastreamento.',
          'tracking_code': order['tracking_code'],
        },
      });
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar email de rastreamento: $e');
      return false;
    }
  }

  // Enviar notificação de pagamento aprovado
  static Future<bool> sendPaymentApprovedNotification(Map<String, dynamic> order) async {
    try {
      final message = 'Pagamento aprovado! Seu pedido ${order['id']} está sendo processado.';
      
      // Enviar push notification
      if (order['customer_id'] != null) {
        await sendPushNotification(order['customer_id'], message);
      }
      
      // Enviar email de confirmação
      await sendConfirmationEmail(order);
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar notificação de pagamento aprovado: $e');
      return false;
    }
  }

  // Enviar notificação de pagamento recusado
  static Future<bool> sendPaymentRejectedNotification(Map<String, dynamic> order) async {
    try {
      final message = 'Pagamento recusado para o pedido ${order['id']}. Tente novamente.';
      
      // Enviar push notification
      if (order['customer_id'] != null) {
        await sendPushNotification(order['customer_id'], message);
      }
      
      // Enviar email de pagamento recusado
      await sendPaymentRejectedEmail(order);
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar notificação de pagamento recusado: $e');
      return false;
    }
  }

  // Enviar email de pagamento recusado
  static Future<bool> sendPaymentRejectedEmail(Map<String, dynamic> order) async {
    try {
      print('📧 Email de pagamento recusado enviado para: ${order['customer_email']}');
      
      // Salvar no Firebase para histórico
      await _firestore.collection('notifications').add({
        'type': 'payment_rejected_email',
        'order_id': order['id'],
        'customer_email': order['customer_email'],
        'status': 'sent',
        'created_at': FieldValue.serverTimestamp(),
        'content': {
          'subject': 'Pagamento Recusado - Mercado da Sophia',
          'body': 'Seu pagamento foi recusado. Verifique os dados e tente novamente.',
        },
      });
      
      return true;
    } catch (e) {
      print('❌ Erro ao enviar email de pagamento recusado: $e');
      return false;
    }
  }

  // Obter histórico de notificações do usuário
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // Marcar notificação como lida
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read_at': FieldValue.serverTimestamp(),
        'is_read': true,
      });
      
      return true;
    } catch (e) {
      print('❌ Erro ao marcar notificação como lida: $e');
      return false;
    }
  }

  // Contar notificações não lidas
  static Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

