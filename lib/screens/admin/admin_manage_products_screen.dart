import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminManageProductsScreen extends StatefulWidget {
  const AdminManageProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageProductsScreen> createState() => _AdminManageProductsScreenState();
}

class _AdminManageProductsScreenState extends State<AdminManageProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, List<Map<String, dynamic>>> _productsByStatus = {
    'revisao': [],
    'publicados': [],
    'removidos': [],
  };
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
    
    // Verificar se há argumentos para navegar para uma aba específica
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialTab')) {
        final initialTab = args['initialTab'] as int;
        if (initialTab >= 0 && initialTab < 3) {
          _tabController.animateTo(initialTab);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar produtos por status
      final statuses = ['aguardando-revisao', 'published', 'removed'];
      final statusKeys = ['revisao', 'publicados', 'removidos'];

      for (int i = 0; i < statuses.length; i++) {
                 final snapshot = await FirebaseFirestore.instance
             .collection('products')
             .where('status', isEqualTo: statuses[i])
             .orderBy('created_at', descending: true)
             .get();

        final products = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _productsByStatus[statusKeys[i]] = products;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar produtos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gerenciar Produtos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending),
              text: 'Revisão',
            ),
            Tab(
              icon: Icon(Icons.published_with_changes),
              text: 'Publicados',
            ),
            Tab(
              icon: Icon(Icons.delete_outline),
              text: 'Removidos',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList('revisao'),
          _buildProductList('publicados'),
          _buildProductList('removidos'),
        ],
      ),
    );
  }

  Widget _buildProductList(String status) {
    final products = _productsByStatus[status] ?? [];

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (products.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product, status);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case 'revisao':
        title = 'Nenhum produto em revisão';
        subtitle = 'Produtos aguardando revisão aparecerão aqui';
        icon = Icons.pending;
        break;
      case 'publicados':
        title = 'Nenhum produto publicado';
        subtitle = 'Produtos publicados aparecerão aqui';
        icon = Icons.published_with_changes;
        break;
      case 'removidos':
        title = 'Nenhum produto removido';
        subtitle = 'Produtos removidos aparecerão aqui';
        icon = Icons.delete_outline;
        break;
      default:
        title = 'Nenhum produto';
        subtitle = 'Nenhum produto encontrado';
        icon = Icons.inventory_2;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case 'revisao':
        statusColor = Colors.orange;
        statusText = 'Aguardando Revisão';
        break;
      case 'publicados':
        statusColor = Colors.green;
        statusText = 'Publicado';
        break;
      case 'removidos':
        statusColor = Colors.red;
        statusText = 'Removido';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconhecido';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _openProductDetails(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagem do produto
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['main_image'] ?? product['image_url'] ?? product['images']?.first ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 30),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações do produto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? product['title'] ?? 'Produto sem título',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${product['aliexpress_id'] ?? product['id'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preço: R\$ ${_formatPrice(product['price']) ?? _formatPrice(product['sale_price']) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Indicador de draft/alterações não salvas
                        if (product['has_unsaved_changes'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 10, color: Colors.amber[700]),
                                const SizedBox(width: 3),
                                Text(
                                  'Rascunho',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.amber[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menu de ações
              PopupMenuButton<String>(
                onSelected: (value) => _handleProductAction(value, product),
                itemBuilder: (context) => _buildProductActions(status),
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildProductActions(String status) {
    final actions = <PopupMenuEntry<String>>[];

    switch (status) {
      case 'revisao':
        actions.addAll([
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'publish',
            child: Row(
              children: [
                Icon(Icons.publish, size: 20),
                SizedBox(width: 8),
                Text('Publicar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 8),
                Text('Remover'),
              ],
            ),
          ),
        ]);
        break;
      case 'publicados':
        actions.addAll([
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          if (product['aliexpress_id'] != null && product['aliexpress_id'].toString().isNotEmpty)
            PopupMenuItem(
              value: 'check_aliexpress_status',
              child: Row(
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 8),
                  Text('Verificar Status AliExpress'),
                ],
              ),
            ),
                     PopupMenuItem(
             value: 'unpublish',
             child: Row(
               children: [
                 Icon(Icons.unpublished, size: 20),
                 SizedBox(width: 8),
                 Text('Despublicar'),
               ],
             ),
           ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 8),
                Text('Remover'),
              ],
            ),
          ),
        ]);
        break;
      case 'removidos':
        actions.addAll([
          const PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                Icon(Icons.restore, size: 20),
                SizedBox(width: 8),
                Text('Restaurar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete_permanent',
            child: Row(
              children: [
                Icon(Icons.delete_forever, size: 20),
                SizedBox(width: 8),
                Text('Excluir Permanentemente'),
              ],
            ),
          ),
        ]);
        break;
    }

    return actions;
  }

  Future<void> _checkAliExpressStatus(String aliexpressId) async {
    if (aliexpressId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto não possui ID do AliExpress'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://service-api-aliexpress.mercadodasophia.com.br/api/aliexpress/product-status/$aliexpressId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final statusData = data['data'];
          final statusDescription = statusData['status_description'] ?? 'Status desconhecido';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status AliExpress: $statusDescription'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${data['message'] ?? 'Erro desconhecido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ${response.statusCode}: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  void _handleProductAction(String action, Map<String, dynamic> product) async {
    try {
      final productId = product['id'];
      String newStatus = '';
      String message = '';

      switch (action) {
        case 'edit':
          _openProductDetails(product);
          return;
        case 'publish':
          newStatus = 'published';
          message = 'Produto publicado com sucesso!';
          break;
        case 'unpublish':
          newStatus = 'aguardando-revisao';
          message = 'Produto despublicado com sucesso!';
          break;
        case 'delete':
          newStatus = 'removed';
          message = 'Produto removido com sucesso!';
          break;
        case 'restore':
          newStatus = 'aguardando-revisao';
          message = 'Produto restaurado com sucesso!';
          break;
        case 'delete_permanent':
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .delete();
          message = 'Produto excluído permanentemente!';
          break;
      }

      if (newStatus.isNotEmpty) {
                 await FirebaseFirestore.instance
             .collection('products')
             .doc(productId)
             .update({
           'status': newStatus,
           'updated_at': DateTime.now().toIso8601String(),
         });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao executar ação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openProductDetails(Map<String, dynamic> product) {
    // Navegar para a tela de detalhes/edição do produto
    Navigator.of(context).pushNamed(
      '/admin/product-edit',
      arguments: product,
    );
  }

  String? _formatPrice(dynamic price) {
    if (price == null) return null;
    
    if (price is String) {
      return price;
    } else if (price is num) {
      return price.toStringAsFixed(2);
    } else {
      return price.toString();
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mercado da Sophia',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Itens do menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.search,
                  title: 'Buscar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/aliexpress');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  title: 'Produtos Importados',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/imported-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Gerenciar Produtos',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categorias',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/categories');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.orange : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
} 