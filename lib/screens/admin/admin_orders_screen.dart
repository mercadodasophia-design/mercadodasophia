import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../services/payment_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  List<Order> _orders = [];
  String _selectedStatus = 'todos';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = firestore.FirebaseFirestore.instance;
      firestore.Query query = db.collection('orders').orderBy('created_at', descending: true);

      // Filtrar por status se selecionado
      if (_selectedStatus != 'todos') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      final querySnapshot = await query.get();
      
      setState(() {
        _orders = querySnapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar pedidos: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar pedidos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Pedidos'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filtrar por status: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: [
                    const DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    const DropdownMenuItem(value: 'aguardando_envio', child: Text('Aguardando Envio')),
                    const DropdownMenuItem(value: 'aprovado', child: Text('Aprovado')),
                    const DropdownMenuItem(value: 'rejeitado', child: Text('Rejeitado')),
                    const DropdownMenuItem(value: 'enviado', child: Text('Enviado')),
                    const DropdownMenuItem(value: 'entregue', child: Text('Entregue')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _loadOrders();
                  },
                ),
              ],
            ),
          ),
          
          // Lista de pedidos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum pedido encontrado',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.customerName,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(order.statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Detalhes do pedido
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: R\$ ${order.totalAmount.toStringAsFixed(2)}'),
                      Text('Itens: ${order.items.length}'),
                      if (order.aliexpressOrderId != null)
                        Text('AliExpress: ${order.aliexpressOrderId}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Criado: ${_formatDate(order.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (order.approvedAt != null)
                      Text(
                        'Aprovado: ${_formatDate(order.approvedAt!)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ações
            if (order.isPendingApproval)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aprovar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rejectOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Rejeitar'),
                    ),
                  ),
                ],
              ),
            
            if (order.isApproved && order.aliexpressOrderId == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _createAliExpressOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Criar Pedido AliExpress'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveOrder(Order order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar Pedido'),
        content: const Text('Tem certeza que deseja aprovar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Atualizar status no Firebase
        final db = firestore.FirebaseFirestore.instance;
        await db.collection('orders').doc(order.id).update({
          'status': 'aprovado',
          'approved_by': 'admin',
          'approved_at': firestore.FieldValue.serverTimestamp(),
          'updated_at': firestore.FieldValue.serverTimestamp(),
        });

        // Recarregar lista
        _loadOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido aprovado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao aprovar pedido: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectOrder(Order order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Pedido'),
        content: const Text('Tem certeza que deseja rejeitar este pedido? O pagamento será estornado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Atualizar status no Firebase
        final db = firestore.FirebaseFirestore.instance;
        await db.collection('orders').doc(order.id).update({
          'status': 'rejeitado',
          'rejected_by': 'admin',
          'rejected_at': firestore.FieldValue.serverTimestamp(),
          'updated_at': firestore.FieldValue.serverTimestamp(),
        });

        // Recarregar lista
        _loadOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido rejeitado com sucesso!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao rejeitar pedido: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _createAliExpressOrder(Order order) async {
    try {
      // Chamar API do servidor para criar pedido no AliExpress
      final result = await PaymentService.createAliExpressOrder(
        paymentId: order.paymentId,
        items: order.items,
        shippingAddress: order.shippingAddress,
      );

      if (result != null) {
        // Atualizar pedido com ID do AliExpress
        final db = firestore.FirebaseFirestore.instance;
        await db.collection('orders').doc(order.id).update({
          'aliexpress_order_id': result.orderId,
          'updated_at': firestore.FieldValue.serverTimestamp(),
        });

        // Recarregar lista
        _loadOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido AliExpress criado: ${result.orderId}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar pedido AliExpress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
