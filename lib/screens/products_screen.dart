import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';

import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/banner_service.dart';
import '../models/banner_model.dart' as banner_model;

import '../providers/location_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_compact.dart';
import '../widgets/product_card_v2.dart';
import '../widgets/product_card_web.dart';

import '../widgets/cart_badge.dart';
import '../widgets/friendly_router.dart';
import '../theme/app_theme.dart';


import 'my_orders_screen.dart';
import 'favorites_screen.dart';
import 'offers_screen.dart';
import 'coupons_screen.dart';
import 'my_account_screen.dart';
import 'about_us_screen.dart';
import 'our_history_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';
import 'contact_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearch;
  
  const ProductsScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  String? selectedCategory;
  List<Product> filteredProducts = [];
  bool isLoading = true;
  List<String> categories = [];
  
  // Controle do banner promocional
  int _currentBannerIndex = 0;
  List<banner_model.Banner> _banners = [];
  bool _isLoadingBanners = true;
  late PageController _pageController;
  Timer? _bannerTimer;
  


  @override
  void initState() {
    super.initState();
    
    // Definir categoria inicial se fornecida
    if (widget.initialCategory != null) {
      selectedCategory = widget.initialCategory;
    }
    
    // TODO: Implementar busca inicial
    // if (widget.initialSearch != null) {
    //   _searchQuery = widget.initialSearch;
    // }
    
    _pageController = PageController();
    _loadProducts();
    _loadCategories();
    _loadBanners();
    _initializeLocation();
    _loadSavedAddress();
  }

  Future<void> _initializeLocation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.initializeLocation();
  }

  Future<void> _loadSavedAddress() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      await locationProvider.loadSavedAddressWithAuth(authService);
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final loadedProducts = await ProductService.getProducts();
      setState(() {
        products = loadedProducts;
        _filterProducts();
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await ProductService.getCategories();
      setState(() {
        categories = ['Todos', ...loadedCategories];
      });
    } catch (e) {
      print('Erro ao carregar categorias: $e');
      setState(() {
        categories = ['Todos'];
      });
    }
  }

  Future<void> _loadBanners() async {
    try {
      setState(() {
        _isLoadingBanners = true;
      });

      final bannerService = BannerService();
      final banners = await bannerService.getLojaBanners();
      
      setState(() {
        _banners = banners;
        _isLoadingBanners = false;
      });
      
      // Iniciar timer automático se há mais de 1 banner
      if (_banners.length > 1) {
        _startBannerTimer();
      }
    } catch (e) {
      print('Erro ao carregar banners: $e');
      setState(() {
        _banners = [];
        _isLoadingBanners = false;
      });
    }
  }

  void _startBannerTimer() {
    _stopBannerTimer(); // Parar timer anterior se existir
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_banners.length > 1) {
        final nextIndex = (_currentBannerIndex + 1) % _banners.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
  }

  void _resetBannerTimer() {
    _stopBannerTimer();
    if (_banners.length > 1) {
      _startBannerTimer();
    }
  }



  void _filterProducts() {
    if (selectedCategory == null || selectedCategory == 'Todos') {
      filteredProducts = products;
    } else {
      filteredProducts = products.where((product) => product.categoria == selectedCategory).toList();
    }
  }

  @override
  void dispose() {
    _stopBannerTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
                     // Header ocupando toda a largura com altura limitada a 20%
           Container(
             width: double.infinity,
                           height: MediaQuery.of(context).size.height * 0.1, // 30% da altura da tela
             decoration: const BoxDecoration(
               gradient: AppTheme.primaryGradient,
             ),
                                                   child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Row(
                  children: [
                    // Ícone Menu Hamburger
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        _showMenu();
                      },
                      tooltip: 'Menu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    
                    // Botão Debug (apenas em desenvolvimento)
                    if (kDebugMode)
                      IconButton(
                        icon: const Icon(Icons.bug_report, color: Colors.white),
                        onPressed: () async {
                          final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                          // DebugHelper removido
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Testes de debug executados! Verifique o console.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Debug',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    
                                                                    // Logo em imagem
                                                                    Image.asset(
                                                                      'assets/images/system/logo/name-logo-web.png',
                                                                      width: 200,
                                                                      height: 60,
                                                                      fit: BoxFit.contain,
                                                                    ),
                    
                    // Espaçamento flexível para empurrar os itens para a direita
                    const Spacer(),
                    
                    // SexyShop (primeiro item no lado direito)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            context.go('/sexyshop');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'SexyShop',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '18+',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Ícone Minha Conta
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () {
                        context.go('/minha-conta');
                      },
                      tooltip: 'Minha Conta',
                    ),
                    
                    // Atendimento
                    TextButton.icon(
                      onPressed: () {
                        context.go('/contato');
                      },
                      icon: const Icon(Icons.headset_mic, color: Colors.white, size: 20),
                      label: const Text(
                        'Atendimento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    
                    // Carrinho
                                CartBadge(
              onTap: () {
                context.go('/carrinho');
              },
              size: 24,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
                  ],
                ),
              ),
            ),
          
          // Conteúdo principal com rodapé rolável
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Banner promocional
                  _buildPromoBanner(),
                  
                  const SizedBox(height: 24),
                  
                  // Layout condicional para seção de categorias
                  kIsWeb 
                    ? _buildWebCategoriesSection()
                    : _buildMobileCategoriesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Grid de produtos locais
                  if (isLoading)
                    kIsWeb 
                      ? _buildWebLoadingSection()
                      : const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                  else if (filteredProducts.isEmpty)
                    kIsWeb 
                      ? _buildWebEmptySection()
                      : const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum produto encontrado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                  else
                    // Layout condicional por plataforma
                    kIsWeb 
                      ? _buildWebLayout(filteredProducts)
                      : _buildMobileLayout(filteredProducts),
                  
                  // Espaçamento antes do rodapé
                  const SizedBox(height: 60),
                  
                  // Rodapé rolável
                  kIsWeb 
                    ? _buildWebFooter()
                    : _buildMobileFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

     Widget _buildFilterChip(String label, bool isSelected) {
     return FilterChip(
       label: Text(label),
       selected: isSelected,
       onSelected: (selected) {
         setState(() {
           if (selected) {
             selectedCategory = label;
           } else {
             selectedCategory = null;
           }
           _filterProducts();
         });
       },
     );
   }

       // Seção de categorias específica para Web - 80% de largura com background branco
    Widget _buildWebCategoriesSection() {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
          color: Colors.white, // Background branco
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                
                // Filtros de categoria
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(category, selectedCategory == category),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

       // Seção de loading específica para Web - 80% de largura com background branco
    Widget _buildWebLoadingSection() {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
          color: Colors.white, // Background branco
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    // Seção de produtos vazios específica para Web - 80% de largura com background branco
    Widget _buildWebEmptySection() {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
          color: Colors.white, // Background branco
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum produto encontrado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Seção de categorias específica para Mobile - largura total
    Widget _buildMobileCategoriesSection() {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       child: Column(
         children: [
           
           // Filtros de categoria
           SingleChildScrollView(
             scrollDirection: Axis.horizontal,
             child: Row(
               children: categories.map((category) {
                 return Padding(
                   padding: const EdgeInsets.only(right: 8),
                   child: _buildFilterChip(category, selectedCategory == category),
                 );
               }).toList(),
             ),
           ),
         ],
       ),
     );
   }

     // Layout específico para Web - 80% de largura com background branco
   Widget _buildWebLayout(List<Product> products) {
     return Center(
       child: Container(
         width: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
         color: Colors.white, // Background branco no body dos produtos
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // Grid de produtos com largura fixa de 230px alinhado à esquerda
               Wrap(
                 spacing: 16,
                 runSpacing: 16,
                 alignment: WrapAlignment.start,
                 crossAxisAlignment: WrapCrossAlignment.start,
                 children: products.map((product) {
                   return SizedBox(
                     width: 230, // Largura fixa de 230px para cada card
                     child: ProductCardWeb(
                       product: product,
                       onTap: () => _showProductDetails(product),
                     ),
                   );
                 }).toList(),
               ),
             ],
           ),
         ),
       ),
     );
   }

  // Layout específico para Mobile - 2 colunas responsivas
  Widget _buildMobileLayout(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: products.map((product) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 34) / 2,
            child: ProductCardV2(
              product: product,
              onTap: () => _showProductDetails(product),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooterCategory(String label) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selectedCategory == label
              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            setState(() {
              selectedCategory = selectedCategory == label ? null : label;
              _loadProducts();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selectedCategory == label ? Colors.white : const Color(0xFF2D3748),
                fontSize: 14,
                fontWeight: selectedCategory == label ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

     Widget _buildFooterContact(IconData icon, String text) {
     return Row(
       children: [
         Icon(icon, color: Colors.black87, size: 20),
         const SizedBox(width: 8),
         Text(
           text,
           style: const TextStyle(
             fontSize: 14,
             color: Colors.black87,
           ),
         ),
       ],
     );
   }

  // Mapear categorias para ícones
  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('eletrônic') || categoryLower.contains('smartphone') || categoryLower.contains('computador')) {
      return Icons.devices;
    } else if (categoryLower.contains('roupa') || categoryLower.contains('vestuário')) {
      return Icons.checkroom;
    } else if (categoryLower.contains('casa') || categoryLower.contains('jardim') || categoryLower.contains('cozinha')) {
      return Icons.home;
    } else if (categoryLower.contains('automóvel') || categoryLower.contains('carro')) {
      return Icons.directions_car;
    } else if (categoryLower.contains('esporte')) {
      return Icons.sports_soccer;
    } else if (categoryLower.contains('brinquedo')) {
      return Icons.toys;
    } else if (categoryLower.contains('beleza')) {
      return Icons.face;
    } else if (categoryLower.contains('livro')) {
      return Icons.book;
    } else if (categoryLower.contains('ferramenta')) {
      return Icons.build;
    } else if (categoryLower.contains('garrafa') || categoryLower.contains('bebida')) {
      return Icons.local_drink;
    } else if (categoryLower.contains('comida') || categoryLower.contains('alimento')) {
      return Icons.restaurant;
    } else if (categoryLower.contains('saúde') || categoryLower.contains('medicamento')) {
      return Icons.medical_services;
    } else if (categoryLower.contains('jogo') || categoryLower.contains('game')) {
      return Icons.games;
    } else if (categoryLower.contains('música') || categoryLower.contains('instrumento')) {
      return Icons.music_note;
    } else if (categoryLower.contains('arte') || categoryLower.contains('decoração')) {
      return Icons.palette;
    } else {
      return Icons.category; // Ícone padrão
    }
  }

    // Rodapé específico para Web - 80% de largura com design moderno
    Widget _buildWebFooter() {
      return Container(
        color: Colors.white, // Fundo branco para todo o rodapé
        width: double.infinity, // Largura total
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
            color: Colors.white, // Fundo branco adicional
            child: Column(
              children: [
                // Seção superior (design moderno) - 80% de largura
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white, // Fundo branco sólido
                  child: Column(
                    children: [
                      const Text(
                        'Nossas Categorias',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 12,
                        runSpacing: 12,
                        children: categories
                            .where((category) => category != 'Todos') // Excluir "Todos"
                            .take(8) // Limitar a 8 categorias para não sobrecarregar
                            .map((category) => _buildFooterCategory(category))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                
                // Seção inferior (design moderno) - 80% de largura
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white, // Fundo branco sólido
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                                                  const Text(
                          'Mercado da Sophia',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Zona Central de São Paulo • República, São Paulo - SP, 01037-010',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterContact(Icons.phone, '(85) 99764-0050'),
                              const SizedBox(width: 24),
                              _buildFooterContact(Icons.email, 'contato@mercadodasophia.com'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterContact(Icons.phone_android, '(85) 99764-0050'),
                              const SizedBox(width: 24),
                              _buildFooterContact(Icons.phone_android, '(85) 99111-2002'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '© 2024 Mercado da Sophia. Todos os direitos reservados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

   // Rodapé específico para Mobile - largura total
   Widget _buildMobileFooter() {
     return Container(
       color: Colors.white,
       child: Column(
         children: [
           // Seção superior (branco)
           Container(
             padding: const EdgeInsets.all(20),
             color: Colors.white,
             child: Column(
               children: [
                 const Text(
                   'Categorias',
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: Colors.black,
                   ),
                 ),
                 const SizedBox(height: 16),
                 Wrap(
                   alignment: WrapAlignment.spaceEvenly,
                   spacing: 16,
                   runSpacing: 16,
                   children: categories
                       .where((category) => category != 'Todos') // Excluir "Todos"
                       .take(6) // Limitar a 6 categorias para mobile
                       .map((category) => _buildFooterCategory(category))
                       .toList(),
                 ),
               ],
             ),
           ),
           
           // Seção inferior (preta)
           Container(
             padding: const EdgeInsets.all(20),
             color: Colors.black,
             child: Column(
               children: [
                 const Text(
                   'Mercado da Sophia',
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                   ),
                 ),
                 const SizedBox(height: 8),
                 const Text(
                   'Zona Central de São Paulo',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.white70,
                   ),
                 ),
                 const Text(
                   'República, São Paulo - SP, 01037-010',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.white70,
                   ),
                 ),
                 const SizedBox(height: 16),
                 Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         _buildFooterContact(Icons.phone, '(85) 99764-0050'),
                         const SizedBox(width: 16),
                         _buildFooterContact(Icons.email, 'contato@mercadodasophia.com'),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         _buildFooterContact(Icons.phone_android, '(85) 99764-0050'),
                         const SizedBox(width: 16),
                         _buildFooterContact(Icons.phone_android, '(85) 99111-2002'),
                       ],
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   '© 2024 Mercado da Sophia. Todos os direitos reservados.',
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.white54,
                   ),
                   textAlign: TextAlign.center,
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

  void _showMenu() {
    if (kIsWeb) {
      // Drawer lateral para Web - abre da esquerda para a direita
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Row(
            children: [
              // Drawer lateral
              Container(
                width: 350,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header do drawer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mercado da Sophia',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Bem-vindo à nossa loja',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botão fechar
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    // Conteúdo do drawer
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [

                            
                            // Seção de Login
                            Consumer<AuthService>(
                              builder: (context, authService, child) {
                                if (authService.isLoggedIn) {
                                  // Usuário logado - mostrar informações do usuário
                                  return _buildDrawerSection(
                                    'Minha Conta',
                                    [
                                      _buildDrawerItem(
                                        authService.currentUser?.displayName ?? 'Usuário',
                                        Icons.person,
                                        () {
                                          Navigator.pop(context);
                                          context.go('/minha-conta');
                                        },
                                      ),
                                      _buildDrawerItem('Minhas Compras', Icons.shopping_bag, () {
                                        Navigator.pop(context);
                                        context.go('/meus-pedidos');
                                      }),
                                      _buildDrawerItem('Favoritos', Icons.favorite, () {
                                        Navigator.pop(context);
                                        context.go('/favoritos');
                                      }),
                                      _buildDrawerItem('Ofertas', Icons.local_offer, () {
                                        Navigator.pop(context);
                                        context.go('/ofertas');
                                      }),
                                      _buildDrawerItem('Cupons', Icons.card_giftcard, () {
                                        Navigator.pop(context);
                                        context.go('/cupons');
                                      }),
                                      _buildDrawerItem('Minha Conta', Icons.person, () {
                                        Navigator.pop(context);
                                        context.go('/minha-conta');
                                      }),
                                    ],
                                  );
                                } else {
                                  // Usuário não logado - mostrar opções de login
                                  return _buildDrawerSection(
                                    'Entrar / Cadastrar',
                                    [
                                      _buildDrawerItem('Entrar / Cadastrar', Icons.login, () {
                                        Navigator.pop(context);
                                        context.go('/login');
                                      }),
                                    ],
                                  );
                                }
                              },
                            ),
                            
                            const Divider(height: 30),
                            
                            // Seção SexyShop - Destaque Especial
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go('/sexyshop');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.favorite,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'SexyShop',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Realce seus desejos, descubra prazeres\ne viva experiências sem tabus.',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 11,
                                                  height: 1.2,
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            '18+',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const Divider(height: 30),
                            
                            // Seção de Categorias
                            _buildDrawerSection(
                              'Categorias de Produtos',
                              categories
                                  .where((category) => category != 'Todos')
                                  .take(10) // Limitar a 10 categorias no drawer
                                  .map((category) => _buildDrawerItem(
                                        category,
                                        _getCategoryIcon(category),
                                        () {
                                          setState(() {
                                            selectedCategory = category;
                                            _filterProducts();
                                          });
                                          Navigator.pop(context);
                                        },
                                      ))
                                  .toList(),
                            ),
                            
                            const Divider(height: 30),
                            
                            // Seção Sobre
                            _buildDrawerSection(
                              'Sobre Mercado Da Sophia',
                              [
                                _buildDrawerItem('Quem Somos', Icons.info, () {
                                  Navigator.pop(context);
                                  context.go('/sobre-nos');
                                }),
                                _buildDrawerItem('Nossa História', Icons.history, () {
                                  Navigator.pop(context);
                                  context.go('/nossa-historia');
                                }),
                                _buildDrawerItem('Política de Privacidade', Icons.privacy_tip, () {
                                  Navigator.pop(context);
                                  context.go('/politica-privacidade');
                                }),
                                _buildDrawerItem('Termos de Uso', Icons.description, () {
                                  Navigator.pop(context);
                                  context.go('/termos-uso');
                                }),
                                _buildDrawerItem('Contato', Icons.contact_support, () {
                                  Navigator.pop(context);
                                  context.go('/contato');
                                }),
                              ],
                            ),
                            
                            // Botão de Logout (apenas se estiver logado)
                            Consumer<AuthService>(
                              builder: (context, authService, child) {
                                if (!authService.isLoggedIn) return const SizedBox.shrink();
                                
                                return Column(
                                  children: [
                                    const Divider(height: 30),
                                    _buildDrawerItem('Sair da Conta', Icons.logout, () async {
                                      try {
                                        await authService.signOut();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Logout realizado com sucesso!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erro ao fazer logout: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }),
                                  ],
                                );
                              },
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Área escura para fechar o drawer
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Modal bottom sheet para Mobile (comportamento original)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header do drawer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mercado da Sophia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bem-vindo à nossa loja',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo do drawer
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Seção de Localização
                      Consumer<LocationProvider>(
                        builder: (context, locationProvider, child) {
                          return _buildDrawerSection(
                            'Localização',
                            [
                              _buildDrawerItem(
                                locationProvider.hasLocation 
                                  ? locationProvider.getFormattedAddress()
                                  : 'Obtendo localização...',
                                Icons.location_on,
                                () async {
                                  if (locationProvider.hasLocation) {
                                    // Se o endereço atual é apenas coordenadas, tentar obter endereço real
                                    if (locationProvider.getFormattedAddress().contains('Localização:')) {
                                      await locationProvider.refreshAddress();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Endereço atualizado: ${locationProvider.getFormattedAddress()}'),
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Localização: ${locationProvider.getFormattedAddress()}'),
                                          backgroundColor: AppTheme.primaryColor,
                                        ),
                                      );
                                    }
                                  } else {
                                    await locationProvider.getCurrentLocation();
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const Divider(height: 30),
                      
                      // Seção de login removida - não há mais login obrigatório
                      
                      const Divider(height: 30),
                      
                      // Seção de Navegação Principal
                      _buildDrawerSection(
                        'Navegação',
                        [
                          _buildDrawerItem('Início', Icons.home, () {
                            Navigator.of(context).pop();
                          }),
                          _buildDrawerItem('Minhas Compras', Icons.shopping_bag, () {
                            Navigator.pop(context);
                            context.go('/meus-pedidos');
                          }),
                          _buildDrawerItem('Favoritos', Icons.favorite, () {
                            Navigator.pop(context);
                            context.go('/favoritos');
                          }),
                          _buildDrawerItem('Ofertas', Icons.local_offer, () {
                            Navigator.pop(context);
                            context.go('/ofertas');
                          }),
                          _buildDrawerItem('Cupons', Icons.card_giftcard, () {
                            Navigator.pop(context);
                            context.go('/cupons');
                          }),
                          _buildDrawerItem('Minha Conta', Icons.person, () {
                            Navigator.pop(context);
                            context.go('/minha-conta');
                          }),
                        ],
                      ),
                      
                      const Divider(height: 30),
                      
                      // Seção de Categorias
                      _buildDrawerSection(
                        'Categorias de Produtos',
                        categories
                            .where((category) => category != 'Todos')
                            .take(10) // Limitar a 10 categorias no drawer
                            .map((category) => _buildDrawerItem(
                                  category,
                                  _getCategoryIcon(category),
                                  () {
                                    setState(() {
                                      selectedCategory = category;
                                      _filterProducts();
                                    });
                                    Navigator.pop(context);
                                  },
                                ))
                            .toList(),
                      ),
                      
                      const Divider(height: 30),
                      
                      // Seção Sobre
                      _buildDrawerSection(
                        'Sobre Mercado Da Sophia',
                        [
                          _buildDrawerItem('Quem Somos', Icons.info, () {
                            Navigator.pop(context);
                            context.go('/sobre-nos');
                          }),
                          _buildDrawerItem('Nossa História', Icons.history, () {
                            Navigator.pop(context);
                            context.go('/nossa-historia');
                          }),
                          _buildDrawerItem('Política de Privacidade', Icons.privacy_tip, () {
                            Navigator.pop(context);
                            context.go('/politica-privacidade');
                          }),
                          _buildDrawerItem('Termos de Uso', Icons.description, () {
                            Navigator.pop(context);
                            context.go('/termos-uso');
                          }),
                          _buildDrawerItem('Contato', Icons.contact_support, () {
                            Navigator.pop(context);
                            context.go('/contato');
                          }),
                        ],
                      ),
                      
                      // Seção de logout removida - não há mais login obrigatório
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildUserProfileItem(String userName) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        userName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: const Text(
        'Editar Perfil',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.edit,
        color: AppTheme.primaryColor,
        size: 20,
      ),
      onTap: () {
        Navigator.pop(context);
        context.go('/minha-conta');
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showProductDetails(Product product) {
    // Usar URLs amigáveis
    FriendlyNavigator.pushProduct(context, product);
  }

  // Widget para logo personalizado
  Widget _buildCustomLogo() {
    return Container(
      height: 60, // Altura fixa para evitar overflow
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // "MERCADO" - Fonte sans-serif maiúscula com contorno
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'MERCADO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.5,
                fontFamily: 'Arial',
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Elemento gráfico de explosão/raios
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Raios superiores (rosa)
              Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 12),
              const SizedBox(width: 2),
              // Raios inferiores (cinza)
              Icon(Icons.flash_on, color: Colors.grey[700], size: 12),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // "DA SOPHIA" - Fonte cursiva em rosa
          Text(
            'DA SOPHIA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryColor,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 1,
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para banner promocional com slide
  Widget _buildPromoBanner() {
    return Container(
      width: kIsWeb ? MediaQuery.of(context).size.width * 0.8 : double.infinity,
      height: kIsWeb ? 600 : 400,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
                      // PageView para os slides
            PageView.builder(
              controller: _pageController,
              itemCount: _banners.isNotEmpty ? _banners.length : 0,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildBannerSlide(index);
            },
          ),
          
          // Botões de controle
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
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
                    if (_banners.isNotEmpty) {
                      final newIndex = (_currentBannerIndex - 1) % _banners.length;
                      final targetIndex = newIndex < 0 ? _banners.length - 1 : newIndex;
                      _pageController.animateToPage(
                        targetIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _resetBannerTimer(); // Resetar timer quando usuário interage
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
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
                    if (_banners.isNotEmpty) {
                      final targetIndex = (_currentBannerIndex + 1) % _banners.length;
                      _pageController.animateToPage(
                        targetIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _resetBannerTimer(); // Resetar timer quando usuário interage
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          
          // Indicadores de página
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.isNotEmpty ? _banners.length : 3, (index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    _resetBannerTimer(); // Resetar timer quando usuário interage
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
                      border: index == _currentBannerIndex 
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para cada slide do banner
  Widget _buildBannerSlide(int index) {
    // Só usar banners do Firebase
    if (_banners.isNotEmpty && index < _banners.length) {
      final banner = _banners[index];
      return _buildFirebaseBanner(banner);
    }

    // Se não há banners do Firebase, retornar container vazio
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFF8BC34A), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Nenhum banner disponível',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Widget para construir banner do Firebase
  Widget _buildFirebaseBanner(banner_model.Banner banner) {
    return GestureDetector(
      onTap: banner.linkProduto != null ? () {
        // Abrir link do produto
        launchUrl(Uri.parse(banner.linkProduto!));
      } : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            banner.image,
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFF8BC34A), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}