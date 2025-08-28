import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'screens/client_login_screen.dart';
import 'screens/products_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/offers_screen.dart';
import 'screens/coupons_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/our_history_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_use_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/address_management_screen.dart';
import 'screens/product_detail_page.dart';
import 'screens/sexyshop_screen.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'models/product_model.dart';
import 'services/firebase_product_service.dart';
import 'providers/location_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/address_provider.dart';
import 'providers/profit_margin_provider.dart';
import 'providers/screen_state_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Remover hash routing - usar URLs limpas
  setUrlStrategy(PathUrlStrategy());
  
  // Inicializar Firebase apenas se não estiver inicializado
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase já foi inicializado, continuar
    print('Firebase já inicializado: $e');
  }
  
  runApp(const MercadoDaSophiaApp());
}

class MercadoDaSophiaApp extends StatelessWidget {
  const MercadoDaSophiaApp({super.key});

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: [
        // Rota raiz - redireciona para produtos
        GoRoute(
          path: '/',
          redirect: (context, state) => '/produtos',
        ),
        
        // Loja principal
        GoRoute(
          path: '/produtos',
          name: 'products',
          builder: (context, state) => const ProductsScreen(),
        ),
        
        GoRoute(
          path: '/loja',
          redirect: (context, state) => '/produtos',
        ),
        
        // SexyShop
        GoRoute(
          path: '/sexyshop',
          name: 'sexyshop',
          builder: (context, state) => const SexyShopScreen(),
        ),
        
        GoRoute(
          path: '/fantasias',
          redirect: (context, state) => '/sexyshop',
        ),
        
        GoRoute(
          path: '/lingerie',
          redirect: (context, state) => '/sexyshop',
        ),
        
        // Produtos individuais com parâmetro dinâmico
        GoRoute(
          path: '/produto/:slug',
          name: 'product_detail',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            final productId = _extractProductIdFromSlug(slug);
            
            return FutureBuilder<Product?>(
              future: ProductService.getProductById(productId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                                   return Scaffold(
                   appBar: AppBar(title: const Text('Carregando...')),
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Produto não encontrado'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    body: const Center(
                      child: Text('Produto não encontrado'),
                    ),
                  );
                }
                
                return ProductDetailPage(product: snapshot.data!);
              },
            );
          },
        ),
        
        // Outras rotas
        GoRoute(
          path: '/carrinho',
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        
        GoRoute(
          path: '/checkout',
          name: 'checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        
        GoRoute(
          path: '/minha-conta',
          name: 'my_account',
          builder: (context, state) => const MyAccountScreen(),
        ),
        
        GoRoute(
          path: '/enderecos',
          name: 'address_management',
          builder: (context, state) => const AddressManagementScreen(),
        ),
        
        GoRoute(
          path: '/meus-pedidos',
          name: 'my_orders',
          builder: (context, state) => const MyOrdersScreen(),
        ),
        
        GoRoute(
          path: '/favoritos',
          name: 'favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        
        GoRoute(
          path: '/ofertas',
          name: 'offers',
          builder: (context, state) => const OffersScreen(),
        ),
        
        GoRoute(
          path: '/cupons',
          name: 'coupons',
          builder: (context, state) => const CouponsScreen(),
        ),
        
        GoRoute(
          path: '/sobre-nos',
          name: 'about_us',
          builder: (context, state) => const AboutUsScreen(),
        ),
        
        GoRoute(
          path: '/nossa-historia',
          name: 'our_history',
          builder: (context, state) => const OurHistoryScreen(),
        ),
        
        GoRoute(
          path: '/politica-privacidade',
          name: 'privacy_policy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        
        GoRoute(
          path: '/termos-uso',
          name: 'terms_of_use',
          builder: (context, state) => const TermsOfUseScreen(),
        ),
        
        GoRoute(
          path: '/contato',
          name: 'contact',
          builder: (context, state) => const ContactScreen(),
        ),
        
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const ClientLoginScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Página não encontrada')),
        body: const Center(
          child: Text('404 - Página não encontrada'),
        ),
      ),
    );
  }
  
  // Extrair ID do produto do slug
  String _extractProductIdFromSlug(String slug) {
    final parts = slug.split('-');
    if (parts.isNotEmpty) {
      return parts.last;
    }
    return slug;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<AddressProvider>(
          create: (_) => AddressProvider(),
        ),
        ChangeNotifierProvider<ProfitMarginProvider>(
          create: (_) => ProfitMarginProvider(),
        ),
        ChangeNotifierProvider<ScreenStateProvider>(
          create: (_) => ScreenStateProvider(),
        ),
        Provider<FirebaseProductService>(
          create: (_) => FirebaseProductService(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Mercado da Sophia',
        theme: AppTheme.lightTheme,
        routerConfig: _createRouter(),
      ),
    );
  }
}
