import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';

import '../providers/cart_provider.dart';
import '../providers/profit_margin_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_variations_widget.dart';
import '../widgets/cart_badge.dart';
import '../widgets/shipping_calculator_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late PageController _pageController;
  int _currentPage = 0;
  int _quantity = 1;
  ProductVariation? _selectedVariation;
  bool _isFavorite = false;
  double _shippingCost = 0.0;

  @override
  void initState() {
    super.initState();
    // Inicializar PageController
    _pageController = PageController(initialPage: 0);
    
    // Inicializar com a primeira variação disponível se existir
    if (widget.product.variations.isNotEmpty) {
      final firstAvailable = widget.product.variations.firstWhere(
        (v) => v.hasStock,
        orElse: () => widget.product.variations.first,
      );
      _selectedVariation = firstAvailable;
    }
    
    // Carregar endereço salvo do usuário se estiver logado
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      if (authService.isAuthenticated) {
        await locationProvider.loadSavedAddressWithAuth(authService);
      }
    } catch (e) {
      print('❌ Erro ao carregar endereço salvo: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Método para navegar para uma página específica
  void _goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < widget.product.allImages.length) {
      setState(() {
        _currentPage = pageIndex;
      });
      
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Método para abrir visualização em tela cheia
  void _openFullScreenView() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageView(
            images: widget.product.allImages,
            initialIndex: _currentPage,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitMarginProvider>(
      builder: (context, profitMarginProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: kIsWeb ? _buildWebLayout(profitMarginProvider) : _buildMobileLayout(profitMarginProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Verificar se o produto é do SexyShop baseado na categoria
            final productCategory = widget.product.categoria?.toLowerCase() ?? '';
            final isSexyShopProduct = productCategory.contains('sexyshop') || 
                                     productCategory.contains('adulto') ||
                                     productCategory.contains('erotico') ||
                                     productCategory.contains('lingerie') ||
                                     productCategory.contains('fantasia');
            
            if (isSexyShopProduct) {
              context.go('/sexyshop');
            } else {
              context.go('/produtos');
            }
          }
        },
      ),
      title: Text(
        widget.product.titulo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isFavorite ? 'Adicionado aos favoritos!' : 'Removido dos favoritos'),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Favoritos',
        ),
                 CartBadge(
           onTap: () {
             context.go('/carrinho');
           },
           size: 24,
           backgroundColor: Colors.red,
           textColor: Colors.white,
         ),
      ],
    );
  }

  Widget _buildWebLayout(ProfitMarginProvider profitMarginProvider) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha superior - Imagem e Informações
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna da esquerda - Imagens
                  Expanded(
                    flex: 1,
                    child: _buildImageSection(),
                  ),
                  const SizedBox(width: 32),
                  // Coluna da direita - Informações
                  Expanded(
                    flex: 1,
                    child: _buildProductInfo(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Linha inferior - Descrição
              _buildDescriptionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(ProfitMarginProvider profitMarginProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 16),
          _buildProductInfo(),
          const SizedBox(height: 24),
          _buildDescriptionSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final allImages = widget.product.allImages;
    final hasMultipleImages = allImages.length > 1;

    return Column(
      children: [
        // Imagem principal
        Container(
          height: kIsWeb ? 400 : 300,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: allImages.isNotEmpty
                ? hasMultipleImages
                                         ? GestureDetector(
                         onTap: _openFullScreenView,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemCount: allImages.length,
                          itemBuilder: (context, index) {
                                                         return Image.network(
                               allImages[index],
                               fit: BoxFit.contain,
                               errorBuilder: (context, error, stackTrace) {
                                 return _buildPlaceholderImage();
                               },
                               loadingBuilder: (context, child, loadingProgress) {
                                 if (loadingProgress == null) return child;
                                 return const Center(
                                   child: CircularProgressIndicator(
                                     color: AppTheme.primaryColor,
                                   ),
                                 );
                               },
                             );
                          },
                        ),
                      )
                                         : Image.network(
                         allImages[0],
                         fit: BoxFit.contain,
                         errorBuilder: (context, error, stackTrace) {
                           return _buildPlaceholderImage();
                         },
                         loadingBuilder: (context, child, loadingProgress) {
                           if (loadingProgress == null) return child;
                           return const Center(
                             child: CircularProgressIndicator(
                               color: AppTheme.primaryColor,
                             ),
                           );
                         },
                       )
                : _buildPlaceholderImage(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Miniaturas das imagens
        if (hasMultipleImages) ...[
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                                 return GestureDetector(
                   onTap: () => _goToPage(index),
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 200),
                     width: 80,
                     height: 80,
                     margin: const EdgeInsets.only(right: 12),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(
                         color: _currentPage == index 
                             ? AppTheme.primaryColor 
                             : Colors.grey[300]!,
                         width: _currentPage == index ? 3 : 1,
                       ),
                       color: Colors.grey[100],
                       boxShadow: _currentPage == index ? [
                         BoxShadow(
                           color: AppTheme.primaryColor.withOpacity(0.3),
                           blurRadius: 8,
                           spreadRadius: 2,
                         ),
                       ] : null,
                                          ),
                                         child: Stack(
                       children: [
                         ClipRRect(
                           borderRadius: BorderRadius.circular(7),
                           child: Image.network(
                             allImages[index],
                             fit: BoxFit.cover,
                             errorBuilder: (context, error, stackTrace) {
                               return Container(
                                 decoration: BoxDecoration(
                                   color: Colors.grey[200],
                                   borderRadius: BorderRadius.circular(7),
                                 ),
                                 child: const Icon(
                                   Icons.image_not_supported,
                                   color: Colors.grey,
                                   size: 24,
                                 ),
                               );
                             },
                             loadingBuilder: (context, child, loadingProgress) {
                               if (loadingProgress == null) return child;
                               return Container(
                                 decoration: BoxDecoration(
                                   color: Colors.grey[200],
                                   borderRadius: BorderRadius.circular(7),
                                 ),
                                 child: const Center(
                                   child: SizedBox(
                                     width: 20,
                                     height: 20,
                                     child: CircularProgressIndicator(
                                       color: AppTheme.primaryColor,
                                       strokeWidth: 2,
                                     ),
                                   ),
                                 ),
                               );
                             },
                           ),
                         ),
                         // Indicador de seleção
                         if (_currentPage == index)
                           Positioned(
                             top: 4,
                             right: 4,
                             child: Container(
                               width: 20,
                               height: 20,
                               decoration: BoxDecoration(
                                 color: AppTheme.primaryColor,
                                 shape: BoxShape.circle,
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.2),
                                     blurRadius: 4,
                                     spreadRadius: 1,
                                   ),
                                 ],
                               ),
                               child: const Icon(
                                 Icons.check,
                                 color: Colors.white,
                                 size: 12,
                               ),
                             ),
                           ),
                       ],
                     ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Indicadores de página (apenas se há múltiplas imagens)
        if (hasMultipleImages) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(allImages.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppTheme.primaryColor
                      : Colors.grey[300],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_bag,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome do produto
        Text(
          widget.product.titulo,
          style: const TextStyle(
            fontSize: kIsWeb ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // Categoria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.product.categoria,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
                 // Preço com margem aplicada
        if (widget.product.hasVariations && _selectedVariation != null)
          // Preço da variação selecionada
          Consumer<ProfitMarginProvider>(
            builder: (context, marginProvider, child) {
              final displayPrice = marginProvider.isReady 
                  ? marginProvider.calculateFinalPrice(_selectedVariation!.price, widget.product.id ?? '')
                  : _selectedVariation!.price;
              
              return Text(
                'R\$ ${displayPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: kIsWeb ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          )
        else
          Consumer<ProfitMarginProvider>(
          builder: (context, marginProvider, child) {
            final displayPrice = marginProvider.isReady 
                ? marginProvider.calculateFinalPrice(widget.product.preco, widget.product.id ?? '')
                : widget.product.preco;
            
            if (widget.product.descontoPercentual != null && widget.product.descontoPercentual! > 0) {
              // Preço com desconto
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preço original riscado
                  Text(
                    'R\$ ${displayPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: kIsWeb ? 20 : 18,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Preço com desconto
                  Row(
                    children: [
                      Text(
                        'R\$ ${(displayPrice * (1 - (widget.product.descontoPercentual! / 100))).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: kIsWeb ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B9D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${widget.product.descontoPercentual!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Preço normal sem desconto
              return Text(
                'R\$ ${displayPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: kIsWeb ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              );
            }
          },
        ),
         // Mostrar faixa de preços se houver variações
         if (widget.product.hasVariations && widget.product.minPrice != widget.product.maxPrice) ...[
           const SizedBox(height: 4),
           Text(
             'R\$ ${widget.product.minPrice.toStringAsFixed(2)} - R\$ ${widget.product.maxPrice.toStringAsFixed(2)}',
             style: TextStyle(
               fontSize: 14,
               color: Colors.grey[600],
               fontWeight: FontWeight.w500,
             ),
           ),
         ],
         // Mostrar total com frete se calculado
         if (_shippingCost > 0) ...[
           const SizedBox(height: 8),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             decoration: BoxDecoration(
               color: Colors.green[50],
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.green[200]!),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(Icons.local_shipping, color: Colors.green[600], size: 16),
                 const SizedBox(width: 8),
                 Consumer<ProfitMarginProvider>(
                   builder: (context, marginProvider, child) {
                     final basePrice = widget.product.hasVariations && _selectedVariation != null 
                         ? _selectedVariation!.price 
                         : (widget.product.descontoPercentual != null && widget.product.descontoPercentual! > 0 
                             ? widget.product.preco * (1 - (widget.product.descontoPercentual! / 100)) 
                             : widget.product.preco);
                     
                     final displayPrice = marginProvider.isReady 
                         ? marginProvider.calculateFinalPrice(basePrice, widget.product.id ?? '')
                         : basePrice;
                     
                     return Text(
                       'Total com frete: R\$ ${(displayPrice * _quantity + _shippingCost).toStringAsFixed(2)}',
                       style: TextStyle(
                         fontSize: 14,
                         fontWeight: FontWeight.w600,
                         color: Colors.green[800],
                       ),
                     );
                   },
                 ),
               ],
             ),
           ),
         ],
        const SizedBox(height: 16),
        
        // Avaliações
        _buildRatingSection(),
        const SizedBox(height: 24),
        
        // Variações do produto
        ProductVariationsWidget(
          product: widget.product,
          selectedVariation: _selectedVariation,
          onVariationSelected: (variation) {
            setState(() {
              _selectedVariation = variation;
            });
          },
        ),
        const SizedBox(height: 16),
        
                 // Quantidade
         _buildQuantitySection(),
         const SizedBox(height: 24),
         
         // Cálculo de frete
         ShippingCalculatorWidget(
           product: widget.product,
           onShippingSelected: (cost) {
             setState(() {
               _shippingCost = cost;
             });
           },
         ),
         const SizedBox(height: 24),
         
         // Botões de ação
         _buildActionButtons(),
         const SizedBox(height: 24),
         
         // Informações adicionais
         _buildAdditionalInfo(),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Row(
      children: [
        // Estrelas
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < 4 ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          '4.0',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(128 avaliações)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Descrição do Produto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.descricao.isNotEmpty 
                ? widget.product.descricao 
                : 'Este produto oferece qualidade excepcional e design moderno. Perfeito para quem busca estilo e funcionalidade em um só lugar. Desenvolvido com materiais de alta qualidade e atenção aos detalhes, este produto foi criado para proporcionar a melhor experiência possível aos nossos clientes.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Características adicionais
          if (widget.product.descricao.isNotEmpty) ...[
            const Text(
              'Características Principais:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('✓ Qualidade Premium'),
            _buildFeatureItem('✓ Design Moderno'),
            _buildFeatureItem('✓ Durabilidade Garantida'),
            _buildFeatureItem('✓ Entrega Rápida'),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildQuantitySection() {
    // Calcular quantidade máxima disponível
    int maxQuantity = 1;
    if (widget.product.hasVariations && _selectedVariation != null) {
      maxQuantity = _selectedVariation!.stock;
    } else if (!widget.product.hasVariations) {
      // Para produtos sem variações, usar um valor padrão ou verificar disponibilidade
      maxQuantity = widget.product.isAvailable ? 999 : 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quantidade:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      _quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_quantity < maxQuantity) {
                        setState(() {
                          _quantity++;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_quantity > maxQuantity) ...[
          const SizedBox(height: 4),
          Text(
            'Quantidade máxima: $maxQuantity',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    // Verificar se pode adicionar ao carrinho
    bool canAddToCart = true;
    String disabledReason = '';

    if (widget.product.hasVariations) {
      if (_selectedVariation == null) {
        canAddToCart = false;
        disabledReason = 'Selecione uma variação';
      } else if (!_selectedVariation!.hasStock) {
        canAddToCart = false;
        disabledReason = 'Sem estoque';
      } else if (_quantity > _selectedVariation!.stock) {
        canAddToCart = false;
        disabledReason = 'Quantidade indisponível';
      }
    } else {
      if (!widget.product.isAvailable) {
        canAddToCart = false;
        disabledReason = 'Produto indisponível';
      }
    }

    return Column(
      children: [
        // Botão Adicionar ao Carrinho
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: canAddToCart ? () {
              _addToCart();
            } : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: canAddToCart ? AppTheme.primaryColor : Colors.grey[400]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              canAddToCart ? 'Adicionar ao Carrinho' : disabledReason,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: canAddToCart ? AppTheme.primaryColor : Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botão Ir para o Carrinho
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              context.go('/carrinho');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ir para o Carrinho',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!canAddToCart) ...[
          const SizedBox(height: 8),
          Text(
            disabledReason,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações do Produto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Categoria', widget.product.categoria),
        _buildInfoRow('Disponibilidade', 'Em estoque'),
        _buildInfoRow('Entrega', '12-28 dias úteis'),
        _buildInfoRow('Devolução', 'Grátis em até 30 dias'),
        _buildInfoRow('Segurança', 'Privacidade garantida'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart() async {
    final cartProvider = context.read<CartProvider>();
    
    // Verificar se há uma variação selecionada quando o produto tem variações
    if (widget.product.hasVariations && _selectedVariation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Por favor, selecione uma variação do produto antes de adicionar ao carrinho.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Verificar estoque da variação selecionada
    if (widget.product.hasVariations && _selectedVariation != null) {
      if (!_selectedVariation!.hasStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produto indisponível: ${_selectedVariation!.displayName} está sem estoque.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Verificar se a quantidade solicitada está disponível
      if (_quantity > _selectedVariation!.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantidade indisponível. Máximo disponível: ${_selectedVariation!.stock} unidades.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Verificar estoque do produto simples (sem variações)
    if (!widget.product.hasVariations) {
      if (!widget.product.isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Produto indisponível no momento.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Adicionar ao carrinho
    final success = await cartProvider.addItem(
      widget.product,
      variation: _selectedVariation,
      quantity: _quantity,
    );

         if (success) {
       // Calcular preço e informações
       final variation = _selectedVariation;
       final basePrice = variation?.price ?? (widget.product.descontoPercentual != null && widget.product.descontoPercentual! > 0 ? widget.product.preco * (1 - (widget.product.descontoPercentual! / 100)) : widget.product.preco);
       
       // Aplicar margem se o provider estiver disponível
       final profitMarginProvider = Provider.of<ProfitMarginProvider>(context, listen: false);
       final price = profitMarginProvider.isReady 
           ? profitMarginProvider.calculateFinalPrice(basePrice, widget.product.id ?? '')
           : basePrice;
       final totalPrice = price * _quantity;
       final totalWithShipping = totalPrice + _shippingCost;
       
       String variationInfo = '';
       String skuInfo = '';
       String shippingInfo = '';
       
       if (variation != null) {
         List<String> parts = [];
         if (variation.color != null) parts.add(variation.color!);
         if (variation.size != null) parts.add(variation.size!);
         if (parts.isNotEmpty) {
           variationInfo = ' (${parts.join(' - ')})';
         }
         skuInfo = ' - SKU: ${variation.sku}';
       }
       
       if (_shippingCost > 0) {
         shippingInfo = ' + Frete: R\$ ${_shippingCost.toStringAsFixed(2)}';
       }
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(
             '✅ Adicionado ao carrinho: ${widget.product.titulo}$variationInfo x$_quantity - R\$ ${totalPrice.toStringAsFixed(2)}$shippingInfo$skuInfo',
           ),
           backgroundColor: Colors.green,
           action: SnackBarAction(
             label: 'Ver Carrinho',
             textColor: Colors.white,
             onPressed: () {
               context.go('/carrinho');
             },
           ),
           duration: const Duration(seconds: 4),
         ),
       );
    } else {
      // Mostrar erro do provider
      if (cartProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProvider.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Widget para visualização em tela cheia das imagens
class _FullScreenImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageView({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView para as imagens
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Botão de fechar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Indicadores de página (apenas se há múltiplas imagens)
          if (widget.images.length > 1) ...[
            // Contador de imagens
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Indicadores de página na parte inferior
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 