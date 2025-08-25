

class UrlHelper {
  // Converter título para slug amigável
  static String createSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove caracteres especiais
        .replaceAll(RegExp(r'[-\s]+'), '-') // Substitui espaços e hífens múltiplos por um só
        .trim()
        .replaceAll(RegExp(r'^-+|-+$'), ''); // Remove hífens no início e fim
  }

  // Criar URL amigável para produto
  static String createProductUrl(String productId, String productTitle) {
    final slug = createSlug(productTitle);
    return '/produto/$slug-$productId';
  }

  // Extrair ID do produto da URL
  static String? extractProductIdFromUrl(String url) {
    final regex = RegExp(r'/produto/.*?-([a-zA-Z0-9]+)$');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  // Criar URL amigável para categoria
  static String createCategoryUrl(String category) {
    final slug = createSlug(category);
    return '/categoria/$slug';
  }

  // Extrair categoria da URL
  static String? extractCategoryFromUrl(String url) {
    final regex = RegExp(r'/categoria/(.+)$');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  // Criar URL amigável para busca
  static String createSearchUrl(String query) {
    final encodedQuery = Uri.encodeComponent(query);
    return '/busca/$encodedQuery';
  }

  // Extrair query de busca da URL
  static String? extractSearchQueryFromUrl(String url) {
    final regex = RegExp(r'/busca/(.+)$');
    final match = regex.firstMatch(url);
    if (match != null) {
      return Uri.decodeComponent(match.group(1)!);
    }
    return null;
  }

  // Mapear URLs amigáveis para rotas internas
  static Map<String, String> getUrlMappings() {
    return {
      '/': '/products',
      '/loja': '/products',
      '/produtos': '/products',
      '/carrinho': '/cart',
      '/minha-conta': '/my_account',
      '/meus-pedidos': '/my_orders',
      '/favoritos': '/favorites',
      '/ofertas': '/offers',
      '/cupons': '/coupons',
      '/sobre-nos': '/about_us',
      '/nossa-historia': '/our_history',
      '/politica-privacidade': '/privacy_policy',
      '/termos-uso': '/terms_of_use',
      '/contato': '/contact',
      '/sexyshop': '/sexyshop',
      '/fantasias': '/sexyshop',
      '/lingerie': '/sexyshop',
    };
  }

  // Converter URL amigável para rota interna
  static String? getInternalRoute(String url) {
    final mappings = getUrlMappings();
    
    // Verificar mapeamentos diretos
    if (mappings.containsKey(url)) {
      return mappings[url];
    }

    // Verificar URLs de produto
    if (url.startsWith('/produto/')) {
      return '/product_detail';
    }

    // Verificar URLs de categoria
    if (url.startsWith('/categoria/')) {
      return '/products';
    }

    // Verificar URLs de busca
    if (url.startsWith('/busca/')) {
      return '/products';
    }

    return null;
  }

  // Criar argumentos para rota baseado na URL
  static Map<String, dynamic>? getRouteArguments(String url) {
    // Para produtos
    if (url.startsWith('/produto/')) {
      final productId = extractProductIdFromUrl(url);
      if (productId != null) {
        return {'productId': productId, 'url': url};
      }
    }

    // Para categorias
    if (url.startsWith('/categoria/')) {
      final category = extractCategoryFromUrl(url);
      if (category != null) {
        return {'category': category, 'url': url};
      }
    }

    // Para busca
    if (url.startsWith('/busca/')) {
      final query = extractSearchQueryFromUrl(url);
      if (query != null) {
        return {'searchQuery': query, 'url': url};
      }
    }

    return null;
  }
}
