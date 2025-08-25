import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  Map<String, dynamic>? userData;
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      try {
        final data = await authService.getUserData(user.uid);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
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
          'Minha Conta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
                         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/produtos'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header com informações do usuário
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Avatar e informações básicas
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                                                  child: _getUserAvatar(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getUserName(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getUserEmail(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getUserRole(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _editProfile,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Estatísticas rápidas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Pedidos', '12', Icons.shopping_bag),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Favoritos', '8', Icons.favorite),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Cupons', '5', Icons.card_giftcard),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Seções de opções
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Informações Pessoais
                  _buildSection(
                    'Informações Pessoais',
                    Icons.person,
                    [
                      _buildUserInfoTile('Nome', _getUserName(), Icons.person),
                      _buildUserInfoTile('Email', _getUserEmail(), Icons.email),
                      if (userData != null && userData!['phone'] != null)
                        _buildUserInfoTile('Telefone', userData!['phone'], Icons.phone),
                      _buildUserInfoTile('Tipo de Conta', _getUserRole(), Icons.badge),
                      if (userData != null && userData!['createdAt'] != null)
                        _buildUserInfoTile('Membro desde', _formatDate(userData!['createdAt']), Icons.calendar_today),
                      _buildOptionTile('Editar Perfil', Icons.edit, _editProfile),
                      _buildOptionTile('Endereços', Icons.location_on, _manageAddresses),
                      _buildOptionTile('Telefones', Icons.phone, _managePhones),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Pedidos e Compras
                  _buildSection(
                    'Pedidos e Compras',
                    Icons.shopping_bag,
                    [
                      _buildOptionTile('Histórico de Pedidos', Icons.history, _orderHistory),
                      _buildOptionTile('Rastrear Pedido', Icons.local_shipping, _trackOrder),
                      _buildOptionTile('Devoluções', Icons.assignment_return, _returns),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Configurações
                  _buildSection(
                    'Configurações',
                    Icons.settings,
                    [
                      _buildOptionTile('Notificações', Icons.notifications, _notifications),
                      _buildOptionTile('Privacidade', Icons.privacy_tip, _privacy),
                      _buildOptionTile('Segurança', Icons.security, _security),
                      _buildOptionTile('Idioma', Icons.language, _language),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Suporte
                  _buildSection(
                    'Suporte',
                    Icons.help,
                    [
                      _buildOptionTile('Central de Ajuda', Icons.help_center, _helpCenter),
                      _buildOptionTile('Fale Conosco', Icons.contact_support, _contactUs),
                      _buildOptionTile('Sobre o App', Icons.info, _aboutApp),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botão Sair
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da Conta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                          children: [
                            _buildFooterCategory('Garrafeira'),
                            _buildFooterCategory('Compotas e Mel'),
                            _buildFooterCategory('Doces'),
                            _buildFooterCategory('Chás e Refrescos'),
                            _buildFooterCategory('Queijos e Pão'),
                          ],
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
    );
  }

  // Métodos auxiliares para obter dados do usuário
  Widget _getUserAvatar() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user?.photoURL != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(37),
        child: Image.network(
          user!.photoURL!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 40,
              color: Colors.grey,
            );
          },
        ),
      );
    } else {
      return const Icon(
        Icons.person,
        size: 40,
        color: Colors.grey,
      );
    }
  }

  String _getUserName() {
    if (isLoading) return 'Carregando...';
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    // Prioridade: dados do Firestore > displayName do Firebase > email
    if (userData != null && userData!['name'] != null) {
      return userData!['name'];
    } else if (user?.displayName != null) {
      return user!.displayName!;
    } else if (user?.email != null) {
      return user!.email!.split('@')[0]; // Primeira parte do email
    } else {
      return 'Usuário';
    }
  }

  String _getUserEmail() {
    if (isLoading) return 'Carregando...';
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    return user?.email ?? 'Email não disponível';
  }

  String _getUserRole() {
    if (isLoading) return 'Carregando...';
    
    if (userData != null && userData!['role'] != null) {
      switch (userData!['role']) {
        case 'admin':
          return 'Administrador';
        case 'manager':
          return 'Gerente';
        case 'customer':
        default:
          return 'Cliente';
      }
    }
    
    return 'Cliente';
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildUserInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Data não disponível';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      return 'Data não disponível';
    } catch (e) {
      return 'Data não disponível';
    }
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Editar perfil em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _manageAddresses() {
    context.go('/enderecos');
  }

  void _managePhones() {
    _showPhoneEditor();
  }

  void _showPhoneEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneEditorSheet(),
    );
  }

  void _orderHistory() {
    context.go('/meus-pedidos');
  }

  void _trackOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rastrear pedido em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _returns() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Devoluções em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _notifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurar notificações em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _privacy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de privacidade em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _security() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de segurança em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _language() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurar idioma em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _helpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Central de ajuda em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _contactUs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fale conosco em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _aboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mercado da Sophia'),
            SizedBox(height: 8),
            Text('Versão: 1.0.0'),
            Text('Desenvolvido com Flutter'),
            SizedBox(height: 8),
            Text('© 2024 Mercado da Sophia'),
          ],
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

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
                             try {
                 final authService = Provider.of<AuthService>(context, listen: false);
                 await authService.signOut();
                 context.go('/produtos');
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Logout realizado com sucesso!'),
                     backgroundColor: Colors.green,
                   ),
                 );
               } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao fazer logout: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCategory(String label) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        // Navegar para produtos com categoria selecionada
        context.go('/produtos');
      },
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
}

class PhoneEditorSheet extends StatefulWidget {
  const PhoneEditorSheet({super.key});

  @override
  State<PhoneEditorSheet> createState() => _PhoneEditorSheetState();
}

class _PhoneEditorSheetState extends State<PhoneEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingPhoneId;
  List<Map<String, dynamic>> _phones = [];
  String _selectedType = 'Celular';

  final List<String> _phoneTypes = ['Celular', 'Residencial', 'Trabalho', 'WhatsApp'];

  @override
  void initState() {
    super.initState();
    _loadPhones();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPhones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = doc.data();
        if (userData != null && userData['phones'] != null) {
          setState(() {
            _phones = List<Map<String, dynamic>>.from(userData['phones']);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar telefones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startEditing(Map<String, dynamic> phone) {
    setState(() {
      _isEditing = true;
      _editingPhoneId = phone['id'];
      _phoneController.text = phone['number'] ?? '';
      _descriptionController.text = phone['description'] ?? '';
      _selectedType = phone['type'] ?? 'Celular';
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingPhoneId = null;
      _phoneController.clear();
      _descriptionController.clear();
      _selectedType = 'Celular';
    });
  }

  Future<void> _savePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final phoneData = {
          'id': _isEditing ? _editingPhoneId : DateTime.now().millisecondsSinceEpoch.toString(),
          'number': _phoneController.text,
          'type': _selectedType,
          'description': _descriptionController.text,
          'isDefault': _phones.isEmpty, // Primeiro telefone é padrão
          'createdAt': DateTime.now().toIso8601String(),
        };

        List<Map<String, dynamic>> updatedPhones;
        
        if (_isEditing) {
          // Atualizar telefone existente
          updatedPhones = _phones.map((phone) {
            if (phone['id'] == _editingPhoneId) {
              return phoneData;
            }
            return phone;
          }).toList();
        } else {
          // Adicionar novo telefone
          updatedPhones = [..._phones, phoneData];
        }
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'phones': updatedPhones,
        });

        setState(() {
          _phones = updatedPhones;
        });

        _cancelEditing();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Telefone atualizado!' : 'Telefone salvo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar telefone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhone(Map<String, dynamic> phone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Telefone'),
        content: const Text('Tem certeza que deseja excluir este telefone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final updatedPhones = _phones.where((p) => p['id'] != phone['id']).toList();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'phones': updatedPhones,
        });

        setState(() {
          _phones = updatedPhones;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefone excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir telefone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPhoneNumber(String number) {
    // Formatar número de telefone brasileiro
    final clean = number.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 11) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7)}';
    } else if (clean.length == 10) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}';
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'Gerenciar Telefones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Para centralizar o título
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Formulário
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? 'Editar Telefone' : 'Adicionar Telefone',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Tipo de telefone
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                  border: OutlineInputBorder(),
                                ),
                                items: _phoneTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Número
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Número',
                                  hintText: '(85) 99764-0050',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o número';
                                  }
                                  final clean = value.replaceAll(RegExp(r'[^\d]'), '');
                                  if (clean.length < 10 || clean.length > 11) {
                                    return 'Número inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Descrição (opcional)
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Descrição (opcional)',
                                  hintText: 'Ex: Principal, Emergência',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Botões
                              Row(
                                children: [
                                  if (_isEditing)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _cancelEditing,
                                        child: const Text('Cancelar'),
                                      ),
                                    ),
                                  if (_isEditing) const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _savePhone,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                      child: Text(
                                        _isEditing ? 'Atualizar' : 'Salvar',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Lista de telefones
                      Expanded(
                        child: _phones.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_disabled,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nenhum telefone cadastrado',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _phones.length,
                                itemBuilder: (context, index) {
                                  final phone = _phones[index];
                                  final isDefault = phone['isDefault'] == true;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor,
                                        child: Icon(
                                          _getPhoneIcon(phone['type']),
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        _formatPhoneNumber(phone['number']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(phone['type'] ?? ''),
                                          if (phone['description']?.isNotEmpty == true)
                                            Text(
                                              phone['description'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          if (isDefault)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Principal',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _startEditing(phone),
                                            tooltip: 'Editar',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deletePhone(phone),
                                            tooltip: 'Excluir',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getPhoneIcon(String? type) {
    switch (type) {
      case 'Celular':
        return Icons.phone_android;
      case 'WhatsApp':
        return Icons.message;
      case 'Trabalho':
        return Icons.work;
      case 'Residencial':
        return Icons.home;
      default:
        return Icons.phone;
    }
  }
}