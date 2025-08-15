import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_product_service.dart';
import '../../theme/app_theme.dart';

class AdminProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  
  const AdminProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<AdminProductDetailsScreen> createState() => _AdminProductDetailsScreenState();
}

class _AdminProductDetailsScreenState extends State<AdminProductDetailsScreen> {
  bool isImporting = false;

  Future<void> _importProduct() async {
    setState(() {
      isImporting = true;
    });

    try {
      final productService = context.read<FirebaseProductService>();
      
      // Processar dados do AliExpress
      final processedData = {
        'name': widget.product['name'],
        'description': 'Produto importado do AliExpress',
        'price': widget.product['price'],
        'originalPrice': widget.product['originalPrice'],
        'stockQuantity': 0,
        'images': [widget.product['image']],
        'mainImage': widget.product['image'],
        'aliexpressId': widget.product['aliexpressId'],
        'aliexpressUrl': widget.product['url'],
        'aliexpressRating': widget.product['rating'],
        'aliexpressReviewsCount': widget.product['reviews'],
        'aliexpressSalesCount': widget.product['sales'],
        'specifications': {
          'Marca': 'Importado',
          'Origem': 'AliExpress',
        },
        'status': 'pending',
        'isActive': false,
        'isFeatured': false,
        'isOnSale': false,
        'searchKeywords': _generateSearchKeywords(widget.product['name']),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'importedFrom': 'aliexpress',
      };

      await productService.importAliExpressProduct(processedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto importado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Voltar para a tela anterior
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isImporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar produto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<String> _generateSearchKeywords(String name) {
    final keywords = <String>{};
    keywords.add(name.toLowerCase());
    
    final words = name.toLowerCase().split(' ');
    for (final word in words) {
      if (word.length > 2) {
        keywords.add(word);
      }
    }
    
    return keywords.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Detalhes do Produto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem principal do produto
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.network(
                  widget.product['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do produto
                  Text(
                    widget.product['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preços
                  Row(
                    children: [
                      Text(
                        'R\$ ${_formatPrice(widget.product['price'])}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'R\$ ${_formatPrice(widget.product['originalPrice'])}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informações de rating e vendas
                  _buildInfoCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Detalhes do produto
                  _buildDetailsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Botões de ação
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    widget.product['rating'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.product['reviews']} avaliações',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.shopping_cart, color: Colors.green, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.product['sales']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'vendidos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.discount, color: Colors.red, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '${(((widget.product['originalPrice'] - widget.product['price']) / widget.product['originalPrice']) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'desconto',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Informações do Produto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID do AliExpress', widget.product['aliexpressId']),
            _buildDetailRow('URL do Produto', widget.product['url']),
            _buildDetailRow('Origem', 'AliExpress'),
            _buildDetailRow('Status', 'Disponível para importação'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isImporting ? null : _importProduct,
            icon: isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(isImporting ? 'Importando...' : 'Importar Produto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Abrir URL do produto no navegador
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abrindo produto no AliExpress...'),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ver no AliExpress'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    
    if (price is String) {
      return price;
    } else if (price is num) {
      return price.toStringAsFixed(2);
    } else {
      return price.toString();
    }
  }
} 