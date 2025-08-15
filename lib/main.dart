import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
import 'services/auth_service.dart';
import 'services/firebase_product_service.dart';
import 'providers/location_provider.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        Provider<FirebaseProductService>(
          create: (_) => FirebaseProductService(),
        ),
      ],
      child: MaterialApp(
        title: 'Mercado da Sophia',
        theme: AppTheme.lightTheme,
        initialRoute: '/login', // Voltar para login
        routes: {
          '/login': (context) => const ClientLoginScreen(),
          '/products': (context) => const ProductsScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/my_orders': (context) => const MyOrdersScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/offers': (context) => const OffersScreen(),
          '/coupons': (context) => const CouponsScreen(),
          '/my_account': (context) => const MyAccountScreen(),
          '/about_us': (context) => const AboutUsScreen(),
          '/our_history': (context) => const OurHistoryScreen(),
          '/privacy_policy': (context) => const PrivacyPolicyScreen(),
          '/terms_of_use': (context) => const TermsOfUseScreen(),
          '/contact': (context) => const ContactScreen(),
          '/address_management': (context) => const AddressManagementScreen(),
          '/product_detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            if (args != null && args['product'] != null) {
              return ProductDetailPage(product: args['product']);
            }
            return const Scaffold(
              body: Center(
                child: Text('Erro: Produto não encontrado'),
              ),
            );
          },
        },
      ),
    );
  }
}
