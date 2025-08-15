import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../providers/location_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_compact.dart';
import '../widgets/product_card_v2.dart';
import '../widgets/product_card_web.dart';
import '../widgets/cart_badge.dart';
import '../theme/app_theme.dart';
import '../utils/debug_helper.dart';

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
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  String? selectedCategory;
  List<Product> filteredProducts = [];
  bool isLoading = true;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
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

  void _filterProducts() {
    if (selectedCategory == null || selectedCategory == 'Todos') {
      filteredProducts = products;
    } else {
      filteredProducts = products.where((product) => product.category == selectedCategory).toList();
    }
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
                          await DebugHelper.runAllTests(locationProvider);
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
                    
                                                                    Image.asset(
                       'assets/images/system/logo/name-logo-web.png',
                       width: 600,
                       height: 800,
                       fit: BoxFit.fill,
                     ),
                    
                    // Espaçamento flexível para empurrar os itens para a direita
                    const Spacer(),
                    // Ícone Minha Conta
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/my_account');
                      },
                      tooltip: 'Minha Conta',
                    ),
                    
                    // Atendimento
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/contact');
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
                Navigator.pushNamed(context, '/cart');
              },
              size: 24,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
                  ],
                ),
              ),
            ),
          
          // Layout condicional para seção de categorias
          kIsWeb 
            ? _buildWebCategoriesSection()
            : _buildMobileCategoriesSection(),
          
          // Conteúdo principal com rodapé fixo no final
          Expanded(
            child: Column(
              children: [
                // Área de conteúdo rolável
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Grid de produtos
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
                      ],
                    ),
                  ),
                ),
                
                // Rodapé fixo no final
                kIsWeb 
                  ? _buildWebFooter()
                  : _buildMobileFooter(),
              ],
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
                        children: [
                          _buildFooterCategory('Garrafeira'),
                          _buildFooterCategory('Compotas e Mel'),
                          _buildFooterCategory('Doces'),
                          _buildFooterCategory('Chás e Refrescos'),
                          _buildFooterCategory('Queijos e Pão'),
                        ],
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
                          'Rua das Flores, 123 - Centro • São Paulo/SP',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFooterContact(Icons.phone, '(11) 99999-9999'),
                          const SizedBox(width: 24),
                          _buildFooterContact(Icons.email, 'contato@mercadodasophia.com'),
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
                   children: [
                     _buildFooterCategory('Garrafeira'),
                     _buildFooterCategory('Compotas e Mel'),
                     _buildFooterCategory('Doces'),
                     _buildFooterCategory('Chás e Refrescos'),
                     _buildFooterCategory('Queijos e Pão'),
                   ],
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
                   'Rua das Flores, 123 - Centro',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.white70,
                   ),
                 ),
                 const Text(
                   'São Paulo/SP - CEP: 01234-567',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.white70,
                   ),
                 ),
                 const SizedBox(height: 16),
                 Wrap(
                   alignment: WrapAlignment.center,
                   spacing: 16,
                   children: [
                     _buildFooterContact(Icons.phone, '(11) 99999-9999'),
                     _buildFooterContact(Icons.email, 'contato@mercadodasophia.com'),
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
                                          Navigator.pushNamed(context, '/my_account');
                                        },
                                      ),
                                      _buildDrawerItem('Minhas Compras', Icons.shopping_bag, () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/my_orders');
                                      }),
                                      _buildDrawerItem('Favoritos', Icons.favorite, () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/favorites');
                                      }),
                                      _buildDrawerItem('Ofertas', Icons.local_offer, () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/offers');
                                      }),
                                      _buildDrawerItem('Cupons', Icons.card_giftcard, () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/coupons');
                                      }),
                                      _buildDrawerItem('Minha Conta', Icons.person, () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/my_account');
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
                                        Navigator.pushNamed(context, '/login');
                                      }),
                                    ],
                                  );
                                }
                              },
                            ),
                            
                            const Divider(height: 30),
                            
                            // Seção de Navegação Principal
                            _buildDrawerSection(
                              'Navegação',
                              [
                                _buildDrawerItem('Início', Icons.home, () {
                                  Navigator.pop(context);
                                }),
                                _buildDrawerItem('Minhas Compras', Icons.shopping_bag, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/my_orders');
                                }),
                                _buildDrawerItem('Favoritos', Icons.favorite, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/favorites');
                                }),
                                _buildDrawerItem('Ofertas', Icons.local_offer, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/offers');
                                }),
                                _buildDrawerItem('Cupons', Icons.card_giftcard, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/coupons');
                                }),
                                _buildDrawerItem('Minha Conta', Icons.person, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/my_account');
                                }),
                              ],
                            ),
                            
                            const Divider(height: 30),
                            
                            // Seção de Categorias
                            _buildDrawerSection(
                              'Categorias de Produtos',
                              [
                                _buildDrawerItem('Garrafeira', Icons.wine_bar, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/products');
                                }),
                                _buildDrawerItem('Compotas e Mel', Icons.hive, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/products');
                                }),
                                _buildDrawerItem('Doces', Icons.cake, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/products');
                                }),
                                _buildDrawerItem('Chás e Refrescos', Icons.local_cafe, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/products');
                                }),
                                _buildDrawerItem('Queijos e Pão', Icons.breakfast_dining, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/products');
                                }),
                              ],
                            ),
                            
                            const Divider(height: 30),
                            
                            // Seção Sobre
                            _buildDrawerSection(
                              'Sobre Mercado Da Sophia',
                              [
                                _buildDrawerItem('Quem Somos', Icons.info, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/about_us');
                                }),
                                _buildDrawerItem('Nossa História', Icons.history, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/our_history');
                                }),
                                _buildDrawerItem('Política de Privacidade', Icons.privacy_tip, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/privacy_policy');
                                }),
                                _buildDrawerItem('Termos de Uso', Icons.description, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/terms_of_use');
                                }),
                                _buildDrawerItem('Contato', Icons.contact_support, () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/contact');
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
                            Navigator.pushNamed(context, '/my_orders');
                          }),
                          _buildDrawerItem('Favoritos', Icons.favorite, () {
                            Navigator.pushNamed(context, '/favorites');
                          }),
                          _buildDrawerItem('Ofertas', Icons.local_offer, () {
                            Navigator.pushNamed(context, '/offers');
                          }),
                          _buildDrawerItem('Cupons', Icons.card_giftcard, () {
                            Navigator.pushNamed(context, '/coupons');
                          }),
                          _buildDrawerItem('Minha Conta', Icons.person, () {
                            Navigator.pushNamed(context, '/my_account');
                          }),
                        ],
                      ),
                      
                      const Divider(height: 30),
                      
                      // Seção de Categorias
                      _buildDrawerSection(
                        'Categorias de Produtos',
                        [
                          _buildDrawerItem('Garrafeira', Icons.wine_bar, () {
                            Navigator.pushNamed(context, '/products');
                          }),
                          _buildDrawerItem('Compotas e Mel', Icons.hive, () {
                            Navigator.pushNamed(context, '/products');
                          }),
                          _buildDrawerItem('Doces', Icons.cake, () {
                            Navigator.pushNamed(context, '/products');
                          }),
                          _buildDrawerItem('Chás e Refrescos', Icons.local_cafe, () {
                            Navigator.pushNamed(context, '/products');
                          }),
                          _buildDrawerItem('Queijos e Pão', Icons.breakfast_dining, () {
                            Navigator.pushNamed(context, '/products');
                          }),
                        ],
                      ),
                      
                      const Divider(height: 30),
                      
                      // Seção Sobre
                      _buildDrawerSection(
                        'Sobre Mercado Da Sophia',
                        [
                          _buildDrawerItem('Quem Somos', Icons.info, () {
                            Navigator.pushNamed(context, '/about_us');
                          }),
                          _buildDrawerItem('Nossa História', Icons.history, () {
                            Navigator.pushNamed(context, '/our_history');
                          }),
                          _buildDrawerItem('Política de Privacidade', Icons.privacy_tip, () {
                            Navigator.pushNamed(context, '/privacy_policy');
                          }),
                          _buildDrawerItem('Termos de Uso', Icons.description, () {
                            Navigator.pushNamed(context, '/terms_of_use');
                          }),
                          _buildDrawerItem('Contato', Icons.contact_support, () {
                            Navigator.pushNamed(context, '/contact');
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
        Navigator.pushNamed(context, '/my_account');
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showProductDetails(Product product) {
    Navigator.pushNamed(
      context,
      '/product_detail',
      arguments: {'product': product},
    );
  }
} 