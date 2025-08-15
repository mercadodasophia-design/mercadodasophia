import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/aliexpress_service.dart';
import '../../models/product.dart';

class AdminImportScreen extends StatefulWidget {
  const AdminImportScreen({super.key});

  @override
  State<AdminImportScreen> createState() => _AdminImportScreenState();
}

class _AdminImportScreenState extends State<AdminImportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AliExpressService _aliExpressService = AliExpressService();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _aliExpressService.searchProducts(
        _searchController.text.trim(),
        limit: 400,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na busca: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importProduct(Map<String, dynamic> product) async {
    try {
      // Usar a URL do produto para importação
      final productUrl = product['url'] ?? product['aliexpressUrl'] ?? '';
      
      if (productUrl.isEmpty) {
        throw Exception('URL do produto não encontrada');
      }
      
      await _aliExpressService.importProduct(productUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto importado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Importar Produtos',
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
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar produtos no AliExpress...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                  _hasSearched = false;
                                });
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: (_) => _searchProducts(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchProducts,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Resultados da busca
          Expanded(
            child: _hasSearched
                ? _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Buscando produtos...'),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum produto encontrado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tente uma busca diferente',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                                                 : GridView.builder(
                             padding: const EdgeInsets.all(16),
                             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                               crossAxisCount: 2,
                               childAspectRatio: 0.65,
                               crossAxisSpacing: 12,
                               mainAxisSpacing: 12,
                             ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final product = _searchResults[index];
                              return _buildProductCard(product);
                            },
                          )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Pesquise produtos no AliExpress',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Digite o nome do produto e clique em buscar',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                                     decoration: BoxDecoration(
                     gradient: AppTheme.primaryGradient,
                   ),
                   child: product['image'] != null
                       ? Image.network(
                           product['image'],
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
                         )
                       : const Center(
                           child: Icon(
                             Icons.shopping_bag,
                             size: 40,
                             color: Colors.white,
                           ),
                         ),
                ),
              ),
            ),
            
            // Conteúdo do card
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         // Nome do produto
                     Expanded(
                       flex: 3,
                       child: Text(
                         product['title'] ?? product['name'] ?? 'Produto sem nome',
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 11,
                         ),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     
                     const SizedBox(height: 2),
                     
                     // Rating
                     Row(
                       children: [
                         const Icon(
                           Icons.star,
                           size: 10,
                           color: Colors.amber,
                         ),
                         const SizedBox(width: 2),
                         Expanded(
                           child: Text(
                             '${product['rating']?.toString() ?? '0.0'}',
                             style: const TextStyle(
                               fontSize: 9,
                               color: Colors.grey,
                             ),
                           ),
                         ),
                       ],
                     ),
                     
                     const SizedBox(height: 2),
                     
                     // Preço
                     Text(
                       product['price'] ?? 'Preço não disponível',
                       style: const TextStyle(
                         color: AppTheme.primaryColor,
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                       ),
                     ),
                     
                     // Botão de importar
                     const SizedBox(height: 2),
                     SizedBox(
                       width: double.infinity,
                       height: 24,
                       child: ElevatedButton.icon(
                         onPressed: () => _importProduct(product),
                         icon: const Icon(Icons.download, size: 10),
                         label: const Text(
                           'Importar',
                           style: TextStyle(fontSize: 8),
                         ),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blue,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 2),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(6),
                           ),
                         ),
                       ),
                     ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem do produto
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 250,
                                                                                      decoration: BoxDecoration(
                               gradient: AppTheme.primaryGradient,
                             ),
                             child: product['image'] != null
                                 ? Image.network(
                                     product['image'],
                                     fit: BoxFit.cover,
                                     errorBuilder: (context, error, stackTrace) {
                                       return const Center(
                                         child: Icon(
                                           Icons.shopping_bag,
                                           size: 64,
                                           color: Colors.white,
                                         ),
                                       );
                                     },
                                   )
                                 : const Center(
                                     child: Icon(
                                       Icons.shopping_bag,
                                       size: 64,
                                       color: Colors.white,
                                     ),
                                   ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Nome do produto
                      Text(
                        product['title'] ?? product['name'] ?? 'Produto sem nome',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Preço
                      Row(
                        children: [
                          Text(
                            product['price'] ?? 'Preço não disponível',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (product['originalPrice'] != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              product['originalPrice'],
                              style: TextStyle(
                                fontSize: 18,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Avaliação e vendas
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '${product['rating']?.toString() ?? '0.0'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.shopping_cart, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '${product['reviews'] ?? '0'} avaliações',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Vendedor
                      if (product['seller'] != null) ...[
                        Row(
                          children: [
                            Icon(Icons.store, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Vendedor: ${product['seller']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // URL do AliExpress
                      if (product['aliexpressUrl'] != null) ...[
                        Row(
                          children: [
                            Icon(Icons.link, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ver no AliExpress',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[600],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Botão de importar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _importProduct(product);
                          },
                          icon: const Icon(Icons.download),
                          label: const Text(
                            'Importar Produto',
                            style: TextStyle(fontSize: 16),
                          ),
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