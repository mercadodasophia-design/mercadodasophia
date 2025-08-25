import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/aliexpress_service.dart';

// Fallback simples de formatação de preço para evitar dependência
String _formatPrice(String value, {String currency = 'BRL'}) {
  try {
    final v = double.tryParse(value.replaceAll(',', '.'));
    if (v == null) return value;
    return 'R\$ ${v.toStringAsFixed(2)}';
  } catch (_) {
    return value;
  }
}

class AdminFeedsScreen extends StatefulWidget {
  const AdminFeedsScreen({super.key});

  @override
  State<AdminFeedsScreen> createState() => _AdminFeedsScreenState();
}

class _AdminFeedsScreenState extends State<AdminFeedsScreen> {
  final AliExpressService _service = AliExpressService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _feeds = const [];
  int _selectedFeedIndex = -1; // -1 = Todos
  int _page = 1;
  final int _pageSize = 8; // AliExpress só permite 8 produtos por página
  int? _totalProductsForSelected; // contador por categoria
  bool _loadingMore = false; // Loading apenas no botão "Carregar mais"
  final List<Map<String, dynamic>> _aggregatedProducts = [];
  final Set<String> _seenProductIds = <String>{};
  bool _hasMoreProducts = true; // Controla se há mais produtos para carregar

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await _tryLoadFromCache();
    await _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMoreProducts = true;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      print('🔍 DEBUG: Carregando página $_page, feed selecionado: $_selectedFeedIndex');
      final data = await _service.getCompleteFeeds(
        page: _page, 
        pageSize: _pageSize, 
        maxFeeds: 3, 
        details: true
      );
      
      print('🔍 DEBUG: Resposta da API: ${data.keys}');
      
      final List<dynamic> feeds = (data['feeds'] as List<dynamic>? ?? const []);
      if (!mounted) return;
      
      setState(() {
        _feeds = feeds.cast<Map<String, dynamic>>();
        if (reset) _loading = false;
        _totalProductsForSelected = _computeSelectedCount();
      });

      // Extrair produtos desta página
      final List<Map<String, dynamic>> newProducts = _selectedFeedIndex == -1
          ? _flattenAllProducts(_feeds)
          : _extractProducts(_feeds[_selectedFeedIndex]);
      
      print('🔍 DEBUG: Extraídos ${newProducts.length} produtos desta página');
      
      if (!mounted) return;
      
      // Adicionar produtos novos (sem duplicatas)
      int newProductsAdded = 0;
      setState(() {
        if (reset) {
          _aggregatedProducts.clear();
          _seenProductIds.clear();
        }
        
        for (final p in newProducts) {
          final id = p['product_id']?.toString() ?? '';
          if (id.isEmpty || _seenProductIds.contains(id)) continue;
          _seenProductIds.add(id);
          _aggregatedProducts.add(p);
          newProductsAdded++;
        }
        
        // Verificar se há mais produtos para carregar
        // Se recebeu produtos novos, pode haver mais páginas
        // Também continuar se ainda não tentou muitas páginas (cada feed tem milhares de produtos)
        _hasMoreProducts = newProductsAdded > 0 || (_page < 10 && _aggregatedProducts.length < 100);
        _loadingMore = false;
      });
      
      print('🔍 DEBUG: Total acumulado: ${_aggregatedProducts.length} produtos (${newProductsAdded} novos adicionados)');
      print('🔍 DEBUG: Há mais produtos? $_hasMoreProducts');
      
      await _saveCache();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        if (reset) _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMoreProducts) return;
    
    _page += 1;
    await _load(reset: false);
  }

  int? _computeSelectedCount() {
    if (_selectedFeedIndex < 0 || _selectedFeedIndex >= _feeds.length) return null;
    final feed = _feeds[_selectedFeedIndex];
    final count = feed['product_count'];
    if (count is int) return count;
    if (count is String) return int.tryParse(count);
    return null;
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = {
        'selected_index': _selectedFeedIndex,
        'page': _page,
        'products': _aggregatedProducts,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('admin_feeds_cache', jsonEncode(cache));
    } catch (_) {}
  }

  Future<void> _tryLoadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('admin_feeds_cache');
      if (raw == null) return;
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final products = (parsed['products'] as List?)?.cast<Map<String, dynamic>>();
      if (products == null) return;
      setState(() {
        _selectedFeedIndex = parsed['selected_index'] as int? ?? -1;
        _page = parsed['page'] as int? ?? 1;
        _aggregatedProducts
          ..clear()
          ..addAll(products);
        _seenProductIds
          ..clear()
          ..addAll(products.map((p) => p['product_id']?.toString() ?? '').where((e) => e.isNotEmpty));
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeds AliExpress'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(reset: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Erro: $_error'));
    }
    if (_feeds.isEmpty) {
      return const Center(child: Text('Nenhum feed disponível'));
    }

    final chips = ['Todos', ..._feeds.map((f) => (f['display_name']?.toString() ?? f['feed_name']?.toString() ?? 'Feed')).toList()];

    final List<Map<String, dynamic>> products = _aggregatedProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips de categorias (feeds)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(chips.length, (i) {
                final selected = (i - 1) == _selectedFeedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(chips[i]),
                    selected: i == 0 ? _selectedFeedIndex == -1 : selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFeedIndex = i == 0 ? -1 : i - 1;
                        _page = 1;
                        _totalProductsForSelected = _computeSelectedCount();
                        _aggregatedProducts.clear();
                        _seenProductIds.clear();
                        _hasMoreProducts = true;
                      });
                      _load(reset: true);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedFeedIndex >= 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _totalProductsForSelected != null
                    ? 'Produtos nesta categoria: $_totalProductsForSelected'
                    : 'Produtos nesta categoria',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          // Grid de produtos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => _ProductCard(product: products[i]),
          ),
          const SizedBox(height: 12),
          
          // Botão "Carregar mais" com loading
          if (_hasMoreProducts)
            Center(
              child: TextButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.expand_more),
                label: Text(_loadingMore ? 'Carregando...' : 'Carregar mais'),
              ),
            ),
          
          // Indicador de fim da lista
          if (!_hasMoreProducts && products.isNotEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Todos os produtos foram carregados',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _flattenAllProducts(List<Map<String, dynamic>> feeds) {
    final List<Map<String, dynamic>> all = [];
    for (final f in feeds) {
      all.addAll(_extractProducts(f));
    }
    return all;
  }

  List<Map<String, dynamic>> _extractProducts(Map<String, dynamic> feed) {
    final List<Map<String, dynamic>> list = [];
    
    print('🔍 DEBUG: Extraindo produtos do feed: ${feed['feed_name']}');
    print('🔍 DEBUG: Estrutura do feed: ${feed.keys}');
    
    // 1) Primeiro tentar products (formato simples)
    if (feed['products'] is List) {
      final List<dynamic> products = feed['products'];
      print('🔍 DEBUG: Encontrados ${products.length} produtos em products[]');
      for (final product in products) {
        if (product is Map<String, dynamic>) {
          list.add({
            'product_id': product['product_id']?.toString() ?? '',
            'title': product['title']?.toString() ?? '',
            'main_image': product['main_image']?.toString() ?? '',
            'price': product['price']?.toString() ?? '',
            'currency': product['currency']?.toString() ?? 'BRL',
          });
        }
      }
    }
    
    // 2) Se não encontrou produtos, tentar item_ids (formato complexo)
    if (list.isEmpty && feed['item_ids'] is Map) {
      print('🔍 DEBUG: Tentando extrair de item_ids...');
      (feed['item_ids'] as Map).forEach((key, value) {
        if (value is List && value.isNotEmpty && value.first is Map) {
          final Map result = value.first as Map;
          // Normalizar campos
          final base = result['ae_item_base_info_dto'] as Map? ?? const {};
          final multimedia = result['ae_multimedia_info_dto'] as Map? ?? const {};
          String? mainImage;
          final imageUrls = multimedia['image_urls']?.toString();
          if (imageUrls != null && imageUrls.isNotEmpty) {
            final parts = imageUrls.split(';');
            if (parts.isNotEmpty) mainImage = parts.first;
          }
          // Fallback de main_image via products resumidos, se existir
          mainImage ??= result['product_main_image_url']?.toString();
          // Fallback extra: primeira imagem de algum SKU
          if (mainImage == null || mainImage.isEmpty) {
            final skusMap = result['ae_item_sku_info_dtos'] as Map?;
            final skus = skusMap != null ? skusMap['ae_item_sku_info_d_t_o'] : null;
            if (skus is List && skus.isNotEmpty) {
              for (final s in skus) {
                final propMap = (s as Map?)?['ae_sku_property_dtos'] as Map?;
                final props = propMap != null ? propMap['ae_item_sku_property_d_t_o'] : null;
                if (props is List) {
                  for (final p in props) {
                    final img = (p as Map?)?['sku_image']?.toString();
                    if (img != null && img.isNotEmpty) { mainImage = img; break; }
                  }
                }
                if (mainImage != null && mainImage.isNotEmpty) break;
              }
            }
          }
          final skuInfo = _extractPriceAndImageFromSkus(result);
          if ((mainImage == null || mainImage.isEmpty) && skuInfo != null && (skuInfo['image']?.toString().isNotEmpty ?? false)) {
            mainImage = skuInfo['image'].toString();
          }
          final price = (skuInfo?['price']?.toString()) ??
              base['target_sale_price']?.toString() ??
              base['sale_price']?.toString() ??
              result['sale_price']?.toString() ?? '';
          list.add({
            'product_id': key.toString(),
            'title': base['subject']?.toString() ?? '',
            'main_image': mainImage,
            'price': price,
            'currency': skuInfo?['currency']?.toString() ?? 'BRL',
          });
        }
      });
    }
    
    // 3) Se ainda não encontrou, tentar item_ids como lista simples
    if (list.isEmpty && feed['item_ids'] is List) {
      print('🔍 DEBUG: Tentando extrair de item_ids como lista...');
      final List<dynamic> itemIds = feed['item_ids'];
      for (final id in itemIds) {
        list.add({
          'product_id': id.toString(),
          'title': 'Produto ${id}',
          'main_image': '',
          'price': '0.00',
          'currency': 'BRL',
        });
      }
    }
    
    print('🔍 DEBUG: Total de produtos extraídos: ${list.length}');
    return list;
  }

  Map<String, dynamic>? _extractPriceAndImageFromSkus(Map data) {
    final skus = (data['ae_item_sku_info_dtos'] as Map?)?['ae_item_sku_info_d_t_o'];
    if (skus is! List || skus.isEmpty) return null;

    double? minPrice;
    String? currency;
    String? skuImage;
    for (final raw in skus) {
      final sku = raw as Map? ?? const {};
      final sale = sku['offer_sale_price']?.toString();
      final base = sku['sku_price']?.toString();
      final code = sku['currency_code']?.toString();
      if (currency == null && code != null && code.isNotEmpty) currency = code;
      final p = double.tryParse((sale ?? base ?? '').replaceAll(',', '.'));
      if (p != null) {
        if (minPrice == null || p < minPrice) minPrice = p;
      }
      // Tentar imagem de variação
      if (skuImage == null || skuImage.isEmpty) {
        final propMap = (sku['ae_sku_property_dtos'] as Map?)?['ae_item_sku_property_d_t_o'];
        if (propMap is List) {
          for (final pr in propMap) {
            final img = (pr as Map?)?['sku_image']?.toString();
            if (img != null && img.isNotEmpty) { skuImage = img; break; }
          }
        }
      }
    }
    if (minPrice == null) return null;
    return {
      'price': minPrice.toStringAsFixed(2),
      'currency': currency ?? 'BRL',
      'image': skuImage,
    };
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final String title = product['title']?.toString() ?? '';
    final String? image = product['main_image']?.toString();
    final String? price = product['price']?.toString();
    final String currency = product['currency']?.toString() ?? 'BRL';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: image == null || image.isEmpty
                    ? Container(color: Colors.grey.shade200)
                    : Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (price != null && price.isNotEmpty && price != '0' && price != '0.00')
                    Text(
                      _formatPrice(price, currency: currency),
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


