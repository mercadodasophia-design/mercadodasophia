import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../services/category_service.dart';
import 'admin_product_detail_screen.dart';

class AdminAliExpressSearchScreen extends StatefulWidget {
  const AdminAliExpressSearchScreen({super.key});

  @override
  State<AdminAliExpressSearchScreen> createState() => _AdminAliExpressSearchScreenState();
}

class _AdminAliExpressSearchScreenState extends State<AdminAliExpressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _products = [];
  String? _errorMessage;
  String _searchQuery = '';
  
  // Categorias
  List<Category> _categories = [];
  bool _isLoadingCategories = false;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Removido busca padrão - agora só carrega categorias
    _loadCategories();
  }

  // Carregar categorias
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await CategoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      print('❌ Erro ao carregar categorias: $e');
    }
  }

  // Buscar produtos por categoria
  Future<void> _searchByCategory(Category category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await CategoryService.getProductsByCategory(category.id, category.name);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar produtos da categoria: $e';
        _isLoading = false;
      });
    }
  }

  // Função unificada para buscar por texto ou link
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Digite um termo para buscar ou cole um link do AliExpress';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Verificar se é um link do AliExpress
    if (query.contains('aliexpress.com') || query.contains('aliexpress.us') || query.contains('alibaba.com')) {
      print('🔗 DETECTADO COMO LINK: $query');
      print('🔗 Chamando _searchByLink...');
      await _searchByLink(query);
    } else {
      print('🔍 DETECTADO COMO TEXTO: $query');
      print('🔍 Chamando _searchByText...');
      await _searchByText(query);
    }
  }

  // Buscar por texto
  Future<void> _searchByText(String query) async {
    print('🔍 Buscando por texto: $query');
    
    try {
      final response = await http.get(
        Uri.parse('https://mercadodasophia-api.onrender.com/api/aliexpress/products?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Resposta produtos: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Data keys: ${data.keys}');
        
        List<dynamic> products = [];

        // Tentar extrair produtos da estrutura aninhada esperada
        if (data.containsKey('data') && data['data'] != null) {
          final outerData = data['data'];
          if (outerData is Map && outerData.containsKey('aliexpress_ds_text_search_response')) {
            final aliResponse = outerData['aliexpress_ds_text_search_response'];
            if (aliResponse is Map && aliResponse.containsKey('data')) {
              final aliData = aliResponse['data'];
              if (aliData is Map && aliData.containsKey('products')) {
                final productsContainer = aliData['products'];
                if (productsContainer is Map && productsContainer.containsKey('selection_search_product')) {
                  final productList = productsContainer['selection_search_product'];
                  if (productList is List) {
                    products = productList;
                    print('✅ Produtos encontrados via aliexpress_ds_text_search_response: ${products.length}');
                  }
                }
              }
            }
          }
        }
        
        print('🔍 Total de produtos processados: ${products.length}');
        
        if (products.isNotEmpty) {
          // Debug: mostrar dados do primeiro produto
          print('🔍 Primeiro produto: ${products.first}');
          print('🔍 Título do primeiro produto: ${products.first['title']}');
          
          setState(() {
            _products = products; // Atribuir a lista completa de produtos
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Produtos encontrados!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Nenhum produto encontrado para "$query"';
            _products = []; // Limpar produtos se nenhum for encontrado
            _isLoading = false;
          });
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Erro ${response.statusCode}: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao buscar produtos por texto: $e');
      setState(() {
        _errorMessage = 'Erro ao buscar produtos: $e';
        _isLoading = false;
      });
    }
  }

  // Buscar por link
  Future<void> _searchByLink(String link) async {
    print('🔗 INÍCIO: _searchByLink chamada com: $link');
    print('🔗 Buscando por link: $link');
    
    // Extrair product_id do link
    String? productId;
    final uri = Uri.parse(link);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;
      if (lastSegment.contains('.html')) {
        productId = lastSegment.replaceAll('.html', '');
      } else {
        productId = lastSegment;
      }
    }
    
    if (productId == null || productId.isEmpty) {
          setState(() {
        _errorMessage = 'Não foi possível extrair o ID do produto do link';
            _isLoading = false;
          });
      return;
    }
    
    print('🔗 Product ID extraído: $productId');

    try {
      // Buscar o produto específico pelo ID exato usando o endpoint existente
      final response = await http.get(
        Uri.parse('https://mercadodasophia-api.onrender.com/api/aliexpress/product/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Resposta produto específico: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Data keys: ${data.keys}');
        
        // Verificar se temos dados do produto específico
        if (data.containsKey('data') && data['data'] != null) {
          final productData = data['data'];
          final basicInfo = productData['basic_info'] ?? {};
          
          // Extrair preços das variações
          String salePrice = '0';
          String originalPrice = '0';
          String rating = '0.0';
          String orders = '0';
          String discount = '0%';
          
          // Verificar se temos variações com preços
          if (productData.containsKey('variations') && productData['variations'] is List) {
            final variations = productData['variations'] as List;
            if (variations.isNotEmpty) {
              final firstVariation = variations.first;
              salePrice = firstVariation['offer_sale_price']?.toString() ?? '0';
              originalPrice = firstVariation['sku_price']?.toString() ?? '0';
              
              // Calcular desconto
              try {
                final double sale = double.parse(salePrice);
                final double original = double.parse(originalPrice);
                if (original > 0 && original > sale) {
                  final double discountValue = ((original - sale) / original) * 100;
                  discount = '${discountValue.toStringAsFixed(0)}%';
                }
              } catch (e) {
                discount = '0%';
              }
            }
          }
          
          // Extrair rating e orders do raw_data
          if (productData.containsKey('raw_data')) {
            final rawData = productData['raw_data'];
            if (rawData.containsKey('ae_item_base_info_dto')) {
              final baseInfo = rawData['ae_item_base_info_dto'];
              rating = baseInfo['avg_evaluation_rating']?.toString() ?? '0.0';
              orders = baseInfo['sales_count']?.toString() ?? '0';
            }
          }
          
          // Criar um produto no formato esperado pelo UI
          final product = {
            'itemId': productId,
            'title': basicInfo['title'] ?? 'Produto sem título',
            'targetSalePrice': salePrice,
            'targetOriginalPrice': originalPrice,
            'itemMainPic': basicInfo['main_image'] ?? '',
            'discount': discount,
            'score': rating,
            'orders': orders,
            'itemUrl': link,
          };
          
          print('🔍 Produto específico encontrado: ${product['title']}');
          
          setState(() {
            _products = [product]; // Exibir apenas o produto específico do link
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Produto específico encontrado!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Produto específico não encontrado';
            _products = [];
            _isLoading = false;
          });
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Erro ${response.statusCode}: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao buscar produto específico: $e');
      setState(() {
        _errorMessage = 'Erro ao buscar produto específico: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _calculateImportTax(String price) {
    try {
      final double priceValue = double.parse(price);
      final double tax = priceValue * 0.60; // 60% de imposto
      return tax.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '🔍 Buscar Produtos AliExpress',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Header com busca
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              children: [
                // Campo de busca unificado
                Container(
            decoration: BoxDecoration(
              color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '🔍 Digite o que você procura ou cole um link do AliExpress...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      IconButton(
                        onPressed: _performSearch,
                        icon: const Icon(Icons.search),
                        color: Colors.grey[600],
                ),
              ],
            ),
          ),
                const SizedBox(height: 8),
                // Texto de ajuda
            Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                    child: Text(
                    '💡 Digite palavras-chave ou cole links do AliExpress',
                      style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Categorias
                if (_categories.isNotEmpty) ...[
                  const Text(
                    '📂 Categorias Populares',
                      style: TextStyle(
                      color: Colors.white,
                        fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory?.id == category.id;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                                category.name,
                                style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                                  fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _searchByCategory(category);
                              } else {
                                setState(() {
                                  _selectedCategory = null;
                                  _products = [];
                                });
                              }
                            },
                            backgroundColor: Colors.white.withOpacity(0.9),
                            selectedColor: Colors.orange,
                            checkmarkColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                ],
              ),
            ),
          // Conteúdo principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Buscando produtos...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
          ),
        ],
      ),
    );
  }

    if (_errorMessage != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Tentar Novamente'),
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
              Icons.search,
            size: 64,
              color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
            const Text(
              'Digite um termo para buscar produtos',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

       return Column(
         children: [
        // Header com informações
        Container(
              padding: const EdgeInsets.all(16),
          child: Row(
          children: [
              Icon(
                Icons.inventory,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 8),
            Text(
                '${_products.length} produtos encontrados',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
            ),
                ],
              ),
            ),
        // Grid de produtos
           Expanded(
          child: _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    // Detectar se é web
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    if (isWeb) {
      // Layout para web com largura máxima de 230px por card
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cardWidth = 230.0;
          final spacing = 16.0;
          final crossAxisCount = (availableWidth / (cardWidth + spacing)).floor();
          final actualCrossAxisCount = crossAxisCount > 0 ? crossAxisCount : 1;
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: actualCrossAxisCount,
              childAspectRatio: 0.75, // Proporção ajustada para web
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProductDetailScreen(product: product),
                    ),
                  );
                },
                child: _buildProductCard(product, isWeb: true),
              );
            },
          );
        },
      );
    } else {
      // Layout original para mobile
      return GridView.builder(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 2,
                 childAspectRatio: 0.40,
                 crossAxisSpacing: 12,
                 mainAxisSpacing: 12,
               ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProductDetailScreen(product: product),
              ),
            );
          },
            child: _buildProductCard(product, isWeb: false),
          );
        },
      );
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product, {required bool isWeb}) {
    final title = product['title'] ?? 'Produto sem título';
           final originalPrice = product['originalPrice'] ?? '0';
           final originalCurrency = product['originalPriceCurrency'] ?? 'USD';
    final targetPrice = product['targetSalePrice'] ?? product['salePrice'] ?? '0';
           final imageUrl = product['itemMainPic'] ?? '';
           final fullImageUrl = imageUrl.isNotEmpty && !imageUrl.startsWith('http') ? 'https:$imageUrl' : imageUrl;
           final discount = product['discount'] ?? '0%';
           final score = product['score'] ?? '0.0';
           final orders = product['orders'] ?? '0';
    final itemId = product['itemId'] ?? '';

    if (isWeb) {
      // Card otimizado para web
      return Container(
        width: 230,
        child: Card(
          margin: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem do produto
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.grey[200],
                ),
                child: fullImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: Image.network(
                          fullImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 24,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
              ),
              // Informações do produto
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nome do produto
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Preços
                      Row(
                        children: [
                          Text(
                            'R\$ $targetPrice',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (originalPrice != '0' && originalPrice != targetPrice) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${originalCurrency == 'USD' ? '\$' : originalCurrency == 'CNY' ? '¥' : originalCurrency} $originalPrice',
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Imposto
                      Row(
                        children: [
                          Icon(Icons.account_balance, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Imposto: R\$ ${_calculateImportTax(targetPrice)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Desconto
                      if (discount != '0%') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            discount,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Avaliação e Pedidos
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            score,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$orders pedidos',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Card original para mobile
    return Card(
              margin: const EdgeInsets.all(4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
        child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                // Imagem do produto
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      color: Colors.grey[200],
                    ),
                    child: fullImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                              fullImageUrl,
                    fit: BoxFit.cover,
                              width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Informações do produto - Uma linha por informação
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                    children: [
                        // Linha 1: Nome do produto
                      Text(
                          title,
                        style: const TextStyle(
                      fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                        const SizedBox(height: 4),
                        // Linha 2: Preços (original e atual)
                      Row(
                        children: [
                          Text(
                              'R\$ $targetPrice',
                              style: const TextStyle(
                          fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (originalPrice != '0' && originalPrice != targetPrice) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${originalCurrency == 'USD' ? '\$' : originalCurrency == 'CNY' ? '¥' : originalCurrency} $originalPrice',
                                style: const TextStyle(
                            fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Linha 3: Imposto de Importação Estimado
                        Row(
                          children: [
                            Icon(Icons.account_balance, size: 12, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Imposto: R\$ ${_calculateImportTax(targetPrice)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Linha 4: Desconto
                        if (discount != '0%') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              discount,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        // Linha 5: Avaliação
                        Row(
                          children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              score,
                              style: const TextStyle(
                          fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Linha 6: Pedidos
                          Text(
                          '$orders pedidos',
                          style: const TextStyle(
                      fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
          ],
                    ),
                  ),
                ],
              ),
            );
         }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mercado da Sophia',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Itens do menu
                Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.search,
                  title: 'Buscar Produtos',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  title: 'Produtos Importados',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/imported-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Gerenciar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/manage-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categorias',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/categories');
                  },
            ),
          ],
                    ),
                  ),
                ],
              ),
            );
         }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
} 