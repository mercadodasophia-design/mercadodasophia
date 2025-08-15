import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_products_screen.dart';
import 'screens/admin/admin_authorizations_screen.dart';
import 'screens/admin/admin_aliexpress_search_screen.dart';
import 'screens/admin/admin_imported_products_screen.dart';
import 'screens/admin/admin_manage_products_screen.dart';
import 'screens/admin/admin_product_edit_screen.dart';
import 'screens/admin/admin_categories_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_sync_settings_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_product_service.dart';
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
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/admin_products': (context) => const AdminProductsScreen(),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Removida verificação de login - vai direto para o dashboard
    return const AdminDashboardScreen();
  }
} 