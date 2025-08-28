import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_authorizations_screen.dart';
import 'screens/admin/admin_aliexpress_search_screen.dart';
import 'screens/admin/admin_imported_products_screen.dart';
import 'screens/admin/admin_manage_products_screen.dart';
import 'screens/admin/admin_product_edit_screen.dart';
import 'screens/admin/admin_categories_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_sync_settings_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_aliexpress_login_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_feed_test_screen.dart';
import 'screens/admin/admin_feeds_screen.dart';
import 'screens/admin/admin_add_product_screen.dart';
import 'screens/admin/admin_banners_screen.dart';
import 'screens/admin/admin_banners_loja_screen.dart';
import 'screens/admin/admin_banners_sexyshop_screen.dart';
import 'screens/admin/admin_add_banner_screen.dart';
import 'screens/admin/admin_contact_messages_screen.dart';
import 'screens/admin/admin_financial_screen.dart';
import 'screens/admin/admin_aliexpress_ds_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_product_service.dart';
import 'services/aliexpress_auth_service.dart';
import 'services/admin_auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MercadoDaSophiaAdminApp());
}

class MercadoDaSophiaAdminApp extends StatelessWidget {
  const MercadoDaSophiaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<AliExpressAuthService>(
          create: (_) => AliExpressAuthService(),
        ),
        Provider<FirebaseProductService>(
          create: (_) => FirebaseProductService(),
        ),
      ],
      child: MaterialApp(
        title: 'Mercado da Sophia - Admin',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/admin_login': (context) => const AdminLoginScreen(),
          '/admin_aliexpress_login': (context) => const AdminAliExpressLoginScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/admin_products': (context) => const AdminManageProductsScreen(),
          '/admin/authorizations': (context) => const AdminAuthorizationsScreen(),
          '/admin/aliexpress': (context) => const AdminAliExpressSearchScreen(),
          '/admin/imported-products': (context) => const AdminImportedProductsScreen(),
          '/admin/manage-products': (context) => const AdminManageProductsScreen(),
          '/admin/product-edit': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return AdminProductEditScreen(product: args);
            }
            return const Scaffold(
              body: Center(
                child: Text('Erro: Produto não encontrado'),
              ),
            );
          },
          '/admin/categories': (context) => const AdminCategoriesScreen(),
          '/admin/users': (context) => const AdminUsersScreen(),
          '/admin/settings': (context) => const AdminSyncSettingsScreen(),
          '/admin/orders': (context) => const AdminOrdersScreen(),
          '/admin/feed-test': (context) => const AdminFeedTestScreen(),
          '/admin/feeds': (context) => const AdminFeedsScreen(),
          '/admin/add-product': (context) => const AdminAddProductScreen(),
          '/admin/banners': (context) => const AdminBannersScreen(),
          '/admin/banners-loja': (context) => const AdminBannersLojaScreen(),
          '/admin/banners-sexyshop': (context) => const AdminBannersSexyShopScreen(),
          '/admin/add-banner': (context) => const AdminAddBannerScreen(),
          '/admin/contact-messages': (context) => const AdminContactMessagesScreen(),
          '/admin/financial': (context) => const AdminFinancialScreen(),
          '/admin/aliexpress-ds': (context) => const AdminAliExpressDSScreen(),
          // Rotas temporárias para funcionalidades não implementadas
          '/admin/reports': (context) => _buildComingSoonScreen('Relatórios'),
          '/admin/backup': (context) => _buildComingSoonScreen('Backup'),
        },
      ),
    );
  }
  
  Widget _buildComingSoonScreen(String feature) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              '$feature em Desenvolvimento',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta funcionalidade será implementada em breve!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar chamar setState durante o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthorization();
    });
  }

  Future<void> _checkAuthorization() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Verificar se o usuário está autenticado no Firebase
    if (authService.isAuthenticated) {
      // Verificar se tem permissão de admin
      final hasAdminPermission = await AdminAuthService.isAdmin();
      
      if (hasAdminPermission) {
        // Se tem permissão, vai para o dashboard
        Navigator.of(context).pushReplacementNamed('/admin_dashboard');
      } else {
        // Se não tem permissão, vai para a tela de login
        Navigator.of(context).pushReplacementNamed('/admin_login');
      }
    } else {
      // Se não está autenticado, vai para a tela de login
      Navigator.of(context).pushReplacementNamed('/admin_login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando autorização...'),
          ],
        ),
      ),
    );
  }
} 