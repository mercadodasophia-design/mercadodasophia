import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/product_detail_service.dart';

class AdminImportedProductsScreen extends StatefulWidget {
  const AdminImportedProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminImportedProductsScreen> createState() => _AdminImportedProductsScreenState();
}

class _AdminImportedProductsScreenState extends State<AdminImportedProductsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _importedProducts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImportedProducts();
  }

  Future<void> _loadImportedProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Buscar produtos importados do Firebase
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'aguardando-revisao')
          .orderBy('createdAt', descending: true)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _importedProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar produtos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Produtos Importados'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImportedProducts,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImportedProducts,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_importedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto importado ainda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Importe produtos do AliExpress para começar',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/admin/search'),
              icon: const Icon(Icons.search),
              label: const Text('Buscar Produtos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadImportedProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _importedProducts.length,
        itemBuilder: (context, index) {
          final product = _importedProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _openProductEdit(product),
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
                    product['image_url'] ?? '',
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
                      product['title'] ?? 'Produto sem título',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${product['aliexpress_id']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preço: R\$ ${_formatPrice(product['price'])}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Aguardando Revisão',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Ícone de edição
              Icon(
                Icons.edit,
                color: Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProductEdit(Map<String, dynamic> product) {
    // Navegar para a tela de edição do produto
    Navigator.of(context).pushNamed(
      '/admin/product-edit',
      arguments: product,
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    
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
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Gerenciar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/manage-products');
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