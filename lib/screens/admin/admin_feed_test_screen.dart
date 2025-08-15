import 'package:flutter/material.dart';
import '../../models/feed.dart';
import '../../models/product.dart';
import '../../services/aliexpress_service.dart';
import '../../widgets/feed_selector_widget.dart';
import '../../widgets/feed_products_grid.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }
  
  Future<void> _loadFeeds() async {
    try {
      setState(() {
        isLoadingFeeds = true;
      });
      
      final availableFeeds = await _aliExpressService.getAvailableFeeds();
      
      setState(() {
        feeds = availableFeeds;
        isLoadingFeeds = false;
      });
      
      // Carregar o primeiro feed automaticamente
      if (feeds.isNotEmpty) {
        _onFeedSelected(feeds.first.feedName);
      }
    } catch (e) {
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
  
  Future<void> _loadFeedProducts({bool refresh = false}) async {
    if (selectedFeed == null) return;
    
    try {
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeeds,
            tooltip: 'Recarregar feeds',
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de Feeds
          if (feeds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Feeds Disponíveis:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FeedSelectorWidget(
                    feeds: feeds,
                    selectedFeed: selectedFeed ?? '',
                    onFeedSelected: _onFeedSelected,
                  ),
                ],
              ),
            ),
          
          // Estatísticas do Feed
          if (selectedFeed != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feed: ${selectedFeed}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Produtos carregados: ${feedProducts.length}',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoadingFeedProducts)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Grid de Produtos
          Expanded(
            child: isLoadingFeeds
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando feeds disponíveis...'),
                      ],
                    ),
                  )
                : feeds.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum feed disponível',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Verifique a conexão com a API do AliExpress',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FeedProductsGrid(
                        products: feedProducts,
                        isLoading: isLoadingFeedProducts,
                        hasMore: hasMoreFeedProducts,
                        onLoadMore: () => _loadFeedProducts(),
                      ),
          ),
        ],
      ),
    );
  }
}
