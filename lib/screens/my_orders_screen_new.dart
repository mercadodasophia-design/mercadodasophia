import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/order_tracking_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userOrders = await OrderTrackingService.getUserOrders('current_user_id');
      
      setState(() {
        orders = userOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Meus Pedidos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando seus pedidos...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum pedido encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seus pedidos aparecerão aqui após a compra',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/products'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Continuar Comprando'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do pedido
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  _buildStatusChip(order),
                ],
              ),
              const SizedBox(height: 12),
              
              // Informações do pedido
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status do envio
              Row(
                children: [
                  Icon(
                    _getShippingIcon(order.shippingStatus),
                    size: 16,
                    color: _getShippingColor(order.shippingStatus),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.shippingStatusDisplayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getShippingColor(order.shippingStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              if (order.trackingCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.track_changes, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Código: ${order.trackingCode}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Total
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'R\$ ${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Order order) {
    Color color = _getStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        order.statusDisplayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getShippingColor(String shippingStatus) {
    switch (shippingStatus) {
      case 'preparing': return Colors.orange;
      case 'shipped': return Colors.blue;
      case 'in_transit': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'exception': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getShippingIcon(String shippingStatus) {
    switch (shippingStatus) {
      case 'preparing': return Icons.inventory;
      case 'shipped': return Icons.local_shipping;
      case 'in_transit': return Icons.flight;
      case 'delivered': return Icons.check_circle;
      case 'exception': return Icons.error;
      default: return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Detalhes do Pedido',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Número do pedido
                    _buildDetailRow('Número do Pedido', order.id),
                    if (order.aliexpressOrderId != null)
                      _buildDetailRow('ID AliExpress', order.aliexpressOrderId!),
                    _buildDetailRow('Data do Pedido', _formatDate(order.createdAt)),
                    _buildDetailRow('Status', order.statusDisplayText),
                    _buildDetailRow('Status do Envio', order.shippingStatusDisplayText),
                    if (order.trackingCode != null)
                      _buildDetailRow('Código de Rastreio', order.trackingCode!),
                    _buildDetailRow('Total Pago', 'R\$ ${order.totalAmount.toStringAsFixed(2)}'),
                    
                    const SizedBox(height: 24),
                    
                    // Itens do pedido
                    const Text(
                      'Itens do Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...order.items.map((item) => _buildOrderItem(item)),
                    
                    const SizedBox(height: 24),
                    
                    // Botões de ação
                    if (order.aliexpressOrderId != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showOrderTracking(order),
                          icon: const Icon(Icons.track_changes),
                          label: const Text('Rastrear Pedido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Implementar suporte/contato
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Suporte'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Placeholder para imagem
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          
          // Detalhes do item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qtd: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Preço
          Text(
            'R\$ ${item.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderTracking(Order order) async {
    if (order.aliexpressOrderId == null) return;
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final tracking = await OrderTrackingService.getOrderTracking(order.aliexpressOrderId!);
      
      Navigator.pop(context); // Fechar loading
      
      if (tracking != null) {
        // Mostrar detalhes do tracking
        _showTrackingDetails(tracking);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informações de rastreamento não disponíveis'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fechar loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar rastreamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTrackingDetails(OrderTracking tracking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.track_changes, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Rastreamento'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tracking.trackingNumber != null) ...[
                Text(
                  'Código: ${tracking.trackingNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              Text(
                'Status: ${tracking.status}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Histórico:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: tracking.events.length,
                  itemBuilder: (context, index) {
                    final event = tracking.events[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 4,
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      title: Text(
                        event.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        _formatDate(event.timestamp),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
