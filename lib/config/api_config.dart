class ApiConfig {
  // URLs das APIs
  static const String baseUrl = 'https://mercadodasophia-api.onrender.com'; // Servidor no Render
  
  // Endpoints
  static const String shippingQuote = '/shipping/quote'; // Python backend com AliExpress real
  static const String aliexpressProduct = '/api/aliexpress/product';
  static const String aliexpressFreight = '/api/aliexpress/freight';
  static const String aliexpressSearch = '/api/aliexpress/search';
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 15);
  
  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Método para obter URL completa
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
