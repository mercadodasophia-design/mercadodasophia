import 'package:flutter/material.dart';
import '../../models/feed.dart';
import '../../models/product.dart';
import '../../services/aliexpress_service.dart';
import '../../theme/app_theme.dart';

class AdminFeedTestScreen extends StatefulWidget {
  const AdminFeedTestScreen({super.key});

  @override
  State<AdminFeedTestScreen> createState() => _AdminFeedTestScreenState();
}

class _AdminFeedTestScreenState extends State<AdminFeedTestScreen> {
  final AliExpressService _aliExpressService = AliExpressService();
  
  List<Feed> feeds = [];
  String? selectedFeed;
  List<Product> feedProducts = [];
  bool isLoadingFeeds = true;
  bool isLoadingFeedProducts = false;
  bool hasMoreFeedProducts = true;
  int currentFeedPage = 1;
  
  // Novos campos para o endpoint completo
  Map<String, dynamic>? completeFeedsData;
  bool isLoadingCompleteFeeds = false;
  
  @override
  void initState() {
    super.initState();
    // Carregar apenas feeds completos automaticamente
    _loadCompleteFeeds();
  }
  
  Future<void> _loadFeeds() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoadingFeeds = true;
      });
      
      final availableFeeds = await _aliExpressService.getAvailableFeeds();
      
      if (!mounted) return;
      setState(() {
        feeds = availableFeeds;
        isLoadingFeeds = false;
      });
      
      // Carregar o primeiro feed automaticamente
      if (feeds.isNotEmpty) {
        _onFeedSelected(feeds.first.feedName);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingFeeds = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar feeds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Novo método para carregar feeds completos
  Future<void> _loadCompleteFeeds() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoadingCompleteFeeds = true;
      });
      
      final completeData = await _aliExpressService.getCompleteFeeds(
        page: 1,
        pageSize: 10,
        maxFeeds: 3,
      );
      
      if (!mounted) return;
      setState(() {
        completeFeedsData = completeData;
        isLoadingCompleteFeeds = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feeds completos carregados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingCompleteFeeds = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar feeds completos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadFeedProducts({bool refresh = false}) async {
    if (selectedFeed == null) return;
    
    try {
      if (!mounted) return;
      setState(() {
        isLoadingFeedProducts = true;
      });
      
      if (refresh) {
        currentFeedPage = 1;
        feedProducts.clear();
      }
      
      final feedProductsData = await _aliExpressService.getFeedProducts(
        selectedFeed!,
        page: currentFeedPage,
      );
      
      if (!mounted) return;
      setState(() {
        if (refresh) {
          feedProducts = feedProductsData.products;
        } else {
          feedProducts.addAll(feedProductsData.products);
        }
        
        hasMoreFeedProducts = feedProductsData.pagination.hasNext;
        currentFeedPage++;
        isLoadingFeedProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingFeedProducts = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _onFeedSelected(String feedName) {
    setState(() {
      selectedFeed = feedName;
    });
    _loadFeedProducts(refresh: true);
  }

  Widget _buildCompleteFeedsView() {
    if (completeFeedsData == null) return const SizedBox.shrink();
    
    final feeds = completeFeedsData!['feeds'] as List;
    final pagination = completeFeedsData!['pagination'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informações de paginação
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Feeds: ${pagination['total_feeds']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Página: ${pagination['page']} | Produtos por página: ${pagination['page_size']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de feeds
        ...feeds.map((feed) => _buildFeedCard(feed)),
      ],
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> feed) {
    final feedName = feed['feed_name'] as String;
    final description = feed['description'] as String;
    final products = feed['products'] as List;
    final productCount = feed['product_count'] as int;
    final productsFound = feed['products_found'] as int;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rss_feed, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$productsFound/$productCount',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Produtos do feed
            if (products.isNotEmpty) ...[
              const Text(
                'Produtos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index] as Map<String, dynamic>;
                    return _buildProductCard(product);
                  },
                ),
              ),
            ] else ...[
              const Text(
                'Nenhum produto encontrado',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['product_id']?.toString() ?? '';
    final title = product['title']?.toString() ?? '';
    final price = product['price']?.toString() ?? '';
    final mainImage = product['main_image']?.toString() ?? '';
    final rating = (product['rating'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      width: 150,
      height: 200, // Altura fixa para evitar overflow
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
            children: [
              // Imagem do produto
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: mainImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          mainImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 8),
              
              // Título do produto
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : 'Produto $productId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              
              // Preço e rating
              Row(
                children: [
                  Expanded(
                    child: Text(
                      price.isNotEmpty ? price : 'R\$ 0,00',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rating > 0) ...[
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Teste do Feed AliExpress'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _loadCompleteFeeds,
            tooltip: 'Carregar Feeds Completos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeeds,
            tooltip: 'Recarregar feeds',
          ),
        ],
      ),
      body: Column(
        children: [

          
          // Visualização dos Feeds Completos - SEÇÃO PRINCIPAL
          Expanded(
            child: isLoadingCompleteFeeds
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('🚀 Carregando Feeds Completos...'),
                        SizedBox(height: 8),
                        Text(
                          'Buscando produtos do AliExpress',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : completeFeedsData != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.orange, size: 28),
                                const SizedBox(width: 12),
                                const Text(
                                  '🚀 Feeds Completos (AliExpress)',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _loadCompleteFeeds,
                                  tooltip: 'Recarregar feeds',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildCompleteFeedsView(),
                          ],
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rss_feed,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum feed carregado',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Clique no botão para carregar os feeds',
                              style: TextStyle(
                                color: Colors.grey,
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
}
