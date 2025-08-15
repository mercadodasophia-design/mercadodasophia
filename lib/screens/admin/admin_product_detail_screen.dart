import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/product_detail_service.dart';
import '../../services/aliexpress_service.dart';
import '../../config/api_config.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const AdminProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  bool _isLoadingDetails = false;
  bool _isImporting = false;
  bool _isImported = false;
  Map<String, dynamic> _completeProductData = {};
  Map<String, dynamic> _freightInfo = {};
  String? _errorMessage;
  String? _categoryName; // Nome da categoria buscado via API
  
  // Cache para traduções de atributos
  static final Map<String, String> _attributeTranslationCache = {};
  static final Map<String, String> _valueTranslationCache = {};
  static final AliExpressService _aliExpressService = AliExpressService();

  @override
  void initState() {
    super.initState();
    _loadCompleteProductDetails();
    _checkIfProductIsImported();
  }

  Future<void> _checkIfProductIsImported() async {
    final itemId = widget.product['itemId']?.toString();
    if (itemId == null || itemId.isEmpty) return;

    try {
      final existingProduct = await FirebaseFirestore.instance
          .collection('products')
          .where('aliexpress_id', isEqualTo: itemId)
          .get();

      if (existingProduct.docs.isNotEmpty) {
        setState(() {
          _isImported = true;
        });
      }
    } catch (e) {
      // Ignorar erro silenciosamente
      print('Erro ao verificar se produto foi importado: $e');
    }
  }

  Future<void> _loadCompleteProductDetails() async {
    final itemId = widget.product['itemId']?.toString();
    if (itemId == null || itemId.isEmpty) {
      setState(() {
        _errorMessage = 'ID do produto não encontrado';
      });
      return;
    }

    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      final result = await ProductDetailService.getCompleteProductDetails(itemId);
      
      setState(() {
        _isLoadingDetails = false;
        if (result['success'] == true) {
          _completeProductData = result['productDetails'] ?? {};
          _freightInfo = result['freightInfo'] ?? {};
        } else {
          _errorMessage = result['error'] ?? 'Erro ao carregar detalhes';
        }
      });
      
      // Buscar nome da categoria após carregar os detalhes
      await _loadCategoryName();
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
        _errorMessage = 'Erro: $e';
      });
    }
  }

  Future<void> _loadCategoryName() async {
    final basicInfo = _completeProductData['basic_info'] ?? {};
    final categoryId = basicInfo['category_id']?.toString() ?? '';
    
    if (categoryId.isNotEmpty && categoryId != '0') {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/aliexpress/category/$categoryId'),
        );
        
        if (response.statusCode == 200) {
          final categoryData = json.decode(response.body);
          if (categoryData['success'] == true) {
            final realCategoryName = categoryData['category_name']?.toString() ?? '';
            if (realCategoryName.isNotEmpty) {
              setState(() {
                _categoryName = realCategoryName;
              });
              print('✅ Categoria carregada: $realCategoryName');
            }
          }
        }
      } catch (e) {
        print('❌ Erro ao buscar categoria: $e');
      }
    }
  }

  Future<String> _createOrGetCategory(String categoryName, String aliexpressCategoryId) async {
    try {
      // Verificar se a categoria já existe
      final existingCategory = await FirebaseFirestore.instance
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (existingCategory.docs.isNotEmpty) {
        // Categoria já existe, retornar o ID
        final categoryId = existingCategory.docs.first.id;
        print('✅ Categoria existente encontrada: $categoryName (ID: $categoryId)');
        return categoryId;
      }

      // Categoria não existe, criar nova
      final newCategoryData = {
        'name': categoryName,
        'aliexpress_category_id': aliexpressCategoryId,
        'description': 'Categoria importada do AliExpress',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final newCategoryRef = await FirebaseFirestore.instance
          .collection('categories')
          .add(newCategoryData);

      print('✅ Nova categoria criada: $categoryName (ID: ${newCategoryRef.id})');
      return newCategoryRef.id;
    } catch (e) {
      print('❌ Erro ao criar/verificar categoria: $e');
      // Em caso de erro, retornar um ID vazio
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openInAliExpress(),
            tooltip: 'Abrir no AliExpress',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            _buildProductImage(),
            
            // Informações principais
            _buildMainInfo(),
            
            // Preços
            _buildPriceSection(),
            
            // Avaliações e vendas
            _buildRatingsSection(),
            
            // Indicador de carregamento de detalhes
            if (_isLoadingDetails)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Carregando detalhes completos...'),
                  ],
                ),
              ),
            
                        // Dados detalhados do produto
            _buildDetailedProductData(),
            
            // Botões de ação
            _buildActionButtons(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    // Coletar todas as imagens possíveis
    List<String> imageUrls = [];
    
    // Se temos dados completos, usar galeria completa
    if (_completeProductData.isNotEmpty) {
      imageUrls = ProductDetailService.extractImageGallery(_completeProductData);
    }
    
    // Fallback: usar imagem básica da busca
    if (imageUrls.isEmpty) {
      final mainImage = widget.product['itemMainPic'] ?? '';
      if (mainImage.isNotEmpty) {
        imageUrls.add(mainImage.startsWith('http') ? mainImage : 'https:$mainImage');
      }
    }
    
    // Imagens adicionais (se disponíveis)
    if (widget.product['itemImages'] != null) {
      final additionalImages = widget.product['itemImages'];
      if (additionalImages is List) {
        for (var img in additionalImages) {
          final imgUrl = img.toString();
          if (imgUrl.isNotEmpty) {
            imageUrls.add(imgUrl.startsWith('http') ? imgUrl : 'https:$imgUrl');
          }
        }
      }
    }
    
    // Outras possíveis fontes de imagens
    final otherImageFields = ['images', 'productImages', 'galleryImages', 'photos'];
    for (String field in otherImageFields) {
      if (widget.product[field] != null) {
        final imgs = widget.product[field];
        if (imgs is List) {
          for (var img in imgs) {
            final imgUrl = img.toString();
            if (imgUrl.isNotEmpty && !imageUrls.contains(imgUrl)) {
              imageUrls.add(imgUrl.startsWith('http') ? imgUrl : 'https:$imgUrl');
            }
          }
        } else if (imgs is String && imgs.isNotEmpty) {
          final imgUrl = imgs.startsWith('http') ? imgs : 'https:$imgs';
          if (!imageUrls.contains(imgUrl)) {
            imageUrls.add(imgUrl);
          }
        }
      }
    }
    
    // Se não tiver imagens, usar placeholder
    if (imageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }
    
    // Se tiver apenas uma imagem
    if (imageUrls.length == 1) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.network(
          imageUrls[0],
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            );
          },
        ),
      );
    }
    
    // Carrossel para múltiplas imagens
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          cs.CarouselSlider(
            options: cs.CarouselOptions(
              height: 300,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: imageUrls.length > 1,
              autoPlay: false,
            ),
            items: imageUrls.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
          // Indicador de quantidade de imagens
          if (imageUrls.length > 1)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${imageUrls.length} fotos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainInfo() {
    final title = widget.product['title'] ?? 
                 widget.product['itemTitle'] ?? 
                 widget.product['productTitle'] ?? 
                 widget.product['name'] ?? 
                 widget.product['productName'] ?? 
                 'Produto ${widget.product['itemId'] ?? 'sem ID'}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.product['itemId'] != null) ...[
            Row(
              children: [
                const Icon(Icons.tag, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'ID: ${widget.product['itemId']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preços',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Preço de venda
          if (widget.product['targetSalePrice'] != null) ...[
            Row(
              children: [
                const Icon(Icons.local_offer, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Preço de Venda: R\$ ${_formatPrice(widget.product['targetSalePrice'])}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Preço original
          if (widget.product['targetOriginalPrice'] != null) ...[
            Row(
              children: [
                const Icon(Icons.money_off, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Preço Original: R\$ ${_formatPrice(widget.product['targetOriginalPrice'])}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Desconto
          if (widget.product['discount'] != null && widget.product['discount'] != '0%') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Desconto: ${widget.product['discount']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Imposto estimado
          if (widget.product['targetSalePrice'] != null) ...[
            Row(
              children: [
                Icon(Icons.account_balance, size: 20, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Imposto Estimado: R\$ ${_calculateImportTax(_formatPrice(widget.product['targetSalePrice']))}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avaliações e Vendas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Avaliação
              if (widget.product['score'] != null || widget.product['evaluateRate'] != null) ...[
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatPrice(widget.product['score']) ?? _formatPrice(widget.product['evaluateRate']) ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Vendas
              if (widget.product['orders'] != null) ...[
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatPrice(widget.product['orders'])} vendas',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildDetailedProductData() {
    if (_completeProductData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              const Icon(Icons.info_outline, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Dados Detalhados do Produto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 1. INFORMAÇÕES BÁSICAS
          _buildBasicInfoSection(),
          const SizedBox(height: 16),
          
          // 2. ESTATÍSTICAS DO PRODUTO
          _buildProductStatsSection(),
          const SizedBox(height: 16),
          
          // 3. GALERIA DE IMAGENS
          _buildImageGallerySection(),
          const SizedBox(height: 16),
          
          // 4. VARIAÇÕES/SKUs
          _buildVariationsSection(),
          const SizedBox(height: 16),
          
          // 5. INFORMAÇÕES DE EMBALAGEM
          _buildPackageInfoSection(),
          const SizedBox(height: 16),
          
          // 6. INFORMAÇÕES DE LOGÍSTICA
          _buildLogisticsSection(),
          const SizedBox(height: 16),
          
          // 7. INFORMAÇÕES DE FRETE
          _buildFreightInfoSection(),
          const SizedBox(height: 16),
          
          // 8. INFORMAÇÕES DA LOJA
          _buildStoreInfoSection(),
          const SizedBox(height: 16),
          
          // 9. PROPRIEDADES DO PRODUTO
          _buildProductPropertiesSection(),
          const SizedBox(height: 16),
          
          // 10. DADOS BRUTOS (expandível)
          ExpansionTile(
            title: const Text('Dados Completos (Raw Data)'),
            children: [
              Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
                    child: Text(
                  _formatPrice(_completeProductData['raw_data']) ?? 'Nenhum dado disponível',
                      style: const TextStyle(
                          fontSize: 12,
                    fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final basicInfo = _completeProductData['basic_info'] ?? {};
    if (basicInfo.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.info,
      title: 'Informações Básicas',
      color: Colors.blue,
      children: [
        _buildInfoRow('Título', _formatPrice(basicInfo['title']) ?? 'N/A'),
        _buildInfoRow('ID do Produto', _formatPrice(basicInfo['product_id']) ?? 'N/A'),
        _buildInfoRowVertical('Descrição', _cleanHtmlDescription(_formatPrice(basicInfo['description']) ?? '')),
        _buildInfoRow('Imagem Principal', _getFirstImageUrl(_formatPrice(basicInfo['main_image']) ?? '')),
      ],
    );
  }

  Widget _buildProductStatsSection() {
    final baseInfo = _completeProductData['raw_data']?['ae_item_base_info_dto'] ?? {};
    if (baseInfo.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.bar_chart,
      title: 'Estatísticas do Produto',
      color: Colors.purple,
        children: [
        _buildInfoRow('Vendas', _formatPrice(baseInfo['sales_count']) ?? 'N/A'),
        _buildInfoRow('Avaliações', _formatPrice(baseInfo['evaluation_count']) ?? 'N/A'),
        _buildInfoRow('Média de Avaliação', _formatPrice(baseInfo['avg_evaluation_rating']) ?? 'N/A'),
        _buildInfoRow('Status do Produto', _formatPrice(baseInfo['product_status_type']) ?? 'N/A'),
        _buildInfoRow('Categoria', _categoryName ?? _formatPrice(baseInfo['category_id']) ?? 'N/A'),
      ],
    );
  }

  Widget _buildImageGallerySection() {
    final images = _completeProductData['images'] ?? [];
    if (images.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.photo_library,
      title: 'Galeria de Imagens',
      color: Colors.green,
                children: [
        _buildInfoRow('Quantidade', '${images.length.toString()} imagens'),
        const SizedBox(height: 8),
                  SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
                            itemCount: images.length.toInt(),
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 30),
                      );
                    },
                  ),
                ),
              );
            },
                    ),
                  ),
                ],
    );
  }

  Widget _buildVariationsSection() {
    final variations = _completeProductData['variations'] ?? [];
    if (variations.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.palette,
      title: 'Variações/SKUs',
      color: Colors.purple,
      children: [
        _buildInfoRow('Quantidade', '${variations.length.toString()} variações'),
        const SizedBox(height: 8),
        ...variations.take(10).map((variation) {
          final skuId = _formatPrice(variation['sku_id']) ?? 'N/A';
          final price = _formatPrice(variation['offer_sale_price']) ?? 'N/A';
          final stock = _formatPrice(variation['sku_available_stock']) ?? 'N/A';
          final properties = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
          
          String colorName = 'N/A';
          String sizeName = 'N/A';
          
          for (var prop in properties) {
            if (prop['sku_property_name'] == 'cor') {
              // Usar property_value_definition_name para cores corretas
              colorName = _formatPrice(prop['property_value_definition_name']) ?? 
                         _formatPrice(prop['sku_property_value']) ?? 'N/A';
            } else if (prop['sku_property_name'] == 'Tamanho') {
              // Usar property_value_definition_name para tamanhos corretos
              sizeName = _formatPrice(prop['property_value_definition_name']) ?? 
                        _formatPrice(prop['sku_property_value']) ?? 'N/A';
            }
          }
    
    return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                _buildInfoRow('SKU ID', skuId.toString()),
          Row(
            children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Cor',
                style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                decoration: BoxDecoration(
                              color: _getColorFromName(colorName),
                              borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                          ),
                    const SizedBox(width: 8),
                          Text(
                            colorName.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildInfoRow('Tamanho', sizeName.toString()),
                _buildInfoRow('Preço', 'R\$ ${_formatPrice(price)}'),
                _buildInfoRow('Estoque', _formatPrice(stock)),
              ],
            ),
          );
        }).toList(),
        if (variations.length.toInt() > 10) ...[
          const SizedBox(height: 8),
          Text(
            'E mais ${(variations.length - 10).toString()} variações...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPackageInfoSection() {
    final packageInfo = _completeProductData['raw_data']?['package_info_dto'] ?? {};
    if (packageInfo.isEmpty) return const SizedBox.shrink();

    // Verificar se há dados reais (não apenas valores padrão)
    final width = packageInfo['package_width'];
    final height = packageInfo['package_height'];
    final length = packageInfo['package_length'];
    final weight = packageInfo['gross_weight'];
    
    // Se todos os dados são muito genéricos, não mostrar a seção
    if ((width == null || width == 'N/A' || width == '' || width == 0) &&
        (height == null || height == 'N/A' || height == '' || height == 0) &&
        (length == null || length == 'N/A' || length == '' || length == 0) &&
        (weight == null || weight == 'N/A' || weight == '' || weight == 0)) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      icon: Icons.inventory,
      title: 'Informações de Embalagem',
      color: Colors.orange,
      children: [
        if (width != null && width != 'N/A' && width != '' && width != 0)
          _buildInfoRow('Largura', '${width.toString()} cm'),
        if (height != null && height != 'N/A' && height != '' && height != 0)
          _buildInfoRow('Altura', '${height.toString()} cm'),
        if (length != null && length != 'N/A' && length != '' && length != 0)
          _buildInfoRow('Comprimento', '${length.toString()} cm'),
        if (weight != null && weight != 'N/A' && weight != '' && weight != 0)
          _buildInfoRow('Peso Bruto', '${weight.toString()} kg'),
        if (packageInfo['package_type'] != null)
          _buildInfoRow('Tipo de Embalagem', packageInfo['package_type'] == false ? 'Padrão' : 'Especial'),
      ],
    );
  }

  Widget _buildLogisticsSection() {
    final logisticsInfo = _completeProductData['raw_data']?['logistics_info_dto'] ?? {};
    if (logisticsInfo.isEmpty) return const SizedBox.shrink();

    // Verificar se há dados reais (não apenas valores padrão)
    final deliveryTime = logisticsInfo['delivery_time'];
    final shipToCountry = logisticsInfo['ship_to_country'];
    
    // Se os dados são muito genéricos, não mostrar a seção
    if (deliveryTime == null || deliveryTime == 'N/A' || deliveryTime == '' ||
        shipToCountry == null || shipToCountry == 'N/A' || shipToCountry == '') {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      icon: Icons.local_shipping,
      title: 'Informações de Logística',
      color: Colors.teal,
      children: [
        _buildInfoRow('Tempo de Entrega', '${_formatPrice(deliveryTime)} dias'),
        _buildInfoRow('País de Destino', _translateCountry(_formatPrice(shipToCountry) ?? 'N/A')),
      ],
    );
  }

  Widget _buildFreightInfoSection() {
    if (_freightInfo.isEmpty) return const SizedBox.shrink();

    final success = _freightInfo['success'] ?? false;
    final freightOptions = _freightInfo['freight_options'] ?? [];
    final error = _freightInfo['error'];

    return _buildSectionCard(
      icon: Icons.local_shipping,
      title: 'Informações de Frete',
              color: success == true ? Colors.green : Colors.red,
      children: [
        _buildInfoRow('Status', success == true ? 'Disponível' : 'Indisponível'),
        if (error != null) _buildInfoRow('Erro', _formatPrice(error) ?? 'N/A'),
        if (freightOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Opções de Frete:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          ...freightOptions.map((option) {
            final serviceName = _formatPrice(option['service_name']) ?? 'N/A';
            final deliveryTime = _formatPrice(option['estimated_delivery_time']) ?? 'N/A';
            final freightAmount = _formatPrice(option['freight']?['amount']) ?? 'N/A';
            final currency = _formatPrice(option['freight']?['currency_code']) ?? 'USD';
    
    return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  _buildInfoRow('Serviço', serviceName.toString()),
                  _buildInfoRow('Tempo de Entrega', '${_formatPrice(deliveryTime)} dias'),
                  _buildInfoRow('Custo', '${_formatPrice(freightAmount)} ${currency.toString()}'),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildStoreInfoSection() {
    final storeInfo = _completeProductData['raw_data']?['ae_store_info'] ?? {};
    if (storeInfo.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.store,
      title: 'Informações da Loja',
      color: Colors.indigo,
      children: [
        _buildInfoRow('Nome da Loja', _formatPrice(storeInfo['store_name']) ?? 'N/A'),
        _buildInfoRow('ID da Loja', _formatPrice(storeInfo['store_id']) ?? 'N/A'),
        _buildInfoRow('País', _translateCountry(_formatPrice(storeInfo['store_country_code']) ?? 'N/A')),
        _buildInfoRow('Avaliação de Envio', _formatPrice(storeInfo['shipping_speed_rating']) ?? 'N/A'),
        _buildInfoRow('Avaliação de Comunicação', _formatPrice(storeInfo['communication_rating']) ?? 'N/A'),
        _buildInfoRow('Avaliação do Produto', _formatPrice(storeInfo['item_as_described_rating']) ?? 'N/A'),
      ],
    );
  }

  Widget _buildProductPropertiesSection() {
    final properties = _completeProductData['raw_data']?['ae_item_properties']?['ae_item_property'] ?? [];
    if (properties.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.category,
      title: 'Propriedades do Produto',
      color: Colors.red,
      children: [
        ...properties.map((prop) {
          final name = _translateAttributeName(_formatPrice(prop['attr_name']) ?? 'N/A');
          final value = _formatPrice(prop['attr_value']) ?? 'N/A';
          return _buildInfoRow(name, value);
        }).toList(),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
          ),
          Expanded(
            child: Text(
              value,
                              style: const TextStyle(fontSize: 12),
                            ),
                  ),
                ],
              ),
            );
  }

  Widget _buildInfoRowVertical(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
            label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }











  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botão para abrir no AliExpress
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInAliExpress,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver no AliExpress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Botão para importar produto
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting || _isImported ? null : _importProduct,
              icon: _isImporting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : _isImported 
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.add_shopping_cart),
              label: Text(
                _isImporting 
                    ? 'Importando...'
                    : _isImported 
                        ? 'Importado'
                        : 'Importar Produto'
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isImported ? Colors.grey : Colors.green,
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
    );
  }

  String _formatKey(String key) {
    // Converte camelCase para formato legível
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ')
        .trim();
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

  String _calculateImportTax(String priceStr) {
    try {
      final price = double.tryParse(priceStr) ?? 0.0;
      if (price <= 0) return '0.00';
      final estimatedTax = price * 0.90; // Estimativa de 90% para o Brasil
      return estimatedTax.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  void _openInAliExpress() {
    final itemUrl = widget.product['itemUrl'];
    if (itemUrl != null) {
      final fullUrl = itemUrl.toString().startsWith('http') 
          ? itemUrl.toString()
          : 'https:${itemUrl.toString()}';
      
      launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
    }
  }

  void _importProduct() {
    // Extrair informações importantes do produto
    final productId = widget.product['itemId']?.toString() ?? '';
    final title = widget.product['title'] ?? widget.product['itemTitle'] ?? 'Produto sem título';
    final price = _formatPrice(widget.product['targetSalePrice']);
    final imageUrl = widget.product['itemMainPic'] ?? '';
    
    // Mostrar diálogo de confirmação
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Importar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Título: $title'),
              const SizedBox(height: 8),
              Text('Preço: R\$ $price'),
              const SizedBox(height: 8),
              Text('ID: $productId'),
              const SizedBox(height: 16),
              const Text(
                'Este produto será adicionado ao seu catálogo. Deseja continuar?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performImport(productId, title, price, imageUrl);
              },
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performImport(String productId, String title, String price, String imageUrl) async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Verificar se o produto já foi importado
      final existingProduct = await FirebaseFirestore.instance
          .collection('products')
          .where('aliexpress_id', isEqualTo: productId)
          .get();

      if (existingProduct.docs.isNotEmpty) {
        // Produto já existe
        setState(() {
          _isImporting = false;
          _isImported = true; // Marcar como já importado
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto "$title" já foi importado anteriormente!'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Extrair informações de categoria
      final basicInfo = _completeProductData['basic_info'] ?? {};
      final categoryId = basicInfo['category_id']?.toString() ?? '';
      final categoryName = basicInfo['category_name']?.toString() ?? '';
      
      // Determinar categoria baseada no título se não houver categoria específica
      String determinedCategory = categoryName;
      if (determinedCategory.isEmpty) {
        final title = basicInfo['title']?.toString().toLowerCase() ?? '';
        if (title.contains('tapete') || title.contains('carpet') || title.contains('rug')) {
          determinedCategory = 'Tapetes e Carpetes';
        } else if (title.contains('roupa') || title.contains('vestido') || title.contains('camisa')) {
          determinedCategory = 'Roupas';
        } else if (title.contains('eletrônico') || title.contains('phone') || title.contains('laptop')) {
          determinedCategory = 'Eletrônicos';
        } else if (title.contains('casa') || title.contains('home') || title.contains('decor')) {
          determinedCategory = 'Casa e Decoração';
        } else {
          determinedCategory = 'Outros';
        }
      }
      
      // Se temos um category_id do AliExpress, vamos tentar buscar o nome real da categoria
      if (categoryId.isNotEmpty && categoryId != '0') {
        try {
          // Buscar categoria real do AliExpress
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/aliexpress/category/$categoryId'),
          );
          
          if (response.statusCode == 200) {
            final categoryData = json.decode(response.body);
            if (categoryData['success'] == true) {
              final realCategoryName = categoryData['category_name']?.toString() ?? '';
              if (realCategoryName.isNotEmpty) {
                determinedCategory = realCategoryName;
                print('✅ Categoria encontrada: $determinedCategory');
              } else {
                print('⚠️ Categoria não encontrada, usando detecção automática');
              }
            } else {
              print('❌ Erro ao buscar categoria: ${categoryData['message']}');
            }
          } else {
            print('❌ Erro HTTP ao buscar categoria: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Erro ao buscar categoria do AliExpress: $e');
        }
      }
      
      // Organizar variações por tamanho e cor
      final variations = _completeProductData['variations'] ?? [];
      final Map<String, Map<String, dynamic>> organizedVariations = {};
      
      // Primeiro, analisar se o produto tem tamanhos reais ou apenas cores
      bool hasRealSizes = false;
      Set<String> allSizes = {};
      Set<String> allColors = {};
      
      for (var variation in variations) {
        final properties = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
        
        for (var prop in properties) {
          final propName = prop['sku_property_name']?.toString() ?? '';
          final propValue = prop['sku_property_value']?.toString() ?? '';
          final propDefValue = prop['property_value_definition_name']?.toString() ?? '';
          
          if (propName == 'cor') {
            allColors.add(propValue.isNotEmpty ? propValue : propDefValue);
          } else if (propName == 'Tamanho' || propName == 'Size' || propName == 'tamanho') {
            final size = propDefValue.isNotEmpty ? propDefValue : propValue;
            if (size.isNotEmpty && size != 'N/A' && size != propValue) {
              // Só é tamanho real se for diferente da cor
              allSizes.add(size);
              hasRealSizes = true;
            }
          }
        }
      }
      
      // Verificar se os tamanhos são realmente diferentes das cores
      if (hasRealSizes) {
        bool sizesAreDifferent = false;
        for (String size in allSizes) {
          if (!allColors.contains(size)) {
            sizesAreDifferent = true;
            break;
          }
        }
        hasRealSizes = sizesAreDifferent;
      }
      
      print('🔍 Análise do produto:');
      print('  - Tem tamanhos reais: $hasRealSizes');
      print('  - Tamanhos encontrados: ${allSizes.join(', ')}');
      print('  - Cores encontradas: ${allColors.join(', ')}');
      
      if (!hasRealSizes) {
        // Produto sem tamanhos - organizar apenas por cores
        print('📦 Organizando por cores (sem tamanhos)');
        
        for (var variation in variations) {
          final properties = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
          
          String colorName = 'N/A';
          
          for (var prop in properties) {
            final propName = prop['sku_property_name']?.toString() ?? '';
            final propValue = prop['sku_property_value']?.toString() ?? '';
            final propDefValue = prop['property_value_definition_name']?.toString() ?? '';
            
            if (propName == 'cor') {
              colorName = propValue.isNotEmpty ? propValue : propDefValue;
            }
          }
          
          // Organizar por cor única
          if (!organizedVariations.containsKey(colorName)) {
            organizedVariations[colorName] = {
              'size': null, // Sem tamanho
              'colors': {},
            };
          }
          
          // Adicionar variação à cor
          organizedVariations[colorName]!['colors']![colorName] = {
            'sku_id': variation['sku_id'],
            'price': variation['offer_sale_price'],
            'original_price': variation['sku_price'],
            'stock': variation['sku_available_stock'],
            'color': colorName,
            'size': null, // Sem tamanho real
            'properties': properties,
          };
        }
      } else {
        // Produto com tamanhos - organizar por tamanho → cores
        print('📦 Organizando por tamanhos e cores');
        
        for (var variation in variations) {
          final properties = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
          
          String colorName = 'N/A';
          String sizeName = 'N/A';
          
          for (var prop in properties) {
            final propName = prop['sku_property_name']?.toString() ?? '';
            final propValue = prop['sku_property_value']?.toString() ?? '';
            final propDefValue = prop['property_value_definition_name']?.toString() ?? '';
            
            if (propName == 'cor') {
              colorName = propValue.isNotEmpty ? propValue : propDefValue;
            } else if (propName == 'Tamanho' || propName == 'Size' || propName == 'tamanho') {
              sizeName = propDefValue.isNotEmpty ? propDefValue : propValue;
            }
          }
          
          // Organizar por tamanho
          if (!organizedVariations.containsKey(sizeName)) {
            organizedVariations[sizeName] = {
              'size': sizeName,
              'colors': {},
            };
          }
          
          // Adicionar cor ao tamanho
          organizedVariations[sizeName]!['colors']![colorName] = {
            'sku_id': variation['sku_id'],
            'price': variation['offer_sale_price'],
            'original_price': variation['sku_price'],
            'stock': variation['sku_available_stock'],
            'color': colorName,
            'properties': properties,
          };
        }
      }
      
      // Converter para lista organizada
      final processedVariations = organizedVariations.values.toList();
      print('✅ Variações organizadas: ${processedVariations.length} grupos');

      // Criar/verificar categoria no Firebase
      final firebaseCategoryId = await _createOrGetCategory(determinedCategory, categoryId);

      // Salvar produto com variações processadas e categoria
      final productData = {
        'aliexpress_id': productId,
        'title': title,
        'price': price,
        'image_url': imageUrl,
        'category_name': determinedCategory,
        'category_id': firebaseCategoryId, // ID da categoria no Firebase
        'aliexpress_category_id': categoryId,
        'variations': processedVariations,
        'complete_data': _completeProductData,
        'freight_info': _freightInfo,
        'status': 'aguardando-revisao',
        'imported_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Salvar no Firebase
      await FirebaseFirestore.instance
          .collection('products')
          .add(productData);

      // Atualizar estado para importado
      setState(() {
        _isImporting = false;
        _isImported = true;
      });

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produto "$title" importado com sucesso!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // Resetar estado em caso de erro
      setState(() {
        _isImporting = false;
      });

      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar produto: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _cleanHtmlDescription(String htmlDescription) {
    if (htmlDescription.isEmpty) return 'N/A';
    
    // Remove tags HTML básicas
    String cleaned = htmlDescription
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove todas as tags HTML
        .replaceAll('&nbsp;', ' ') // Remove espaços HTML
        .replaceAll('&amp;', '&') // Remove entidades HTML
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
    
    // Limita o tamanho
    if (cleaned.length > 150) {
      cleaned = '${cleaned.substring(0, 150)}...';
    }
    
    return cleaned.isEmpty ? 'N/A' : cleaned;
  }

  String _getFirstImageUrl(String imageUrls) {
    if (imageUrls.isEmpty) return 'N/A';
    
    // Se contém ponto e vírgula, pega a primeira URL
    if (imageUrls.contains(';')) {
      final firstUrl = imageUrls.split(';').first;
      return firstUrl.isNotEmpty ? firstUrl : 'N/A';
    }
    
    // Se é uma única URL
    return imageUrls;
  }

  Color _getColorFromName(String colorName) {
    final name = colorName.toLowerCase();
    
    // Mapeamento de cores comuns
    switch (name) {
      case 'vermelho':
      case 'red':
        return Colors.red;
      case 'azul':
      case 'blue':
        return Colors.blue;
      case 'verde':
      case 'green':
        return Colors.green;
      case 'amarelo':
      case 'yellow':
        return Colors.yellow;
      case 'laranja':
      case 'orange':
        return Colors.orange;
      case 'rosa':
      case 'pink':
        return Colors.pink;
      case 'roxo':
      case 'purple':
      case 'violeta':
        return Colors.purple;
      case 'preto':
      case 'black':
        return Colors.black;
      case 'branco':
      case 'white':
        return Colors.white;
      case 'cinza':
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'marrom':
      case 'brown':
        return Colors.brown;
      case 'dourado':
      case 'gold':
        return Colors.amber;
      case 'prateado':
      case 'silver':
        return Colors.grey[400]!;
      case 'transparente':
      case 'transparent':
        return Colors.transparent;
      case 'multicor':
        return Colors.purple; // Cor padrão para multicor
      default:
        // Para cores não mapeadas, tenta gerar uma cor baseada no nome
        return _generateColorFromString(colorName);
    }
  }

  Color _generateColorFromString(String text) {
    // Gera uma cor baseada no hash da string
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Converte o hash em uma cor
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    );
  }

  String _translateCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'BR':
        return 'Brasil';
      case 'US':
        return 'Estados Unidos';
      case 'CA':
        return 'Canadá';
      case 'MX':
        return 'México';
      case 'AR':
        return 'Argentina';
      case 'CL':
        return 'Chile';
      case 'CO':
        return 'Colômbia';
      case 'PE':
        return 'Peru';
      case 'UY':
        return 'Uruguai';
      case 'PY':
        return 'Paraguai';
      case 'BO':
        return 'Bolívia';
      case 'EC':
        return 'Equador';
      case 'VE':
        return 'Venezuela';
      case 'GY':
        return 'Guiana';
      case 'SR':
        return 'Suriname';
      case 'GF':
        return 'Guiana Francesa';
      case 'CN':
        return 'China';
      case 'JP':
        return 'Japão';
      case 'KR':
        return 'Coreia do Sul';
      case 'IN':
        return 'Índia';
      case 'RU':
        return 'Rússia';
      case 'DE':
        return 'Alemanha';
      case 'FR':
        return 'França';
      case 'IT':
        return 'Itália';
      case 'ES':
        return 'Espanha';
      case 'GB':
        return 'Reino Unido';
      case 'AU':
        return 'Austrália';
             default:
         return countryCode; // Retorna o código se não encontrar tradução
     }
   }

   String _translateAttributeName(String attributeName) {
     // Tenta buscar na cache
     if (_attributeTranslationCache.containsKey(attributeName)) {
       return _attributeTranslationCache[attributeName]!;
     }

     // Se não estiver na cache, faz a chamada para o serviço de tradução
     final translatedName = _aliExpressService.translateAttributeName(attributeName);
     _attributeTranslationCache[attributeName] = translatedName;
     return translatedName;
  }
}