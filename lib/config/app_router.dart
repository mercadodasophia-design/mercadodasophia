import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/products_screen.dart';
import '../screens/sexyshop_screen.dart';
import '../screens/product_detail_page.dart';
import '../screens/cart_screen.dart';
import '../screens/my_account_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/offers_screen.dart';
import '../screens/coupons_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/our_history_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/client_login_screen.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirectLimit: 10,
    // Configuração específica para web
    restorationScopeId: 'app',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: const Center(
        child: Text('404 - Página não encontrada'),
      ),
    ),
    routes: [
      // Rota raiz - redireciona para produtos
      GoRoute(
        path: '/',
        redirect: (context, state) {
          print('Redirecting from / to /produtos');
          return '/produtos';
        },
      ),
      
      // Loja principal
      GoRoute(
        path: '/produtos',
        name: 'products',
        builder: (context, state) {
          print('Building ProductsScreen for path: ${state.path}');
          return const ProductsScreen();
        },
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
      
      // Produtos individuais
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
      
      // Categorias
      GoRoute(
        path: '/categoria/:category',
        name: 'category',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return ProductsScreen(initialCategory: category);
        },
      ),
      
      // Busca
      GoRoute(
        path: '/busca/:query',
        name: 'search',
        builder: (context, state) {
          final query = state.pathParameters['query']!;
          return ProductsScreen(initialSearch: query);
        },
      ),
      
      // Outras rotas
      GoRoute(
        path: '/carrinho',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      
      GoRoute(
        path: '/minha-conta',
        name: 'my_account',
        builder: (context, state) => const MyAccountScreen(),
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
  );
  
  // Extrair ID do produto do slug
  static String _extractProductIdFromSlug(String slug) {
    final parts = slug.split('-');
    if (parts.isNotEmpty) {
      return parts.last;
    }
    return slug;
  }
}
