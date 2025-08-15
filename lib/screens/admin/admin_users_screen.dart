import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_product_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
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
          'Gestão de Usuários',
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
            onPressed: () => _showAddUserDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas
          _buildStats(),
          
          // Lista de usuários
          Expanded(
            child: _buildUsersList(),
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
          _buildStatCard('Total', '156', Colors.blue),
          const SizedBox(width: 16),
          _buildStatCard('Ativos', '142', Colors.green),
          const SizedBox(width: 16),
          _buildStatCard('Admins', '3', Colors.red),
          const SizedBox(width: 16),
          _buildStatCard('Hoje', '8', Colors.orange),
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

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text('Nenhum usuário encontrado'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;

            return _buildUserCard(user, userId);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String userId) {
    final name = user['name'] ?? 'Sem nome';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'customer';
    final isActive = user['isActive'] ?? true;
    final lastLogin = user['lastLogin'] as Timestamp?;
    final createdAt = user['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
            Text(email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleChip(role),
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
                      'Ativo',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'Inativo',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (lastLogin != null)
              Text(
                'Último login: ${_formatDate(lastLogin.toDate())}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
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
              value: 'role',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings),
                  SizedBox(width: 8),
                  Text('Alterar Role'),
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
                _editUser(userId, user);
                break;
              case 'toggle':
                _toggleUser(userId, isActive);
                break;
              case 'role':
                _changeUserRole(userId, role);
                break;
              case 'delete':
                _deleteUser(userId);
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      case 'editor':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRoleChip(String role) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.red;
        label = 'Admin';
        break;
      case 'manager':
        color = Colors.orange;
        label = 'Manager';
        break;
      case 'editor':
        color = Colors.blue;
        label = 'Editor';
        break;
      default:
        color = Colors.grey;
        label = 'Cliente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'customer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'customer', child: Text('Cliente')),
                DropdownMenuItem(value: 'editor', child: Text('Editor')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                selectedRole = value!;
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
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos os campos são obrigatórios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final authService = context.read<FirebaseAuthService>();
                await authService.createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                  name: nameController.text,
                );

                // Atualizar role no Firestore
                final user = authService.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'role': selectedRole});
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuário criado com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar usuário: $e'),
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

  void _editUser(String userId, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Usuário'),
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

  void _toggleUser(String userId, bool isActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Desativar Usuário' : 'Ativar Usuário'),
        content: Text(
          isActive
              ? 'Tem certeza que deseja desativar este usuário?'
              : 'Tem certeza que deseja ativar este usuário?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'isActive': !isActive});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive
                          ? 'Usuário desativado com sucesso'
                          : 'Usuário ativado com sucesso',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao atualizar usuário: $e'),
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

  void _changeUserRole(String userId, String currentRole) {
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Role'),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: const InputDecoration(
            labelText: 'Nova Role',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'customer', child: Text('Cliente')),
            DropdownMenuItem(value: 'editor', child: Text('Editor')),
            DropdownMenuItem(value: 'manager', child: Text('Manager')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (value) {
            selectedRole = value!;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'role': selectedRole});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Role alterada com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao alterar role: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir este usuário? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuário excluído com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir usuário: $e'),
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