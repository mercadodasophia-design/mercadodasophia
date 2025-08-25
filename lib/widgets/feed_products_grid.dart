import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';

class FeedProductsGrid extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  const FeedProductsGrid({
    Key? key,
    required this.products,
    this.isLoading = false,
    this.onLoadMore,
    this.hasMore = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (hasMore && !isLoading && 
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length + (isLoading && hasMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return _buildLoadingCard();
          }
          
          final product = products[index];
          // Verificação de segurança para evitar erros de renderização
          if (product == null) {
            return _buildLoadingCard();
          }
          
          try {
            return ProductCard(product: product);
          } catch (e) {
            print('Erro ao renderizar produto: $e');
            return _buildLoadingCard();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente selecionar outro feed ou verificar sua conexão',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
