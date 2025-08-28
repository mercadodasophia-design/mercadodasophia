import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../providers/profit_margin_provider.dart';

/// ProductCard para Web - Largura fixa de 230px
/// 
/// Características:
/// - Largura fixa: 230px
/// - Auto-ajuste em linha
/// - Layout otimizado para web
class ProductCardWeb extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCardWeb({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 230,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem do produto
              Container(
                height: 160,
                width: 230,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Stack(
                  children: [
                    // Imagem do produto ou placeholder
                    product.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: CachedNetworkImage(
                              imageUrl: product.images.first,
                              width: 230,
                              height: 160,
                              fit: BoxFit.cover,
                              memCacheWidth: 460, // 2x para retina displays
                              memCacheHeight: 320,
                              maxWidthDiskCache: 460,
                              maxHeightDiskCache: 320,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(
                                  Icons.shopping_bag,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                    // Estrela de favorito no canto superior direito
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Implementar favoritar produto
                        },
                        child: const Icon(
                          Icons.star_border,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Informações do produto
              Container(
                width: 230,
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do produto
                    Flexible(
                      child: Text(
                        product.titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Preço com margem aplicada
                    Consumer<ProfitMarginProvider>(
                      builder: (context, marginProvider, child) {
                        final displayPrice = marginProvider.isReady 
                            ? marginProvider.calculateFinalPrice(product.preco, product.id ?? '')
                            : product.preco;
                        
                        if (product.descontoPercentual != null && product.descontoPercentual! > 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Preço original riscado
                              Text(
                                'R\$ ${displayPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Preço com desconto
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'R\$ ${(displayPrice * (1 - (product.descontoPercentual! / 100))).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B9D),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '-${product.descontoPercentual!.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 8,
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    // Rating e vendas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              0.0 > 0 ? 0.0.toStringAsFixed(1) : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          0 > 0 
                              ? '${0} vendidos'
                              : 'Novo',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                          ),
                        ),
                      ],
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
}
