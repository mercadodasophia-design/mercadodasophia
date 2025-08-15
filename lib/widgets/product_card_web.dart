import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

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
                    product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: Image.network(
                              product.imageUrl,
                              width: 230,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.shopping_bag,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                );
                              },
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
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Preço destacado
                    Text(
                      'R\$ ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating e vendas
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating > 0 ? product.rating.toStringAsFixed(1) : 'N/A',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.reviewCount > 0 
                              ? '${product.reviewCount} vendidos'
                              : 'Novo',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Status de estoque
                    if (product.isAvailable)
                      Text(
                        'Disponível',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Fora de estoque',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
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
}
