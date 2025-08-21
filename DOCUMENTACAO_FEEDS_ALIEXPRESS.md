# 📚 Documentação Técnica - Feeds AliExpress
## Implementação do Feed Direto na Loja

---

## 🎯 **OBJETIVO**
Implementar feed direto do AliExpress na loja principal para exibir produtos sempre atualizados e relevantes, melhorando o engajamento dos usuários.

---

## 🔧 **APIS NECESSÁRIAS**

### **1. aliexpress.ds.feed.name.list.get**
**Função**: Obter lista de feeds disponíveis
**Endpoint**: `/api/aliexpress/feeds/list`

#### **Parâmetros de Entrada**
```json
{
  "method": "aliexpress.ds.feed.name.list.get",
  "app_key": "APP_KEY",
  "timestamp": "TIMESTAMP",
  "sign": "SIGN",
  "sign_method": "md5",
  "format": "json"
}
```

#### **Resposta Esperada**
```json
{
  "success": true,
  "feeds": [
    {
      "feed_name": "top_selling_products",
      "feed_id": "12345",
      "display_name": "Mais Vendidos",
      "description": "Produtos mais populares",
      "product_count": 1000
    },
    {
      "feed_name": "new_arrivals",
      "feed_id": "12346",
      "display_name": "Novidades",
      "description": "Produtos recém-chegados", 
      "product_count": 500
    },
    {
      "feed_name": "trending_products",
      "feed_id": "12347",
      "display_name": "Tendências",
      "description": "Produtos em alta",
      "product_count": 750
    }
  ]
}
```

### **2. aliexpress.ds.feed.items.get**
**Função**: Obter produtos de um feed específico
**Endpoint**: `/api/aliexpress/feeds/{feed_name}/products`

#### **Parâmetros de Entrada**
```json
{
  "method": "aliexpress.ds.feed.items.get",
  "app_key": "APP_KEY",
  "timestamp": "TIMESTAMP",
  "sign": "SIGN",
  "sign_method": "md5",
  "format": "json",
  "feed_name": "top_selling_products",
  "page_size": 20,
  "page_no": 1
}
```

#### **Exemplo Real (Produção)**
Resposta obtida de `/api/aliexpress/feeds/list`:
```json
{
  "success": true,
  "feeds": [
    {
      "feed_name": "DS_Brazil_topsellers",
      "feed_id": "1",
      "display_name": "Mais Vendidos Brasil",
      "description": "Produtos mais vendidos no Brasil",
      "product_count": 14544
    },
    {
      "feed_name": "DS_NewArrivals",
      "feed_id": "2",
      "display_name": "Novidades",
      "description": "Produtos recém-chegados",
      "product_count": 14818
    },
    {
      "feed_name": "DS_ConsumerElectronics_bestsellers",
      "feed_id": "3",
      "display_name": "Eletrônicos",
      "description": "Eletrônicos mais vendidos",
      "product_count": 20633
    },
    {
      "feed_name": "DS_Home&Kitchen_bestsellers",
      "feed_id": "4",
      "display_name": "Casa e Cozinha",
      "description": "Produtos para casa e cozinha",
      "product_count": 12751
    }
  ]
}
```

#### **Resposta Esperada**
```json
{
  "success": true,
  "feed_name": "top_selling_products",
  "products": [
    {
      "item_id": "1005001234567890",
      "product_title": "Smartphone Android 128GB",
      "product_main_image_url": "https://ae01.alicdn.com/...",
      "product_price": "299.90",
      "product_rating": "4.5",
      "product_review_count": 150,
      "product_sales": 500,
      "product_discount": "15%",
      "product_original_price": "349.90"
    }
  ],
  "pagination": {
    "page_no": 1,
    "page_size": 20,
    "total_count": 1000,
    "has_next": true,
    "total_pages": 50
  }
}
```

---

## 🏗️ **IMPLEMENTAÇÃO BACKEND**

### **1. Estrutura de Arquivos**
```
aliexpress-python-api/
├── server.py
├── services/
│   ├── feed_service.py
│   └── aliexpress_api.py
├── models/
│   └── feed_models.py
└── utils/
    └── cache.py
```

### **2. Feed Service (feed_service.py)**
```python
import requests
import json
from typing import Dict, List, Optional
from models.feed_models import Feed, FeedProducts, PaginationInfo
from utils.cache import cache

class FeedService:
    def __init__(self):
        self.base_url = "https://api.aliexpress.com/v2/"
        self.app_key = os.getenv("ALIEXPRESS_APP_KEY")
        self.app_secret = os.getenv("ALIEXPRESS_APP_SECRET")
    
    def get_available_feeds(self) -> Dict:
        """Obter lista de feeds disponíveis"""
        try:
            # Verificar cache primeiro
            cached_feeds = cache.get("available_feeds")
            if cached_feeds:
                return {"success": True, "feeds": cached_feeds}
            
            # Chamar API AliExpress
            params = {
                "method": "aliexpress.ds.feed.name.list.get",
                "app_key": self.app_key,
                "timestamp": self._get_timestamp(),
                "sign": self._generate_sign(),
                "sign_method": "md5",
                "format": "json"
            }
            
            response = requests.get(self.base_url, params=params)
            data = response.json()
            
            if data.get("success"):
                feeds = self._process_feeds_response(data)
                # Cache por 24 horas
                cache.set("available_feeds", feeds, timeout=86400)
                return {"success": True, "feeds": feeds}
            else:
                return {"success": False, "error": data.get("message", "Erro ao obter feeds")}
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_feed_products(self, feed_name: str, page: int = 1, page_size: int = 20) -> Dict:
        """Obter produtos de um feed específico"""
        try:
            # Verificar cache
            cache_key = f"feed_products_{feed_name}_{page}_{page_size}"
            cached_products = cache.get(cache_key)
            if cached_products:
                return {"success": True, **cached_products}
            
            # Chamar API AliExpress
            params = {
                "method": "aliexpress.ds.feed.items.get",
                "app_key": self.app_key,
                "timestamp": self._get_timestamp(),
                "sign": self._generate_sign(),
                "sign_method": "md5",
                "format": "json",
                "feed_name": feed_name,
                "page_size": page_size,
                "page_no": page
            }
            
            response = requests.get(self.base_url, params=params)
            data = response.json()
            
            if data.get("success"):
                products_data = self._process_feed_products_response(data)
                # Cache por 1 hora
                cache.set(cache_key, products_data, timeout=3600)
                return {"success": True, **products_data}
            else:
                return {"success": False, "error": data.get("message", "Erro ao obter produtos")}
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _process_feeds_response(self, data: Dict) -> List[Dict]:
        """Processar resposta da API de feeds"""
        feeds = []
        for feed in data.get("feeds", []):
            feeds.append({
                "feed_name": feed.get("feed_name"),
                "feed_id": feed.get("feed_id"),
                "display_name": feed.get("display_name", feed.get("feed_name")),
                "description": feed.get("description", ""),
                "product_count": feed.get("product_count", 0)
            })
        return feeds
    
    def _process_feed_products_response(self, data: Dict) -> Dict:
        """Processar resposta da API de produtos do feed"""
        products = []
        for product in data.get("products", []):
            products.append({
                "item_id": product.get("item_id"),
                "product_title": product.get("product_title"),
                "product_main_image_url": product.get("product_main_image_url"),
                "product_price": product.get("product_price"),
                "product_rating": product.get("product_rating"),
                "product_review_count": product.get("product_review_count"),
                "product_sales": product.get("product_sales"),
                "product_discount": product.get("product_discount"),
                "product_original_price": product.get("product_original_price")
            })
        
        pagination = data.get("pagination", {})
        return {
            "feed_name": data.get("feed_name"),
            "products": products,
            "pagination": {
                "page_no": pagination.get("page_no", 1),
                "page_size": pagination.get("page_size", 20),
                "total_count": pagination.get("total_count", 0),
                "has_next": pagination.get("has_next", False),
                "total_pages": pagination.get("total_pages", 0)
            }
        }
```

### **3. Endpoints Flask (server.py)**
```python
from flask import Flask, jsonify, request
from services.feed_service import FeedService

app = Flask(__name__)
feed_service = FeedService()

@app.route('/api/aliexpress/feeds/list', methods=['GET'])
def get_available_feeds():
    """Obter lista de feeds disponíveis"""
    try:
        result = feed_service.get_available_feeds()
        return jsonify(result)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/aliexpress/feeds/<feed_name>/products', methods=['GET'])
def get_feed_products(feed_name):
    """Obter produtos de um feed específico"""
    try:
        page = int(request.args.get('page', 1))
        page_size = int(request.args.get('page_size', 20))
        
        result = feed_service.get_feed_products(feed_name, page, page_size)
        return jsonify(result)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500
```

---

## 📱 **IMPLEMENTAÇÃO FRONTEND**

### **1. Modelos (models/feed_models.dart)**
```dart
class Feed {
  final String feedName;
  final String feedId;
  final String displayName;
  final String description;
  final int productCount;

  Feed({
    required this.feedName,
    required this.feedId,
    required this.displayName,
    required this.description,
    required this.productCount,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      feedName: json['feed_name'] ?? '',
      feedId: json['feed_id'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      productCount: json['product_count'] ?? 0,
    );
  }
}

class FeedProducts {
  final String feedName;
  final List<Product> products;
  final PaginationInfo pagination;

  FeedProducts({
    required this.feedName,
    required this.products,
    required this.pagination,
  });

  factory FeedProducts.fromJson(Map<String, dynamic> json) {
    return FeedProducts(
      feedName: json['feed_name'] ?? '',
      products: (json['products'] as List?)
          ?.map((p) => Product.fromJson(p))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int pageNo;
  final int pageSize;
  final int totalCount;
  final bool hasNext;
  final int totalPages;

  PaginationInfo({
    required this.pageNo,
    required this.pageSize,
    required this.totalCount,
    required this.hasNext,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      pageNo: json['page_no'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      hasNext: json['has_next'] ?? false,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}
```

### **2. Serviço (services/aliexpress_service.dart)**
```dart
class AliExpressService {
  static const String baseUrl = 'https://mercadodasophia-api.onrender.com/api';

  // Método existente
  Future<List<Product>> searchProducts(String query) async {
    // Implementação existente
  }

  // Novo método para obter feeds disponíveis
  Future<List<Feed>> getAvailableFeeds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/aliexpress/feeds/list'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['feeds'] as List)
              .map((feed) => Feed.fromJson(feed))
              .toList();
        }
      }
      throw Exception('Falha ao carregar feeds');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Novo método para obter produtos de um feed
  Future<FeedProducts> getFeedProducts(String feedName, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/aliexpress/feeds/$feedName/products?page=$page'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return FeedProducts.fromJson(data);
        }
      }
      throw Exception('Falha ao carregar produtos do feed');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
```

### **3. Widgets Especializados**

#### **FeedSelectorWidget**
```dart
class FeedSelectorWidget extends StatelessWidget {
  final List<Feed> feeds;
  final String selectedFeed;
  final Function(String) onFeedSelected;

  const FeedSelectorWidget({
    Key? key,
    required this.feeds,
    required this.selectedFeed,
    required this.onFeedSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          final feed = feeds[index];
          final isSelected = feed.feedName == selectedFeed;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(feed.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFeedSelected(feed.feedName);
                }
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

#### **FeedProductsGrid**
```dart
class FeedProductsGrid extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final VoidCallback? onLoadMore;

  const FeedProductsGrid({
    Key? key,
    required this.products,
    this.isLoading = false,
    this.onLoadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length + (isLoading ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return _buildLoadingCard();
        }
        
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
```

### **4. Atualização da Tela Principal (screens/products_screen.dart)**
```dart
class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final AliExpressService _aliExpressService = AliExpressService();
  
  List<Feed> _feeds = [];
  String _selectedFeed = 'top_selling_products';
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
    _loadProducts();
  }

  Future<void> _loadFeeds() async {
    try {
      final feeds = await _aliExpressService.getAvailableFeeds();
      setState(() {
        _feeds = feeds;
      });
    } catch (e) {
      // Tratar erro
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (refresh) {
        _currentPage = 1;
        _products.clear();
      }

      final feedProducts = await _aliExpressService.getFeedProducts(
        _selectedFeed,
        page: _currentPage,
      );

      setState(() {
        if (refresh) {
          _products = feedProducts.products;
        } else {
          _products.addAll(feedProducts.products);
        }
        _hasMore = feedProducts.pagination.hasNext;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Tratar erro
    }
  }

  void _onFeedSelected(String feedName) {
    setState(() {
      _selectedFeed = feedName;
    });
    _loadProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mercado da Sophia'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(refresh: true),
        child: Column(
          children: [
            if (_feeds.isNotEmpty)
              FeedSelectorWidget(
                feeds: _feeds,
                selectedFeed: _selectedFeed,
                onFeedSelected: _onFeedSelected,
              ),
            Expanded(
              child: FeedProductsGrid(
                products: _products,
                isLoading: _isLoading,
                onLoadMore: _hasMore ? () => _loadProducts() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 **TESTES**

### **1. Testes de API**
```bash
# Testar listagem de feeds
curl -X GET "https://mercadodasophia-api.onrender.com/api/aliexpress/feeds/list"

# Testar produtos de um feed
curl -X GET "https://mercadodasophia-api.onrender.com/api/aliexpress/feeds/top_selling_products/products?page=1&page_size=20"
```

### **2. Testes Frontend**
```dart
test('should load feeds successfully', () async {
  final service = AliExpressService();
  final feeds = await service.getAvailableFeeds();
  
  expect(feeds, isNotEmpty);
  expect(feeds.first, isA<Feed>());
});

test('should load feed products successfully', () async {
  final service = AliExpressService();
  final feedProducts = await service.getFeedProducts('top_selling_products');
  
  expect(feedProducts.products, isNotEmpty);
  expect(feedProducts.pagination, isA<PaginationInfo>());
});
```

---

## 🚀 **DEPLOY E MONITORAMENTO**

### **1. Variáveis de Ambiente**
```env
ALIEXPRESS_APP_KEY=your_app_key
ALIEXPRESS_APP_SECRET=your_app_secret
CACHE_REDIS_URL=redis://localhost:6379
```

### **2. Monitoramento**
- **Métricas**: Tempo de resposta das APIs
- **Cache Hit Rate**: Eficiência do cache
- **Erro Rate**: Taxa de erros nas chamadas
- **User Engagement**: Tempo na tela, produtos visualizados

### **3. Logs**
```python
import logging

logging.info(f"Loading feeds for user: {user_id}")
logging.info(f"Feed {feed_name} loaded with {len(products)} products")
logging.error(f"Failed to load feed {feed_name}: {error}")
```

---

## 📊 **MÉTRICAS DE SUCESSO**

### **Técnicas**
- [ ] ✅ Tempo de carregamento < 2s
- [ ] ✅ Cache hit rate > 80%
- [ ] ✅ Taxa de erro < 5%
- [ ] ✅ Paginação funcionando

### **Negócio**
- [ ] ✅ Produtos sempre atualizados
- [ ] ✅ Engajamento dos usuários aumentou
- [ ] ✅ Conversão melhorou
- [ ] ✅ Tempo na tela aumentou

---

**📅 Última atualização**: Janeiro 2024
**👥 Responsável**: Equipe de Desenvolvimento
**🎯 Status**: Pronto para implementação
