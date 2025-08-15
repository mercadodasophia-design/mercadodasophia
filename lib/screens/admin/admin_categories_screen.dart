import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_product_service.dart';
import '../../theme/app_theme.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
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
          'Gestão de Categorias',
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
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas
          _buildStats(),
          
          // Lista de categorias
          Expanded(
            child: _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatCard('Total', '12', Colors.blue),
          const SizedBox(width: 16),
          _buildStatCard('Ativas', '10', Colors.green),
          const SizedBox(width: 16),
          _buildStatCard('Em Destaque', '5', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
                fontSize: 20,
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

  Widget _buildCategoriesList() {
    final productService = context.read<FirebaseProductService>();
    
    return StreamBuilder<QuerySnapshot>(
      stream: productService.getCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data?.docs ?? [];

        if (categories.isEmpty) {
          return const Center(
            child: Text('Nenhuma categoria encontrada'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index].data() as Map<String, dynamic>;
            final categoryId = categories[index].id;

            return _buildCategoryCard(category, categoryId);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, String categoryId) {
    final name = category['name'] ?? 'Sem nome';
    final description = category['description'] ?? '';
    final isActive = category['isActive'] ?? false;
    final isFeatured = category['isFeatured'] ?? false;
    final productCount = category['productCount'] ?? 0;
    final color = category['color'] ?? '#007bff';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(int.parse(color.replaceAll('#', '0xFF'))),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.category,
            color: Colors.white,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '$productCount produtos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'Ativa',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isFeatured) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'Destaque',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(Icons.toggle_on),
                  SizedBox(width: 8),
                  Text('Ativar/Desativar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editCategory(categoryId, category);
                break;
              case 'toggle':
                _toggleCategory(categoryId, isActive);
                break;
              case 'delete':
                _deleteCategory(categoryId);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = '#007bff';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Categoria',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedColor,
              decoration: const InputDecoration(
                labelText: 'Cor',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: '#007bff', child: Text('Azul')),
                DropdownMenuItem(value: '#28a745', child: Text('Verde')),
                DropdownMenuItem(value: '#dc3545', child: Text('Vermelho')),
                DropdownMenuItem(value: '#ffc107', child: Text('Amarelo')),
                DropdownMenuItem(value: '#6f42c1', child: Text('Roxo')),
              ],
              onChanged: (value) {
                selectedColor = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nome da categoria é obrigatório'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final productService = context.read<FirebaseProductService>();
                await productService.createCategory({
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'color': selectedColor,
                  'isActive': true,
                  'isFeatured': false,
                  'sortOrder': 0,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoria criada com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar categoria: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _editCategory(String categoryId, Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoria'),
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

  void _toggleCategory(String categoryId, bool isActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Desativar Categoria' : 'Ativar Categoria'),
        content: Text(
          isActive
              ? 'Tem certeza que deseja desativar esta categoria?'
              : 'Tem certeza que deseja ativar esta categoria?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final productService = context.read<FirebaseProductService>();
                await productService.updateCategory(categoryId, {
                  'isActive': !isActive,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive
                          ? 'Categoria desativada com sucesso'
                          : 'Categoria ativada com sucesso',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao atualizar categoria: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isActive ? 'Desativar' : 'Ativar'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir esta categoria? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final productService = context.read<FirebaseProductService>();
                await productService.deleteCategory(categoryId);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoria excluída com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir categoria: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
} 