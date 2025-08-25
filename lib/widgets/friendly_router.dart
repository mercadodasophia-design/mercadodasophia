import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/url_helper.dart';
import '../models/product_model.dart';

class FriendlyRouter extends StatelessWidget {
  final Widget child;
  final Map<String, WidgetBuilder> routes;

  const FriendlyRouter({
    super.key,
    required this.child,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mercado da Sophia',
      routerDelegate: FriendlyRouterDelegate(
        routes: routes,
      ),
      routeInformationParser: FriendlyRouteInformationParser(),
      builder: (context, child) {
        return this.child;
      },
    );
  }
}

class FriendlyRouterDelegate extends RouterDelegate<RouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteConfiguration> {
  final Map<String, WidgetBuilder> routes;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  FriendlyRouterDelegate({required this.routes});

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: const ValueKey('home'),
          child: _buildPage(context, '/products'),
        ),
      ],
    );
  }

  Widget _buildPage(BuildContext context, String route) {
    final builder = routes[route];
    if (builder != null) {
      return builder(context);
    }
    
    // Fallback para página não encontrada
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: const Center(
        child: Text('404 - Página não encontrada'),
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(RouteConfiguration configuration) async {
    // Implementar navegação baseada na configuração
  }
}

class FriendlyRouteInformationParser extends RouteInformationParser<RouteConfiguration> {
  @override
  Future<RouteConfiguration> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    final path = uri.path;
    
    // Obter rota interna
    final internalRoute = UrlHelper.getInternalRoute(path);
    final arguments = UrlHelper.getRouteArguments(path);
    
    return RouteConfiguration(
      route: internalRoute ?? '/products',
      arguments: arguments,
    );
  }

  @override
  RouteInformation? restoreRouteInformation(RouteConfiguration configuration) {
    return RouteInformation(uri: Uri.parse(configuration.route));
  }
}

class RouteConfiguration {
  final String route;
  final Map<String, dynamic>? arguments;

  RouteConfiguration({
    required this.route,
    this.arguments,
  });
}

// Widget para navegação com URLs amigáveis
class FriendlyNavigator {
  static Future<void> pushNamed(
    BuildContext context,
    String route, {
    Map<String, dynamic>? arguments,
  }) async {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  static Future<void> pushReplacementNamed(
    BuildContext context,
    String route, {
    Map<String, dynamic>? arguments,
  }) async {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  static Future<void> pushNamedAndRemoveUntil(
    BuildContext context,
    String route,
    RoutePredicate predicate, {
    Map<String, dynamic>? arguments,
  }) async {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      predicate,
      arguments: arguments,
    );
  }

  // Navegar para produto com URL amigável
  static Future<void> pushProduct(
    BuildContext context,
    Product product,
  ) async {
    final url = UrlHelper.createProductUrl(product.id ?? 'unknown', product.titulo);
    
    // Usar go_router para navegação com URL amigável
    context.go(url);
  }

  // Navegar para categoria com URL amigável
  static Future<void> pushCategory(
    BuildContext context,
    String category,
  ) async {
    final url = UrlHelper.createCategoryUrl(category);
    
    // Usar go_router para navegação com URL amigável
    context.go(url);
  }

  // Navegar para busca com URL amigável
  static Future<void> pushSearch(
    BuildContext context,
    String query,
  ) async {
    final url = UrlHelper.createSearchUrl(query);
    
    // Usar go_router para navegação com URL amigável
    context.go(url);
  }
}
