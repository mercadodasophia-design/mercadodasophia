import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/product_card_v2.dart';
import '../widgets/friendly_router.dart';
import '../theme/app_theme.dart';


class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Product> offersProducts = [];
  String? selectedCategory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffersProducts();
  }

  Future<void> _loadOffersProducts() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final products = await ProductService.getProductsWithDiscount();
      setState(() {
        offersProducts = products;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar produtos em oferta: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Product> get filteredProducts {
    if (selectedCategory == null || selectedCategory == 'Todos') {
      return offersProducts;
    } else {
      return offersProducts.where((product) => product.categoria == selectedCategory).toList();
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
          'Ofertas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/produtos'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com estatísticas
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produtos em Oferta',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${filteredProducts.length} produtos com desconto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OFERTAS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Filtros de categoria
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', selectedCategory == null || selectedCategory == 'Todos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Garrafeira', selectedCategory == 'Garrafeira'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Compotas e Mel', selectedCategory == 'Compotas e Mel'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Doces', selectedCategory == 'Doces'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Chás e Refrescos', selectedCategory == 'Chás e Refrescos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Queijos e Pão', selectedCategory == 'Queijos e Pão'),
                  ],
                ),
              ),
            ),
            
            // Lista de produtos em oferta
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 1,
                          runSpacing: 1,
                          children: filteredProducts.map((product) {
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 34) / 2,
                              child: Stack(
                                children: [
                                  ProductCardV2(
                                    product: product,
                                    onTap: () => _showProductDetails(product),
                                  ),
                                  // Badge de oferta
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'OFERTA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
            
            // Rodapé
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Seção superior (cinza claro)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[200],
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
                          'República, São Paulo - SP, 01037-010',
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
                            _buildFooterContact(Icons.phone, '(85) 99764-0050'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma oferta disponível',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Volte mais tarde para novas ofertas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            selectedCategory = label;
          } else {
            selectedCategory = null;
          }
        });
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white.withOpacity(0.5),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooterCategory(String label) {
    return FilterChip(
      label: Text(label),
      selected: selectedCategory == label,
      onSelected: (selected) {
        setState(() {
          selectedCategory = selected ? label : null;
        });
      },
    );
  }

  Widget _buildFooterContact(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _showProductDetails(Product product) {
    // Usar URLs amigáveis
    FriendlyNavigator.pushProduct(context, product);
  }
} 