import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart' as banner_model;
import '../services/product_service.dart';
import '../services/banner_service.dart';
import '../widgets/product_card_web.dart';
import '../widgets/friendly_router.dart';

class SexyShopScreen extends StatefulWidget {
  const SexyShopScreen({Key? key}) : super(key: key);

  @override
  _SexyShopScreenState createState() => _SexyShopScreenState();
}

class _SexyShopScreenState extends State<SexyShopScreen> {
  final PageController _bannerController = PageController();
  
  List<Product> _products = []; // Todos os produtos
  List<Product> _filteredProducts = []; // Produtos filtrados (todos)
  List<Product> _displayedProducts = []; // Produtos exibidos na tela (paginação)
  List<banner_model.Banner> _banners = [];
  List<String> _categories = ['Todos'];
  String _selectedCategory = 'Todos';
  
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _productsPerPage = 20;
  
  int _currentBannerIndex = 0;
  String? _error;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSexyShopProducts(reset: true),
      _loadBanners(),
    ]);
  }

  Future<void> _loadSexyShopProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreProducts = true;
        _displayedProducts.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      // Buscar produtos da seção SexyShop usando ProductService
      final loadedProducts = await ProductService.getSexyShopProducts();
      
      // Se for reset, salvar todos os produtos e extrair categorias
      if (reset) {
        _products = loadedProducts;
        
        final Set<String> uniqueCategories = {};
        for (final product in loadedProducts) {
          if (product.categoria.isNotEmpty) {
            uniqueCategories.add(product.categoria);
        }
      }
      
      setState(() {
          _categories = ['Todos', ...uniqueCategories.toList()..sort()];
          _isLoadingCategories = false;
        });
      }
      
      // Aplicar filtro como na home
      _filterProducts();
      
      // Calcular quantos produtos já foram mostrados
      final currentCount = _displayedProducts.length;
      final nextCount = currentCount + _productsPerPage;
      
      // Pegar apenas os próximos produtos
      final productsToShow = _filteredProducts.sublist(
        currentCount, 
        nextCount > _filteredProducts.length ? _filteredProducts.length : nextCount
      );
      
      setState(() {
        if (reset) {
          _displayedProducts = productsToShow;
          _currentPage = 1;
        } else {
          _displayedProducts.addAll(productsToShow);
          _currentPage++;
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMoreProducts = _displayedProducts.length < _filteredProducts.length;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar produtos. Tente novamente.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await BannerService().getBannersBySection('SexyShop');
      setState(() {
        _banners = banners;
      });
    } catch (e) {
      setState(() {
        _banners = [];
      });
    }
  }



  void _loadMoreProducts() {
    if (!_isLoadingMore && _hasMoreProducts) {
      _loadSexyShopProducts();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _filterProducts() {
    List<Product> filtered = List.from(_products);
    
    // Filtrar por categoria
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((product) => 
      product.categoria.toLowerCase().contains(_selectedCategory.toLowerCase())
    ).toList();
    }
    
    // Filtrar por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) => 
        product.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.descricao.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    _filteredProducts = filtered;
  }

  List<Product> _getFilteredProducts() {
    return _displayedProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fundo escuro
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Stack(
                children: [
                  // Título SexyShop centralizado
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'SexyShop',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  
                  // Row com elementos nas laterais
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão voltar + nome da loja
                      GestureDetector(
                        onTap: () => context.go('/produtos'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => context.go('/produtos'),
                            ),
                            const Text(
                              'Mercado da Sophia',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Carrinho
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () {
                          context.go('/carrinho');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header expandido com gradiente e slide de banners
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              height: 500,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
              children: [
                // Slide de banners
                Positioned.fill(
                  child: _banners.isNotEmpty
                      ? PageView.builder(
                          controller: _bannerController,
                          itemCount: _banners.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentBannerIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildFirebaseBanner(_banners[index]);
                          },
                        )
                      : PageView.builder(
                          controller: _bannerController,
                          itemCount: 3, // banners padrão
                          onPageChanged: (index) {
                            setState(() {
                              _currentBannerIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildSexyShopBanner(index);
                          },
                        ),
                ),
                
                // Conteúdo do header sobreposto
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Produtos Especiais para Casais',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '18+ Conteúdo Adulto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Indicadores de página
                if (_banners.isNotEmpty || _currentBannerIndex < 3)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _banners.isNotEmpty ? _banners.length : 3, 
                        (index) {
                        return GestureDetector(
                          onTap: () {
                            _bannerController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentBannerIndex 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                
                // Setas de navegação no canto inferior direito
                if (_banners.isNotEmpty || _currentBannerIndex < 3)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Row(
                    children: [
                      // Seta esquerda
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.black87,
                            size: 24,
                          ),
                          onPressed: () {
                            final maxIndex = _banners.isNotEmpty ? _banners.length - 1 : 2;
                            if (_currentBannerIndex > 0) {
                              _bannerController.animateToPage(
                                _currentBannerIndex - 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Seta direita
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.black87,
                            size: 24,
                          ),
                          onPressed: () {
                            final maxIndex = _banners.isNotEmpty ? _banners.length - 1 : 2;
                            if (_currentBannerIndex < maxIndex) {
                              _bannerController.animateToPage(
                                _currentBannerIndex + 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
          
          // Categorias - SliverPersistentHeader para ficar fixo após rolar
                  SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chips de categoria
                          Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 1200), // 80% de 1500px
                        child: _isLoadingCategories
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6B9D),
                                ),
                              )
                            : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(
                                          category.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF6B9D),
                        backgroundColor: Colors.grey[800],
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                                            _currentPage = 1;
                                            _hasMoreProducts = true;
                          });
                                          // Recarregar produtos com a nova categoria
                                          _loadSexyShopProducts(reset: true);
                        },
                      ),
                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                ),
              ),

                  // Barra de busca
            Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: Container(
                        width: 1185, // 79% de 1500px
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _currentPage = 1;
                              _hasMoreProducts = true;
                            });
                            _loadSexyShopProducts(reset: true);
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Buscar produtos...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B9D)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFFFF6B9D)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _currentPage = 1;
                                        _hasMoreProducts = true;
                                      });
                                      _loadSexyShopProducts(reset: true);
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // Lista de produtos - CONTEÚDO FIXO COM LARGURA MÁXIMA DE 80%
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200), // 80% de 1500px
                  child: _buildProductsContent(),
                ),
                              ),
                            ),
          ),

          // Rodapé
          SliverToBoxAdapter(
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
            ),
            child: Column(
              children: [
                // Informações de contato
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFooterItem(
                      icon: Icons.location_on,
                      title: 'Endereço',
                      subtitle: 'Zona Central de São Paulo\nRepública, São Paulo - SP, 01037-010',
                    ),
                    _buildFooterItem(
                      icon: Icons.phone,
                      title: 'WhatsApp',
                      subtitle: '85 997640050\n85 991112002',
                    ),
                    _buildFooterItem(
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: 'contato@mercadodasophia.com.br',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Linha divisória
                Container(
                  height: 1,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 20),
                
                // Links úteis
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFooterLink('Quem Somos', () {}),
                    _buildFooterLink('Nossa História', () {}),
                    _buildFooterLink('Política de Privacidade', () {}),
                    _buildFooterLink('Termos de Uso', () {}),
                    _buildFooterLink('Contato', () {}),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Copyright
                Text(
                  '© 2024 Mercado da Sophia. Todos os direitos reservados.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B9D),
        ),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _loadSexyShopProducts(reset: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _getFilteredProducts();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ProductCardWeb(
                  product: product,
                  onTap: () {
                    FriendlyNavigator.pushProduct(context, product);
                  },
                ),
              );
            },
          ),
        ),
        if (_hasMoreProducts || _isLoadingMore)
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isLoadingMore
                  ? const Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF6B9D)),
                        SizedBox(height: 8),
                        Text('Carregando mais produtos...', style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 14)),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _loadMoreProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B9D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Carregar Mais Produtos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Text('Mostrando ${_displayedProducts.length} de ${_filteredProducts.length} produtos', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                if (_hasMoreProducts)
                  Text('Página $_currentPage', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6B9D),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // Método para construir banners do Firebase
  Widget _buildFirebaseBanner(banner_model.Banner banner) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Imagem do banner
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: banner.image,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                memCacheHeight: 600,
                maxWidthDiskCache: 1200,
                maxHeightDiskCache: 600,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                    child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
              ),
            ),
            
            // Overlay gradiente
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Conteúdo do banner
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (banner.linkProduto != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Ver Produto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir banners padrão
  Widget _buildSexyShopBanner(int index) {
    final bannerData = <Map<String, dynamic>>[
      {
        'title': 'FANTASIAS',
        'subtitle': 'Para Casais',
        'description': 'Explore novos horizontes de prazer',
        'icon': Icons.favorite,
        'gradient': <Color>[Color(0xFFFF6B9D), Color(0xFFFF8E53)],
      },
      {
        'title': 'LINGERIE',
        'subtitle': 'Sensual',
        'description': 'Desperte sua sensualidade',
        'icon': Icons.diamond,
        'gradient': <Color>[Color(0xFF9C27B0), Color(0xFFE91E63)],
      },
      {
        'title': 'BRINQUEDOS',
        'subtitle': 'Para Casais',
        'description': 'Explore novos horizontes de prazer',
        'icon': Icons.star,
        'gradient': <Color>[Color(0xFFAB47BC), Color(0xFF8E24AA)],
      },
    ];

    final data = bannerData[index];

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Conteúdo principal
          Positioned(
            left: 30,
            top: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] as String,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['description'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ícone decorativo
          Positioned(
            right: 30,
            bottom: 30,
            child: Icon(
              data['icon'] as IconData,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// Classe para o SliverPersistentHeader das categorias
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({required this.child});

  @override
  double get minExtent => 124.0;

  @override
  double get maxExtent => 124.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}



