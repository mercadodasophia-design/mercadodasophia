import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../services/aliexpress_auth_service.dart';
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoadingAuth = false;
  Map<String, dynamic>? _authStatus;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoadingAuth = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://service-api-aliexpress.mercadodasophia.com.br/api/aliexpress/tokens/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _authStatus = data;
          _isLoadingAuth = false;
        });
      } else {
        setState(() {
          _authStatus = {'has_tokens': false};
          _isLoadingAuth = false;
        });
      }
    } catch (e) {
      setState(() {
        _authStatus = {'has_tokens': false};
        _isLoadingAuth = false;
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Painel Administrativo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com boas-vindas
            _buildWelcomeHeader(),
            
            const SizedBox(height: 24),
            
            // Cards de estatísticas
            _buildStatsCards(),
            
            const SizedBox(height: 24),
            
            // Menu de ações rápidas
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // Seção de funcionalidades
            _buildFeaturesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
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
                      color: Colors.blue,
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
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
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
                  icon: Icons.rss_feed,
                  title: 'Feed',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/feeds');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.language,
                  title: 'AliExpress DS',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/aliexpress-ds');
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
                  icon: Icons.add_box,
                  title: 'Adicionar Produto',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/add-product');
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
                  icon: Icons.shopping_bag,
                  title: 'Gestão de Pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/orders');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info,
                  title: 'Status dos Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/product-status');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categorias',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/categories');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.image,
                  title: 'Banner Loja',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/banners-loja');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  title: 'Banner SexyShop',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/banners-sexyshop');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_photo_alternate,
                  title: 'Adicionar Banner',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/add-banner');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Usuários',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/users');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.security,
                  title: 'Autorizações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/authorizations');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  title: 'Mensagens de Contato',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/contact-messages');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.attach_money,
                  title: 'Financeiro',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/financial');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Configurações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/settings');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Relatórios',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/reports');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.backup,
                  title: 'Backup',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/backup');
                  },
                ),
              ],
            ),
          ),
          
          // Footer do drawer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sair',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/');
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
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: onTap,
    );
  }

  Widget _buildWelcomeHeader() {
    final hasValidToken = _authStatus?['has_tokens'] ?? false;
    final account = _authStatus?['account'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo ao Painel Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gerencie produtos, importações e configurações do Mercado da Sophia',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Status de Autorização
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (_isLoadingAuth)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    hasValidToken ? Icons.check_circle : Icons.error,
                    color: hasValidToken ? Colors.green.shade300 : Colors.red.shade300,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status AliExpress',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoadingAuth 
                          ? 'Verificando...'
                          : hasValidToken 
                            ? 'Autorizado' + (account != null ? ' ($account)' : '')
                            : 'Não autorizado',
                        style: TextStyle(
                          color: hasValidToken ? Colors.green.shade300 : Colors.red.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoadingAuth) ...[
                  if (!hasValidToken)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin/authorizations');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Autorizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (hasValidToken)
                    IconButton(
                      onPressed: _checkAuthStatus,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 16,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildStatCard('Total de Produtos', '0', Icons.inventory, Colors.blue),
        _buildStatCard('Produtos Ativos', '0', Icons.check_circle, Colors.green),
        _buildStatCard('Em Destaque', '0', Icons.star, Colors.orange),
        _buildStatCard('Pendentes', '0', Icons.pending, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildActionCard(
              'Buscar AliExpress',
              Icons.search,
              Colors.red,
              () => Navigator.pushNamed(context, '/admin/aliexpress'),
            ),
            _buildActionCard(
              'Importar Produtos',
              Icons.download,
              Colors.blue,
              () => Navigator.pushNamed(context, '/admin/import'),
            ),
            _buildActionCard(
              'Gerenciar Produtos',
              Icons.inventory,
              Colors.green,
              () => Navigator.pushNamed(context, '/admin_products'),
            ),
            _buildActionCard(
              'Categorias',
              Icons.category,
              Colors.orange,
              () => Navigator.pushNamed(context, '/admin/categories'),
            ),
            _buildActionCard(
              'Feed (AliExpress)',
              Icons.rss_feed,
              Colors.purple,
              () => Navigator.pushNamed(context, '/admin/feeds'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Funcionalidades',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFeatureItem('🔍 Busca e Importação AliExpress', 'Importe produtos diretamente do AliExpress'),
              _buildFeatureItem('📦 Gestão de Produtos', 'Gerencie catálogo, preços e estoque'),
              _buildFeatureItem('🏷️ Categorização', 'Organize produtos por categorias'),
              _buildFeatureItem('👥 Gestão de Usuários', 'Controle acesso e permissões'),
              _buildFeatureItem('⚙️ Configurações', 'Personalize o sistema'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔐 Sair do Sistema'),
          content: const Text('Tem certeza que deseja sair? Você será redirecionado para a tela de login.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    Navigator.of(context).pushReplacementNamed('/admin_login');
  }
} 