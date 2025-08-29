import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/aliexpress_service.dart';
import '../../theme/app_theme.dart';

class AdminAliExpressDSScreen extends StatefulWidget {
  const AdminAliExpressDSScreen({super.key});

  @override
  State<AdminAliExpressDSScreen> createState() => _AdminAliExpressDSScreenState();
}

class _AdminAliExpressDSScreenState extends State<AdminAliExpressDSScreen> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _savedLinks = [];
  List<Map<String, dynamic>> _productCards = [];

  @override
  void initState() {
    super.initState();
    _loadSavedLinks();
  }

  Future<void> _loadSavedLinks() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('saved_product_links')
          .orderBy('saved_at', descending: true)
          .get();
      
      if (mounted) {
        setState(() {
          _savedLinks = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'link': data['link'] ?? '',
              'notes': data['notes'] ?? '',
              'saved_at': data['saved_at'] ?? '',
              'status': data['status'] ?? 'pending',
            };
          }).toList();
        });
      }
      
      // Carregar produtos dos links salvos
      await _loadProductsFromLinks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar links: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProductsFromLinks() async {
    if (_savedLinks.isEmpty) {
      if (mounted) {
        setState(() {
          _productCards = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingProducts = true;
      });
    }

    try {
      List<Map<String, dynamic>> products = [];
      
      for (final link in _savedLinks) {
        try {
          final productData = await AliExpressService.getProductDataByLink(link['link']);
          if (productData != null && productData['success'] == true && productData['data'] != null) {
            products.add({
              ...productData['data'],
              'firebase_id': link['id'],
              'notes': link['notes'],
              'saved_at': link['saved_at'],
            });
          } else {
            print('Produto não encontrado ou erro: ${link['link']}');
          }
        } catch (e) {
          print('Erro ao carregar produto ${link['link']}: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _productCards = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _saveProductLink() async {
    if (_linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira o link do produto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'link': _linkController.text.trim(),
        'notes': _notesController.text.trim(),
        'saved_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Salvar no Firebase
      await FirebaseFirestore.instance
          .collection('saved_product_links')
          .add(productData);
      
      // Recarregar a lista e produtos
      await _loadSavedLinks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpar campos
      _linkController.clear();
      _notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'AliExpress DS - Gerenciar Links',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSavedLinks,
            tooltip: 'Atualizar Links',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Formulário para salvar link (fixo no topo)
          _buildSaveForm(),
          
          // Área dos Produtos dos Links Salvos (com altura automática e rolagem)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header da seção de produtos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Produtos dos Links Salvos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${_productCards.length} produto${_productCards.length != 1 ? 's' : ''} carregado${_productCards.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            const url = 'https://ds.aliexpress.com/find-products';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Abrir AliExpress DS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Grid de produtos com rolagem
                  Expanded(
                    child: _isLoadingProducts
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Carregando produtos...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _productCards.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Nenhum produto carregado',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Salve links de produtos para vê-los aqui',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        const url = 'https://ds.aliexpress.com/find-products';
                                        if (await canLaunchUrl(Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.explore),
                                      label: const Text('Explorar AliExpress DS'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 250, // Máximo 250px por card
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _productCards.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(_productCards[index]);
                                },
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

  Widget _buildSaveForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.link, color: Colors.blue[700]),
              ),
              const SizedBox(width: 12),
              const Text(
                'Salvar Link do Produto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Link do Produto',
              hintText: 'Cole aqui o link do produto do AliExpress',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.link),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Adicione observações sobre o produto',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.note),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProductLink,
              icon: _isLoading 
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: Text(_isLoading ? 'Salvando...' : 'Salvar Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mercado da Sophia',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Itens do menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/dashboard');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.search,
                  title: 'Buscar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/aliexpress');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.rss_feed,
                  title: 'Feed',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/feeds');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.language,
                  title: 'AliExpress DS',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  title: 'Produtos Importados',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/imported-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_box,
                  title: 'Adicionar Produto',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/add-product');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Gerenciar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/manage-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag,
                  title: 'Gestão de Pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/orders');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final basicInfo = product['basic_info'] ?? {};
    final ratings = product['ratings'] ?? {};
    final images = product['images'] ?? [];
    final variations = product['variations'] ?? [];
    final priceInfo = product['price_info'] ?? {};
    final storeInfo = product['store_info'] ?? {};
    final packageInfo = product['package_info'] ?? {};
    final notes = product['notes'] ?? '';
    
    return Container(
      width: 230, // Largura fixa de 230px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showProductModal(product),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey[50],
              ),
              child: images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Image.network(
                            images.first,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Badge de destaque
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Badge de observações se houver
                          if (notes.isNotEmpty)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.note,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            
            // Informações do produto
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título do produto
                  Text(
                    basicInfo['title'] ?? 'Sem título',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Avaliações
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${ratings['avg_evaluation_rating'] ?? '0'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${ratings['evaluation_count'] ?? '0'})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Preço (se disponível)
                  if (priceInfo['sale_price'] != null)
                    Row(
                      children: [
                        Text(
                          'R\$ ${priceInfo['sale_price']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        if (priceInfo['original_price'] != null && 
                            priceInfo['original_price'] != priceInfo['sale_price'])
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              'R\$ ${priceInfo['original_price']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Informações da loja
                  if (storeInfo['store_name'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            storeInfo['store_name'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Informações adicionais
                  Row(
                    children: [
                      if (variations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${variations.length} var.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (packageInfo['gross_weight'] != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${packageInfo['gross_weight']}kg',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductModal(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailModal(
        product: product,
        onImport: () => _importProduct(product),
      ),
    );
  }

  Future<void> _importProduct(Map<String, dynamic> product) async {
    // TODO: Implementar importação do produto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de importação será implementada em breve!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class ProductDetailModal extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onImport;

  const ProductDetailModal({
    super.key,
    required this.product,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final basicInfo = product['basic_info'] ?? {};
    final ratings = product['ratings'] ?? {};
    final storeInfo = product['store_info'] ?? {};
    final packageInfo = product['package_info'] ?? {};
    final priceInfo = product['price_info'] ?? {};
    final variations = product['variations'] ?? [];
    final properties = product['properties'] ?? [];
    final images = product['images'] ?? [];
    final notes = product['notes'] ?? '';
    final freightInfo = product['freight_info'] ?? {};
    final specialInfo = product['special_info'] ?? {};

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      basicInfo['title'] ?? 'Detalhes do Produto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagem principal
                    if (images.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações básicas
                    _buildInfoSection(
                      'Informações Básicas',
                      [
                        'Título: ${basicInfo['title'] ?? 'N/A'}',
                        'ID: ${basicInfo['product_id'] ?? 'N/A'}',
                        'Categoria: ${basicInfo['category_id'] ?? 'N/A'}',
                        'Status: ${basicInfo['product_status_type'] ?? 'N/A'}',
                        'Tipo: ${basicInfo['product_type'] ?? 'N/A'}',
                        'Marca: ${basicInfo['brand'] ?? 'N/A'}',
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Preços
                    if (priceInfo.isNotEmpty)
                      _buildInfoSection(
                        'Informações de Preço',
                        [
                          'Preço de venda: R\$ ${priceInfo['sale_price'] ?? 'N/A'}',
                          'Preço original: R\$ ${priceInfo['original_price'] ?? 'N/A'}',
                          'Moeda: ${priceInfo['currency'] ?? 'BRL'}',
                          'Desconto: ${priceInfo['discount'] ?? 'N/A'}',
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Avaliações
                    _buildInfoSection(
                      'Avaliações',
                      [
                        'Avaliação média: ${ratings['avg_evaluation_rating'] ?? '0'}/5',
                        'Total de avaliações: ${ratings['evaluation_count'] ?? '0'}',
                        'Vendas: ${ratings['sales_count'] ?? '0'}',
                        'Avaliações positivas: ${ratings['positive_rate'] ?? 'N/A'}%',
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações da loja
                    _buildInfoSection(
                      'Informações da Loja',
                      [
                        'Nome: ${storeInfo['store_name'] ?? 'N/A'}',
                        'ID: ${storeInfo['store_id'] ?? 'N/A'}',
                        'País: ${storeInfo['store_country_code'] ?? 'N/A'}',
                        'Avaliação da loja: ${storeInfo['store_rating'] ?? 'N/A'}',
                        'Anos de atividade: ${storeInfo['store_years'] ?? 'N/A'}',
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações do pacote
                    _buildInfoSection(
                      'Informações do Pacote',
                      [
                        'Peso bruto: ${packageInfo['gross_weight'] ?? 'N/A'} kg',
                        'Comprimento: ${packageInfo['package_length'] ?? 'N/A'} cm',
                        'Largura: ${packageInfo['package_width'] ?? 'N/A'} cm',
                        'Altura: ${packageInfo['package_height'] ?? 'N/A'} cm',
                        'Tipo de pacote: ${packageInfo['package_type'] ?? 'N/A'}',
                        'Volume: ${packageInfo['package_volume'] ?? 'N/A'}',
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações de frete
                    if (freightInfo.isNotEmpty)
                      _buildInfoSection(
                        'Informações de Frete',
                        [
                          'Frete grátis: ${freightInfo['free_shipping'] == true ? 'Sim' : 'Não'}',
                          'Tempo de entrega: ${freightInfo['delivery_time'] ?? 'N/A'}',
                          'Custo do frete: R\$ ${freightInfo['shipping_cost'] ?? 'N/A'}',
                          'Método de envio: ${freightInfo['shipping_method'] ?? 'N/A'}',
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações especiais
                    if (specialInfo.isNotEmpty)
                      _buildInfoSection(
                        'Informações Especiais',
                        [
                          'Certificações: ${specialInfo['certifications'] ?? 'N/A'}',
                          'Garantia: ${specialInfo['warranty'] ?? 'N/A'}',
                          'Material: ${specialInfo['material'] ?? 'N/A'}',
                          'Origem: ${specialInfo['origin'] ?? 'N/A'}',
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Variações
                    if (variations.isNotEmpty)
                      _buildInfoSection(
                        'Variações (${variations.length})',
                        variations.take(10).map((variation) {
                          final skuProps = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
                          final props = skuProps.map((prop) => '${prop['sku_property_name']}: ${prop['sku_property_value']}').join(', ');
                          final price = variation['offer_sale_price'] ?? 'N/A';
                          return 'SKU ${variation['sku_id']}: R\$ $price - ${props}';
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Propriedades
                    if (properties.isNotEmpty)
                      _buildInfoSection(
                        'Propriedades (${properties.length})',
                        properties.take(15).map((prop) => '${prop['attr_name']}: ${prop['attr_value']}').toList(),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Observações
                    if (notes.isNotEmpty)
                      _buildInfoSection(
                        'Observações',
                        [notes],
                      ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Footer com botões
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onImport();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Importar Produto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Implementar ação de abrir no AliExpress
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir no AliExpress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
