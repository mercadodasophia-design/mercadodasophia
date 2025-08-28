import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/order_tracking_service.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../config/api_config.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String selectedFilter = 'Todos';
  List<Order> orders = [];
  List<String> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      context.go('/login');
      return;
    }
    _loadOrders();
    _loadCategories();
    _checkAndClearCartIfNeeded();
  }

  Future<void> _checkAndClearCartIfNeeded() async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final wasCleared = await cartProvider.checkAndClearCartIfPaymentApproved();
      
      if (wasCleared && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pagamento confirmado! Carrinho limpo automaticamente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Erro ao verificar carrinho: $e');
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Obter ID do usuário logado
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }
      
      print('👤 Usuário logado: ${user.uid} - ${user.email}');
      
      // Buscar pedidos reais do Firebase
      final userOrders = await OrderTrackingService.getUserOrders(user.uid);
      
      setState(() {
        orders = userOrders;
        isLoading = false;
      });
      
      print('📦 Pedidos carregados: ${orders.length}');
      
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      print('❌ Erro ao carregar pedidos: $e');
      
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

  Future<void> _loadCategories() async {
    try {
      print('🏷️ Carregando categorias do Firebase...');
      
      // Buscar categorias do Firebase
      final db = FirebaseFirestore.instance;
      final categoriesSnapshot = await db
          .collection('categories')
          .orderBy('name')
          .get();
      
      final List<String> categoryNames = [];
      
      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'] as String?;
        if (categoryName != null && categoryName.isNotEmpty) {
          categoryNames.add(categoryName);
        }
      }
      
      // Se não houver categorias no Firebase, buscar das seções de produtos
      if (categoryNames.isEmpty) {
        print('📦 Buscando categorias das seções de produtos...');
        
        // Buscar produtos e extrair categorias únicas
        final productsSnapshot = await db
            .collection('products')
            .get();
        
        final Set<String> uniqueCategories = {};
        
        for (final doc in productsSnapshot.docs) {
          final data = doc.data();
          final category = data['category'] as String?;
          if (category != null && category.isNotEmpty) {
            uniqueCategories.add(category);
          }
        }
        
        categoryNames.addAll(uniqueCategories.toList()..sort());
      }
      
      setState(() {
        categories = categoryNames;
      });
      
      print('✅ Categorias carregadas: ${categories.length}');
      
    } catch (e) {
      print('❌ Erro ao carregar categorias: $e');
      // Em caso de erro, usar categorias padrão
      setState(() {
        categories = [
          'Garrafeira',
          'Compotas e Mel',
          'Doces',
          'Chás e Refrescos',
          'Queijos e Pão',
        ];
      });
    }
  }

  List<Order> get filteredOrders {
    if (selectedFilter == 'Todos') {
      return orders;
    } else if (selectedFilter == 'Entregue') {
      return orders.where((order) => order.status == 'delivered').toList();
    } else if (selectedFilter == 'Em trânsito') {
      return orders.where((order) => order.shippingStatus == 'in_transit').toList();
    } else if (selectedFilter == 'Cancelado') {
      return orders.where((order) => order.status == 'cancelled').toList();
    } else if (selectedFilter == 'Enviado') {
      return orders.where((order) => order.status == 'shipped').toList();
    } else if (selectedFilter == 'Confirmado') {
      return orders.where((order) => order.status == 'confirmed').toList();
    } else if (selectedFilter == 'Aguardando Pagamento') {
      return orders.where((order) => order.status == 'pending').toList();
    }
    return orders;
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
          'Minhas Compras',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/produtos');
            }
          },
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
              child: SingleChildScrollView(
                child: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Resumo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total de Pedidos',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${orders.length} pedidos',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtros
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', selectedFilter == 'Todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Aguardando Pagamento', selectedFilter == 'Aguardando Pagamento'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Confirmado', selectedFilter == 'Confirmado'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Enviado', selectedFilter == 'Enviado'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Entregue', selectedFilter == 'Entregue'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cancelado', selectedFilter == 'Cancelado'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de pedidos
            filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
            
            // Rodapé
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Seção superior (cinza claro)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[200],
                    child: Column(
                      children: [
                        const Text(
                          'Categorias',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 16,
                          runSpacing: 16,
                          children: categories.map((category) => _buildFooterCategory(category)).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Seção inferior (preta)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black,
                    child: Column(
                      children: [
                        const Text(
                          'Mercado da Sophia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rua das Flores, 123 - Centro',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          'República, São Paulo - SP, 01037-010',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          children: [
                            _buildFooterContact(Icons.phone, '(85) 99764-0050'),
                            _buildFooterContact(Icons.email, 'contato@mercadodasophia.com'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '© 2024 Mercado da Sophia. Todos os direitos reservados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
                ),
              ),
            ),
    );
  }



  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = label;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do pedido
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido ${order.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        color: _getStatusColor(order.status),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                      Text(
                        '${order.items.length} itens',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
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
                ),
                ElevatedButton(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Ver Detalhes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você ainda não fez nenhuma compra',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Fazer Primeira Compra'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido ${order.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Conteúdo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(order.status),
                            color: _getStatusColor(order.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Detalhes
                    const Text(
                      'Detalhes do Pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('Número do Pedido', order.id),
                    _buildDetailRow('Data', '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}'),
                    _buildDetailRow('Itens', '${order.items.length} produtos'),
                    _buildDetailRow('Total', 'R\$ ${order.totalAmount.toStringAsFixed(2)}'),
                    
                    const Spacer(),
                    
                    // Botões de ação
                    Column(
                      children: [
                        if (order.status == 'pending') ...[
                          // Botão para tentar pagamento novamente
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _retryPayment(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Tentar Pagamento Novamente'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Botão para ver produtos
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _viewOrderItems(order),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Ver Produtos'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Botão para cancelar pedido
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _cancelOrder(order),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancelar Pedido'),
                            ),
                          ),
                        ] else ...[
                          // Botões para outros status
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                                  onPressed: () => _viewOrderItems(order),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                            ),
                                  child: const Text('Ver Produtos'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implementar rastreamento
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Rastrear'),
                          ),
                        ),
                      ],
                          ),
                          if (order.status == 'confirmed' || order.status == 'processing') ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _cancelOrder(order),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Cancelar Pedido'),
                              ),
                            ),
                          ],
                        ],
                      ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCategory(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildFooterContact(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // Helper functions for status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.payment;
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.build;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Aguardando Pagamento';
      case 'confirmed':
        return 'Confirmado';
      case 'processing':
        return 'Processando';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregue';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  Future<void> _retryPayment(Order order) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fazer requisição para gerar nova preferência
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/${order.id}/retry-payment'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      // Fechar loading
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['success']) {
          // Redirecionar para o Mercado Pago
          final initPoint = result['init_point'];
          
          if (await canLaunchUrl(Uri.parse(initPoint))) {
            await launchUrl(Uri.parse(initPoint), mode: LaunchMode.externalApplication);
            
            // Mostrar mensagem de sucesso
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Nova preferência gerada! Redirecionando para o Mercado Pago...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            throw Exception('Não foi possível abrir o link de pagamento');
          }
        } else {
          throw Exception(result['message'] ?? 'Erro ao gerar preferência');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao tentar pagamento novamente: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(Order order) async {
    try {
      // Mostrar diálogo de confirmação
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: const Text('Tem certeza que deseja cancelar este pedido? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sim, Cancelar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fazer requisição para cancelar pedido
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/${order.id}/cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': 'Cancelado pelo usuário',
        }),
      );

      // Fechar loading
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['success']) {
          // Recarregar pedidos
          await _loadOrders();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pedido cancelado com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception(result['message'] ?? 'Erro ao cancelar pedido');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao cancelar pedido: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _viewOrderItems(Order order) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fazer requisição para buscar itens do pedido
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/${order.id}/items'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Fechar loading
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['success']) {
          final items = result['items'] as List;
          
          // Mostrar modal com os produtos
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Produtos do Pedido',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    order.id,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      
                      // Lista de produtos
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              ...items.map((item) => Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Imagem do produto
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (item['imageUrl'] != null || item['image'] != null || (item['variation']?['image'] != null))
                                            ? Image.network(
                                                item['imageUrl'] ?? item['image'] ?? item['variation']?['image'] ?? '',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, color: Colors.grey),
                                                ),
                                              )
                                            : Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.image, color: Colors.grey),
                                              ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // Informações do produto
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title']?.isNotEmpty == true 
                                                  ? item['title'] 
                                                  : item['name']?.isNotEmpty == true 
                                                      ? item['name'] 
                                                      : 'Produto ${item['id'] ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Quantidade: ${item['quantity']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Preço unitário: R\$ ${(item['unit_price'] ?? item['price'] ?? 0.0).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Preço total do item
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'R\$ ${(item['total_price'] ?? ((item['unit_price'] ?? item['price'] ?? 0.0) * (item['quantity'] ?? 1))).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )).toList(),
                              
                              const SizedBox(height: 20),
                              
                              // Total do pedido
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total do Pedido:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'R\$ ${(result['total'] ?? 0.0).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else {
          throw Exception(result['message'] ?? 'Erro ao buscar itens');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao buscar itens do pedido: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 