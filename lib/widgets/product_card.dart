import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

/// ProductCard com layout otimizado para evitar overflow
/// 
/// Mudanças implementadas:
/// - Altura fixa de 200px para o card
/// - Uso de Expanded com flex para distribuir espaço
/// - Flexible para textos que podem quebrar
/// - Spacer para empurrar o preço para baixo
/// - Textos mais compactos e ícones menores
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem do produto - altura fixa
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Conteúdo do card - altura flexível
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do produto - espaço garantido
                      Expanded(
                        flex: 2,
                        child: Text(
                          product.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rating - espaço fixo
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating} (${product.reviewCount})',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Preço - espaço fixo
                      Text(
                        'R\$ ${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 