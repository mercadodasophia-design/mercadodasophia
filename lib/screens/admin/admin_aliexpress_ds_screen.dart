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
      
      // Carregar produtos dos links salvos
      await _loadProductsFromLinks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar links: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProductsFromLinks() async {
    if (_savedLinks.isEmpty) {
      setState(() {
        _productCards = [];
      });
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      List<Map<String, dynamic>> products = [];
      
      for (final link in _savedLinks) {
        try {
          final productData = await AliExpressService.getProductDataByLink(link['link']);
          if (productData != null && productData['success'] == true) {
            products.add({
              ...productData['data'],
              'firebase_id': link['id'],
              'notes': link['notes'],
              'saved_at': link['saved_at'],
            });
          }
        } catch (e) {
          print('Erro ao carregar produto ${link['link']}: $e');
        }
      }
      
      setState(() {
        _productCards = products;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar produtos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
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
      setState(() {
        _isLoading = false;
      });
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
             body: SingleChildScrollView(
         child: Column(
           children: [
                           // Área dos Produtos dos Links Salvos
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Produtos dos Links Salvos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              const url = 'https://ds.aliexpress.com/find-products';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Abrir AliExpress DS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 400,
                      width: double.infinity,
                      color: Colors.white,
                      child: _isLoadingProducts
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Carregando produtos...'),
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
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nenhum produto carregado',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Salve links de produtos para vê-los aqui',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.8,
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
             
             // Formulário para salvar link (sempre visível)
             _buildSaveForm(),
             
             // Lista de links salvos
             Container(
               height: 300,
               child: _buildSavedLinksList(),
             ),
           ],
         ),
       ),
    );
  }

    Widget _buildSavedLinksList() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Links Salvos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_savedLinks.length} link${_savedLinks.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_savedLinks.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.link_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum link salvo ainda',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Navegue pelo AliExpress DS na área acima, copie o link do produto e cole no campo abaixo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _savedLinks.length,
                itemBuilder: (context, index) {
                  final link = _savedLinks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.link, color: Colors.blue),
                      title: Text(
                        link['link'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (link['notes']?.isNotEmpty == true)
                            Text(
                              link['notes'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Salvo em: ${_formatDate(link['saved_at'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'open') {
                            _openLink(link['link']);
                          } else if (value == 'delete') {
                            _deleteLink(index);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new),
                                SizedBox(width: 8),
                                Text('Abrir Link'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data desconhecida';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  Future<void> _openLink(String? url) async {
    if (url == null) return;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteLink(int index) async {
    final link = _savedLinks[index];
    final linkId = link['id'];
    
    if (linkId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('saved_product_links')
            .doc(linkId)
            .delete();
        
        setState(() {
          _savedLinks.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSaveForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Salvar Link do Produto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: 'Link do Produto',
              hintText: 'Cole aqui o link do produto do AliExpress',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Adicione observações sobre o produto',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProductLink,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: Text(_isLoading ? 'Salvando...' : 'Salvar Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductModal(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[100],
                ),
                child: images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            
            // Informações do produto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      basicInfo['title'] ?? 'Sem título',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ratings['avg_evaluation_rating'] ?? '0'}/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                    const SizedBox(height: 4),
                    if (variations.isNotEmpty)
                      Text(
                        '${variations.length} variações',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
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
    final variations = product['variations'] ?? [];
    final properties = product['properties'] ?? [];
    final images = product['images'] ?? [];
    final notes = product['notes'] ?? '';

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
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Avaliações
                    _buildInfoSection(
                      'Avaliações',
                      [
                        'Avaliação: ${ratings['avg_evaluation_rating'] ?? '0'}/5',
                        'Total de avaliações: ${ratings['evaluation_count'] ?? '0'}',
                        'Vendas: ${ratings['sales_count'] ?? '0'}',
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
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações do pacote
                    _buildInfoSection(
                      'Informações do Pacote',
                      [
                        'Peso: ${packageInfo['gross_weight'] ?? 'N/A'}',
                        'Dimensões: ${packageInfo['package_length'] ?? 'N/A'} x ${packageInfo['package_width'] ?? 'N/A'} x ${packageInfo['package_height'] ?? 'N/A'}',
                        'Tipo: ${packageInfo['package_type'] ?? 'N/A'}',
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Variações
                    if (variations.isNotEmpty)
                      _buildInfoSection(
                        'Variações (${variations.length})',
                        variations.take(5).map((variation) {
                          final skuProps = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
                          final props = skuProps.map((prop) => '${prop['sku_property_name']}: ${prop['sku_property_value']}').join(', ');
                          return 'SKU ${variation['sku_id']}: ${variation['offer_sale_price']} - ${props}';
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Propriedades
                    if (properties.isNotEmpty)
                      _buildInfoSection(
                        'Propriedades (${properties.length})',
                        properties.take(10).map((prop) => '${prop['attr_name']}: ${prop['attr_value']}').toList(),
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
            
            // Footer com botão de importar
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
