import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCardCompact extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCardCompact({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 160,
          child: Column(
            children: [
              // Imagem
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Conteúdo
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          product.name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'R\$ ${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
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