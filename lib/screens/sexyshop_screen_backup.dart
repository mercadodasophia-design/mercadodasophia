import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart' as banner_model;
import '../services/product_service.dart';
import '../services/banner_service.dart';
import '../services/category_service.dart';
import '../widgets/product_card_web.dart';

class SexyShopScreen extends StatefulWidget {
  const SexyShopScreen({super.key});

  @override
  State<SexyShopScreen> createState() => _SexyShopScreenState();
}

class _SexyShopScreenState extends State<SexyShopScreen> {
  final BannerService _bannerService = BannerService();
  final CategoryService _categoryService = CategoryService();
  final PageController _bannerController = PageController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<banner_model.Banner> _banners = [];
  List<String> _categories = ['Todos'];
  bool _isLoading = true;
  bool _isLoadingBanners = true;
  bool _isLoadingCategories = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  String? _error;
  String _selectedCategory = 'Todos';
  int _currentBannerIndex = 0;
  int _currentPage = 1;
  static const int _productsPerPage = 20;

  // Categorias padrão caso não haja no Firebase
  final List<String> _defaultCategories = [
    'Todos',
  ];

  @override
  void initState() {
    super.initState();
    _loadSexyShopProducts();
    _loadSexyShopBanners();
    
    // Adicionar listener para detectar quando chegar ao final da lista
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSexyShopProducts({bool reset = true}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMoreProducts = true;
        });
      } else {
        setState(() {
          _isLoadingMore = true;
          _currentPage++;
        });
      }

      // Simular delay para mostrar loading
      await Future.delayed(const Duration(milliseconds: 500));

      // Buscar produtos da seção SexyShop usando ProductService
      final allProducts = await ProductService.getSexyShopProducts();
      
      // Simular paginação - pegar apenas uma parte dos produtos
      final startIndex = reset ? 0 : (_currentPage - 1) * _productsPerPage;
      final endIndex = startIndex + _productsPerPage;
      final products = allProducts.sublist(
        startIndex, 
        endIndex > allProducts.length ? allProducts.length : endIndex
      );
      
      setState(() {
        if (reset) {
          _products = products;
          _isLoading = false;
        } else {
          _products.addAll(products);
          _isLoadingMore = false;
        }
        
        // Verificar se há mais produtos para carregar
        _hasMoreProducts = endIndex < allProducts.length;
      });
      
      // Carregar categorias baseadas nos produtos (igual à home)
      if (reset) {
        _loadSexyShopCategories();
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar produtos. Tente novamente.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadSexyShopBanners() async {
    try {
      setState(() {
        _isLoadingBanners = true;
      });

      // Buscar banners da seção SexyShop
      final banners = await _bannerService.getSexyShopBanners();
      
      setState(() {
        _banners = banners;
        _isLoadingBanners = false;
      });
    } catch (e) {
      setState(() {
        _banners = [];
        _isLoadingBanners = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;
    
    await _loadSexyShopProducts(reset: false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadSexyShopCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      // Extrair categorias dos produtos carregados (igual à home)
      final categories = <String>{};
      for (var product in _products) {
        if (product.categoria.isNotEmpty) {
          categories.add(product.categoria);
        }
      }

      setState(() {
        if (categories.isNotEmpty) {
          _categories = ['Todos', ...categories.toList()..sort()];
        } else {
          _categories = ['Todos']; // Apenas "Todos" se não houver categorias
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categories = ['Todos']; // Apenas "Todos" em caso de erro
        _isLoadingCategories = false;
      });
    }
  }

  List<Product> _getFilteredProducts() {
    if (_selectedCategory == 'Todos') {
      return _products;
    }
    return _products.where((product) => 
      product.categoria.toLowerCase().contains(_selectedCategory.toLowerCase())
    ).toList();
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
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/products', 
                          (route) => false,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, 
                                '/products', 
                                (route) => false,
                              ),
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
                          Navigator.pushNamed(context, '/cart');
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
            body: ListView(
              controller: _scrollController,
              children: [
                                                  // Header expandido com gradiente e slide de banners
                Container(
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
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFF1A1A1A),
                      child: _isLoadingCategories
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF6B9D),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected = _selectedCategory == category;
                                
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: FilterChip(
                                    label: Text(
                                      category,
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
                              },
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
                    ],
                  ),
                ),
              ],
            ),
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
              child: Image.network(
                banner.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFFF6B9D),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Overlay gradiente para melhorar legibilidade do texto
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
              bottom: 30,
              left: 30,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.nome,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
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

  // Método para construir o conteúdo dos produtos
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
              color: Colors.grey[400],
              size: 64,
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
              onPressed: () => _loadSexyShopProducts(reset: true),
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
    
    if (_getFilteredProducts().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente selecionar outra categoria',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Grid de produtos com paginação
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 5 produtos por linha
              childAspectRatio: 0.75, // Proporção do card
              crossAxisSpacing: 16, // Espaçamento horizontal
              mainAxisSpacing: 16, // Espaçamento vertical
            ),
            itemCount: _getFilteredProducts().length,
            itemBuilder: (context, index) {
              final product = _getFilteredProducts()[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ProductCardWeb(
                  product: product,
                  onTap: () {
                    // Navegar para detalhes do produto
                    Navigator.pushNamed(
                      context,
                      '/product_detail',
                      arguments: {'product': product},
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        // Botão "Carregar Mais" ou indicador de loading
        if (_hasMoreProducts || _isLoadingMore)
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isLoadingMore
                  ? const Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFFFF6B9D),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Carregando mais produtos...',
                          style: TextStyle(
                            color: Color(0xFFFF6B9D),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _loadMoreProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B9D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        'Carregar Mais Produtos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
            ),
          ),
        
        // Indicador de produtos carregados
        Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Text(
                  'Mostrando ${_getFilteredProducts().length} produtos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_hasMoreProducts)
                  Text(
                    'Página $_currentPage',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Método para construir os banners padrão do SexyShop
  Widget _buildSexyShopBanner(int index) {
    List<Map<String, dynamic>> bannerData = [
      {
        'title': 'LINGERIE',
        'subtitle': 'Coleção Exclusiva',
        'description': 'Descubra peças únicas para momentos especiais',
        'icon': Icons.favorite,
        'gradient': [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
      },
      {
        'title': 'BRINQUEDOS',
        'subtitle': 'Para Casais',
        'description': 'Explore novos horizontes de prazer',
        'icon': Icons.star,
        'gradient': [Color(0xFFAB47BC), Color(0xFF8E24AA)],
      },
      {
        'title': 'COSMÉTICOS',
        'subtitle': 'Cuidados Especiais',
        'description': 'Produtos para sua intimidade',
        'icon': Icons.spa,
        'gradient': [Color(0xFF42A5F5), Color(0xFF1E88E5)],
      },
    ];

    var data = bannerData[index];

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data['gradient'],
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
                  data['title'],
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
                  data['subtitle'],
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
                    data['description'],
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
  double get minExtent => 60.0;

  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}



