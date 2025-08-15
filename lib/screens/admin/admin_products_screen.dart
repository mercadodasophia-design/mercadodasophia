import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_product_service.dart';
import '../../theme/app_theme.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String selectedStatus = 'all';
  String selectedCategory = 'all';
  bool isLoading = false;

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
          'Gestão de Produtos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilters(),
          
          // Lista de produtos
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Filtro por status
          Row(
            children: [
              const Text('Status: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedStatus,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todos')),
                  const DropdownMenuItem(value: 'active', child: Text('Ativos')),
                  const DropdownMenuItem(value: 'pending', child: Text('Pendentes')),
                  const DropdownMenuItem(value: 'inactive', child: Text('Inativos')),
                  const DropdownMenuItem(value: 'rejected', child: Text('Rejeitados')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(width: 16),
              
              // Filtro por categoria
              const Text('Categoria: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedCategory,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todas')),
                  const DropdownMenuItem(value: 'electronics', child: Text('Eletrônicos')),
                  const DropdownMenuItem(value: 'clothing', child: Text('Roupas')),
                  const DropdownMenuItem(value: 'home', child: Text('Casa')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Estatísticas rápidas
          Row(
            children: [
              _buildQuickStat('Total', '156', Colors.blue),
              const SizedBox(width: 16),
              _buildQuickStat('Ativos', '89', Colors.green),
              const SizedBox(width: 16),
              _buildQuickStat('Pendentes', '23', Colors.orange),
              const SizedBox(width: 16),
              _buildQuickStat('Rejeitados', '8', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final productService = context.read<FirebaseProductService>();
    
    return StreamBuilder<QuerySnapshot>(
      stream: productService.getProductsStream(
        isActive: selectedStatus == 'all' ? null : selectedStatus == 'active',
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data?.docs ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text('Nenhum produto encontrado'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final productId = products[index].id;

            return _buildProductCard(product, productId);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String productId) {
    final status = product['status'] ?? 'pending';
    final isActive = product['isActive'] ?? false;
    final isFeatured = product['isFeatured'] ?? false;
    final isOnSale = product['isOnSale'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagem do produto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['mainImage'] != null
                  ? Image.network(
                      product['mainImage'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Informações do produto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Sem nome',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${(product['price'] ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusChip(status),
                      if (isFeatured) _buildFeatureChip('Destaque'),
                      if (isOnSale) _buildFeatureChip('Oferta'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estoque: ${product['stockQuantity'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Ações
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editProduct(productId, product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteProduct(productId),
                ),
                if (status == 'pending')
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveProduct(productId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Ativo';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pendente';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Inativo';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejeitado';
        break;
      default:
        color = Colors.grey;
        label = 'Desconhecido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Produto'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editProduct(String productId, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Produto'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar exclusão
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produto excluído com sucesso'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _approveProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar Produto'),
        content: const Text('Tem certeza que deseja aprovar este produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final productService = context.read<FirebaseProductService>();
                await productService.approveProduct(productId);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produto aprovado com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao aprovar produto: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
  }
} 