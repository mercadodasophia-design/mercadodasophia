import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

/// ProductCard V2 - Layout otimizado com melhor distribuição de espaço
/// 
/// Características:
/// - Altura fixa de 200px
/// - Imagem ocupa 60% do espaço
/// - Conteúdo ocupa 40% do espaço
/// - Rating e preço em posições fixas
class ProductCardV2 extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCardV2({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Permite crescer conforme conteúdo
          children: [
            // Imagem do produto
            Container(
              height: 180, // Imagem maior
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Stack(
                children: [
                  // Imagem do produto ou placeholder
                  product.imageUrl.isNotEmpty
                      ? ClipRRect(
                          child: Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
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
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Informações do produto
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8), // Padding maior
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Permite crescer
                children: [
                  // Nome do produto
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 3, // Permite até 3 linhas
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Preço destacado
                  Text(
                    'R\$ ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Vendas e avaliação
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.reviewCount > 0 
                              ? '${product.reviewCount} vendidos'
                              : 'Novo produto',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        product.rating > 0 ? product.rating.toStringAsFixed(1) : 'N/A',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Informações adicionais
                  if (product.isAvailable)
                    Text(
                      'Disponível em estoque',
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
    );
  }
} 