import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/aliexpress_service.dart';

class AdminFeedsScreen extends StatefulWidget {
  const AdminFeedsScreen({super.key});

  @override
  State<AdminFeedsScreen> createState() => _AdminFeedsScreenState();
}

class _AdminFeedsScreenState extends State<AdminFeedsScreen> {
  final AliExpressService _service = AliExpressService();
  bool _loading = true;
  bool _loadingProducts = false;
  String? _error;
  
  // Feeds
  List<Map<String, dynamic>> _feeds = [];
  String? _selectedFeedName;
  
  // Produtos
  List<Map<String, dynamic>> _products = [];
  int _currentPage = 1;
  final int _pageSize = 10; // Reduzido para melhorar performance
  bool _hasMoreProducts = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('📋 ADMIN: Carregando feeds...');
      final data = await _service.getAdminFeeds();
      
      if (data['success'] == true) {
        final feeds = List<Map<String, dynamic>>.from(data['data']['feeds'] ?? []);
        setState(() {
          _feeds = feeds;
          _loading = false;
        });
        print('✅ ADMIN: ${feeds.length} feeds carregados');
      } else {
        throw Exception(data['message'] ?? 'Erro ao carregar feeds');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      print('❌ ADMIN: Erro ao carregar feeds: $e');
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (_selectedFeedName == null) return;

    if (reset) {
      setState(() {
        _loadingProducts = true;
        _currentPage = 1;
        _products.clear();
        _hasMoreProducts = true;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
             print('📦 ADMIN: Carregando produtos do feed $_selectedFeedName (página $_currentPage)');
       print('📦 ADMIN: Parâmetros - page: $_currentPage, pageSize: $_pageSize');
      final data = await _service.getAdminFeedProducts(
        _selectedFeedName!,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
                    if (data['success'] == true) {
         final products = List<Map<String, dynamic>>.from(data['data']['products'] ?? []);
         final pagination = data['data']['pagination'] ?? {};
         
         // Debug: verificar estrutura dos dados
         print('🔍 ADMIN: Estrutura dos dados recebidos:');
         print('  - Produtos: ${products.length}');
         print('  - Paginação: $pagination');
         if (products.isNotEmpty) {
           print('  - Primeiro produto: ${products.first.keys}');
           print('  - ID do primeiro produto: ${products.first['id']}');
           print('  - IDs dos produtos: ${products.map((p) => p['id']).toList()}');
           print('  - ESTRUTURA COMPLETA DO PRIMEIRO PRODUTO:');
           print('    ${products.first}');
           print('  - Imagem do primeiro produto: ${products.first['main_image']}');
           print('  - URL da imagem: ${products.first['main_image']}');
           print('  - Tipo da imagem: ${products.first['main_image'].runtimeType}');
           print('  - Imagem está vazia? ${products.first['main_image'].toString().isEmpty}');
         }
        
                 setState(() {
           if (reset) {
             _products = products;
           } else {
             // Verificar se há produtos duplicados
             final existingIds = _products.map((p) => p['id']).toSet();
             final newProducts = products.where((p) => !existingIds.contains(p['id'])).toList();
             print('🔄 ADMIN: Produtos novos: ${newProducts.length} de ${products.length}');
             _products.addAll(newProducts);
           }
           // Verificar se há mais produtos baseado na paginação e no número de produtos recebidos
           _hasMoreProducts = (pagination['has_more'] ?? false) || 
                             (products.length >= _pageSize); // Se recebeu o número máximo, provavelmente há mais
           _loadingProducts = false;
           _loadingMore = false;
         });
        
                 print('✅ ADMIN: ${products.length} produtos carregados (total: ${_products.length})');
         print('✅ ADMIN: Há mais produtos? $_hasMoreProducts');
      } else {
        throw Exception(data['message'] ?? 'Erro ao carregar produtos');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingProducts = false;
        _loadingMore = false;
      });
      print('❌ ADMIN: Erro ao carregar produtos: $e');
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loadingMore || !_hasMoreProducts) return;
    
    print('🔄 ADMIN: Carregando mais produtos - página atual: $_currentPage');
    _currentPage++;
    print('🔄 ADMIN: Nova página: $_currentPage');
    await _loadProducts(reset: false);
  }

  void _selectFeed(String feedName) {
    setState(() {
      _selectedFeedName = feedName;
    });
    _loadProducts(reset: true);
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
            onPressed: _loadFeeds,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar feeds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeeds,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Seção de Feeds (Chips)
        _buildFeedsSection(),
        
        // Seção de Produtos
        Expanded(
          child: _buildProductsSection(),
        ),
      ],
    );
  }

  Widget _buildFeedsSection() {
    return Container(
      height: 200, // Altura fixa para evitar overflow
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fixo
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.rss_feed, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Feeds Disponíveis (${_feeds.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Chips scrolláveis
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Chip "Todos"
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedFeedName == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFeedName = null;
                          _products.clear();
                        });
                      }
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                  ),
                  // Chips dos feeds
                  ..._feeds.map((feed) {
                    final feedName = feed['name'] ?? '';
                    final productCount = feed['product_count'] ?? 0;
                    final isSelected = _selectedFeedName == feedName;
                    
                    return FilterChip(
                      label: Text('${feed['display_name'] ?? feedName} ($productCount)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _selectFeed(feedName);
                        }
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_selectedFeedName == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Selecione um feed para ver os produtos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Carregando produtos do feed...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Isso pode levar alguns segundos',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header dos produtos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Produtos do Feed: ${_selectedFeedName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_products.length} produtos',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
                 // Lista de produtos
         Expanded(
           child: GridView.builder(
             padding: const EdgeInsets.all(16),
             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 
                              MediaQuery.of(context).size.width > 800 ? 3 : 2,
               childAspectRatio: 0.75,
               crossAxisSpacing: 16,
               mainAxisSpacing: 16,
             ),
             itemCount: _products.length + (_hasMoreProducts ? 1 : 0),
             itemBuilder: (context, index) {
               if (index == _products.length) {
                 // Botão "Carregar Mais"
                 return _buildLoadMoreButton();
               }
               
               final product = _products[index];
               return _buildProductCard(product);
             },
           ),
         ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = product['title'] ?? 'Sem título';
    final price = product['price'] ?? 0.0;
    final originalPrice = product['original_price'] ?? 0.0;
    final rating = product['rating'] ?? 0.0;
    final orders = product['orders'] ?? 0;
    // Tentar pegar a primeira imagem do array images se main_image estiver vazio
    final mainImage = (product['main_image']?.toString().isNotEmpty == true) 
        ? product['main_image'] 
        : (product['images'] is List && (product['images'] as List).isNotEmpty) 
            ? (product['images'] as List).first 
            : '';
    final isImported = product['is_imported'] ?? false;
    
    // Debug: verificar dados do produto
    print('🖼️ ADMIN: Construindo card do produto:');
    print('  - Título: $title');
    print('  - Preço: $price');
    print('  - Preço original: ${product['original_price']}');
    print('  - Campo price: ${product['price']}');
    print('  - Campo price type: ${product['price'].runtimeType}');
    print('  - Campo original_price: ${product['original_price']}');
    print('  - Campo currency: ${product['currency']}');
    print('  - Campo discount: ${product['discount']}');
    print('  - Todos os campos do produto: ${product.keys.toList()}');
    print('  - Campos que contêm "price": ${product.keys.where((k) => k.toString().toLowerCase().contains('price')).toList()}');
    print('  - Imagem final: "$mainImage"');
    print('  - Tipo da imagem: ${mainImage.runtimeType}');
    print('  - Imagem vazia? ${mainImage.isEmpty}');
    print('  - Campo images: ${product['images']}');
    print('  - Campo main_image: ${product['main_image']}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do produto
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey.shade100,
              ),
                             child: mainImage.isNotEmpty
                   ? ClipRRect(
                       borderRadius: const BorderRadius.vertical(
                         top: Radius.circular(12),
                       ),
                       child: Image.network(
                         mainImage,
                         fit: BoxFit.cover,
                         loadingBuilder: (context, child, loadingProgress) {
                           if (loadingProgress == null) return child;
                           return Center(
                             child: CircularProgressIndicator(
                               value: loadingProgress.expectedTotalBytes != null
                                   ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                   : null,
                               strokeWidth: 2,
                             ),
                           );
                         },
                         errorBuilder: (context, error, stackTrace) {
                           print('❌ Erro ao carregar imagem: $mainImage - $error');
                           return const Center(
                             child: Icon(
                               Icons.image_not_supported,
                               color: Colors.grey,
                             ),
                           );
                         },
                       ),
                     )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          
          // Informações do produto
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Preço
                  Row(
                    children: [
                      Text(
                        'R\$ ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (originalPrice > price) ...[
                        const SizedBox(width: 4),
                        Text(
                          'R\$ ${originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Avaliação e vendas
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.shopping_cart,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        orders.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  
                  // Botão Importar
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isImported ? null : () {
                        // TODO: Implementar importação
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidade de importação em desenvolvimento'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        backgroundColor: isImported ? Colors.grey : Colors.blue,
                      ),
                      child: Text(
                        isImported ? 'Importado' : 'Importar',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    print('🔍 ADMIN: Construindo botão "Carregar Mais" - _hasMoreProducts: $_hasMoreProducts, _loadingMore: $_loadingMore');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _loadingMore ? null : _loadMoreProducts,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.blue.shade50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loadingMore)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Colors.blue.shade400,
                ),
              const SizedBox(height: 8),
              Text(
                _loadingMore ? 'Carregando...' : 'Carregar Mais',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


