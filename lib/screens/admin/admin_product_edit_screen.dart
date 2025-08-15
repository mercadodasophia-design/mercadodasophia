import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import '../../services/aliexpress_service.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/product_detail_service.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import 'package:image_picker/image_picker.dart';
import '../../services/product_publishing_service.dart';
import '../../services/product_validation_service.dart';
import 'product_preview_modal.dart';
import 'admin_manage_products_screen.dart';

class AdminProductEditScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const AdminProductEditScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  bool _isLoadingDetails = false;
  bool _isSaving = false;
  bool _isAutoSaving = false;
  Map<String, dynamic> _completeProductData = {};
  Map<String, dynamic> _freightInfo = {};
  String? _errorMessage;
  
  // Auto-save
  Timer? _autoSaveTimer;
  String _sessionId = '';
  bool _hasUnsavedChanges = false;
  DateTime? _lastSaveTime;

  // Controllers para campos editáveis
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _warrantyController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _seoTitleController = TextEditingController();
  final TextEditingController _seoDescriptionController = TextEditingController();

  // Cache para traduções de atributos
  static final Map<String, String> _translationCache = {};
  static final AliExpressService _aliExpressService = AliExpressService();

  // Modal de edição de descrição
  bool _showDescriptionModal = false;
  Color _selectedColor = Colors.black;
  
      // Estados de formatação ativa
    bool _boldActive = false;
    bool _italicActive = false;
    bool _underlineActive = false;
    Color? _colorActive;
    double _fontSizeActive = 16.0;
    // Estados adicionais para fonte e tamanho
    String _fontFamilyActive = 'sans-serif';
    String _fontFamilyActiveLabel = 'Sans Serif';
    String _fontSizeLabel = 'Normal';
    
    // Quill Editor
  late QuillController _quillController;
  late FocusNode _quillFocusNode;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  
  // Publishing
  bool _isPublishing = false;


  @override
  void initState() {
    super.initState();
    _sessionId = _generateSessionId();
    _loadProductDetails();
    _initializeControllers();
    _initializeQuillController();
    _setupAutoSave();
    _addControllersListeners();
  }



  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _warrantyController.dispose();
    _shippingController.dispose();
    _tagsController.dispose();
    _keywordsController.dispose();
    _seoTitleController.dispose();
    _seoDescriptionController.dispose();
    _quillController.dispose();
    _quillFocusNode.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Prioriza draft_data se existir, senão usa dados originais
    final draftData = widget.product['draft_data'] ?? {};
    final sourceData = draftData.isNotEmpty ? draftData : widget.product;
    
    _nameController.text = sourceData['title'] ?? '';
    _priceController.text = sourceData['price'] ?? '';
    _originalPriceController.text = sourceData['original_price'] ?? '';
    _categoryController.text = sourceData['category'] ?? '';
    _brandController.text = sourceData['brand'] ?? '';
    _descriptionController.text = sourceData['description'] ?? '';
    _skuController.text = sourceData['sku'] ?? '';
    _weightController.text = sourceData['weight'] ?? '';
    _dimensionsController.text = sourceData['dimensions'] ?? '';
    _materialController.text = sourceData['material'] ?? '';
    _colorController.text = sourceData['color'] ?? '';
    _warrantyController.text = sourceData['warranty'] ?? '';
    _shippingController.text = sourceData['shipping'] ?? '';
    _tagsController.text = sourceData['tags'] ?? '';
    _keywordsController.text = sourceData['keywords'] ?? '';
    _seoTitleController.text = sourceData['seo_title'] ?? '';
    _seoDescriptionController.text = sourceData['seo_description'] ?? '';
    
    // Mostra indicador se há dados de draft
    if (draftData.isNotEmpty) {
      _hasUnsavedChanges = true;
      final lastEdit = draftData['last_edit'];
      if (lastEdit != null) {
        try {
          _lastSaveTime = DateTime.parse(lastEdit);
        } catch (_) {}
      }
    }
  }

  void _initializeQuillController() {
    _quillController = QuillController.basic();
    _quillFocusNode = FocusNode();
    
    // Tenta carregar delta do draft primeiro
    final draftData = widget.product['draft_data'] ?? {};
    final descriptionDelta = draftData['description_delta'] ?? 
                           _completeProductData['description_delta'];
    
    if (descriptionDelta != null) {
      try {
        _quillController.document = Document.fromJson(descriptionDelta);
      } catch (e) {
        // Se falhar, usa texto simples
        final description = _descriptionController.text;
    if (description.isNotEmpty) {
      _quillController.document = Document()..insert(0, description);
        }
      }
    } else {
      // Usa texto simples se não há delta
      final description = _descriptionController.text;
      if (description.isNotEmpty) {
        _quillController.document = Document()..insert(0, description);
      }
    }
    
    // Adiciona listener para atualizar estados de formatação
    _quillController.addListener(_updateActiveFormats);
    _quillController.addListener(() => _markAsChanged());
  }



  Future<void> _loadProductDetails() async {
    final aliexpressId = widget.product['aliexpress_id'];
    if (aliexpressId == null) return;

    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      final result = await ProductDetailService.getCompleteProductDetails(aliexpressId);
      
      setState(() {
        _isLoadingDetails = false;
        if (result['success'] == true) {
          _completeProductData = result['productDetails'] ?? {};
          _updateControllersWithCompleteData();
        } else {
          _errorMessage = result['error'] ?? 'Erro ao carregar detalhes';
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
        _errorMessage = 'Erro: $e';
      });
    }
  }

  String _cleanHtml(String html) {
    // Remove tags HTML básicas
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove todas as tags HTML
        .replaceAll('&nbsp;', ' ') // Substitui &nbsp; por espaço
        .replaceAll('&amp;', '&') // Substitui &amp; por &
        .replaceAll('&lt;', '<') // Substitui &lt; por <
        .replaceAll('&gt;', '>') // Substitui &gt; por >
        .replaceAll('&quot;', '"') // Substitui &quot; por "
        .replaceAll('&#39;', "'") // Substitui &#39; por '
        .trim(); // Remove espaços extras
  }

  void _updateControllersWithCompleteData() {
    final basicInfo = _completeProductData['basic_info'] ?? {};
    final rawData = _completeProductData['raw_data'] ?? {};
    final baseInfo = rawData['ae_item_base_info_dto'] ?? {};

    // Atualizar controllers com dados completos
    if (basicInfo['title'] != null) {
      _nameController.text = basicInfo['title'];
    }
    
    if (basicInfo['description'] != null) {
      _descriptionController.text = _cleanHtml(basicInfo['description']);
    }

    if (basicInfo['price'] != null) {
      _priceController.text = basicInfo['price'].toString();
    }

    if (basicInfo['original_price'] != null) {
      _originalPriceController.text = basicInfo['original_price'].toString();
    }

    if (baseInfo['category_id'] != null) {
      _categoryController.text = baseInfo['category_id'].toString();
    }

    // Extrair informações das propriedades
    final properties = rawData['ae_item_properties']?['ae_item_property'] ?? [];
    for (var prop in properties) {
      final attrName = prop['attr_name']?.toString().toLowerCase() ?? '';
      final attrValue = prop['attr_value']?.toString() ?? '';
      
      switch (attrName) {
        case 'brand':
          _brandController.text = attrValue;
          break;
        case 'material':
          _materialController.text = attrValue;
          break;
        case 'color':
          _colorController.text = attrValue;
          break;
        case 'weight':
          _weightController.text = attrValue;
          break;
        case 'dimensions':
          _dimensionsController.text = attrValue;
          break;
        case 'warranty':
          _warrantyController.text = attrValue;
          break;
        case 'shipping':
          _shippingController.text = attrValue;
          break;
      }
    }

    // Extrair SKU se disponível
    final skuInfo = rawData['ae_item_sku_info_dtos']?['ae_item_sku_info_d_t_o'] ?? [];
    if (skuInfo.isNotEmpty && skuInfo is List) {
      final firstSku = skuInfo.first;
      if (firstSku['sku_id'] != null) {
        _skuController.text = firstSku['sku_id'].toString();
      }
    }

    // Extrair tags e keywords se disponível
    if (baseInfo['keywords'] != null) {
      _keywordsController.text = baseInfo['keywords'].toString();
    }

    if (baseInfo['tags'] != null) {
      _tagsController.text = baseInfo['tags'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar Produto'),
            if (_hasUnsavedChanges || _isAutoSaving)
              Text(
                _isAutoSaving 
                  ? 'Salvando...' 
                  : _lastSaveTime != null 
                    ? 'Salvo ${_formatLastSaveTime()}'
                    : 'Alterações não salvas',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          if (_hasUnsavedChanges && !_isAutoSaving)
            IconButton(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Salvar rascunho',
            ),
          if (!_isLoadingDetails)
            TextButton.icon(
              onPressed: _showProductPreview,
              icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
              label: const Text(
                'Visualizar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: _isPublishing ? null : _showPublishingDialog,
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Publicar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do produto
                _buildProductImage(),
                
                // Informações principais (editáveis)
                _buildMainInfoEditable(),
                
                // Preços (editáveis)
                _buildPriceSectionEditable(),
                
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
                
                // Botão de salvar
                _buildSaveButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingDetails) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductDetails,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do produto
          _buildProductImage(),
          
          // Informações principais editáveis
          _buildMainInfoEditable(),
          
          // Preços editáveis
          _buildPriceSectionEditable(),
          
          // Avaliações e vendas (somente leitura)
          _buildRatingsSection(),
          
          // Dados detalhados completos (como na tela de detalhes)
          _buildDetailedProductDataComplete(),
          
          // Variações e cores
          _buildVariationsSection(),
          
          // SEO e palavras-chave
          _buildSEOSection(),
          
          // Botão de salvar
          _buildSaveButton(),
           
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
                  _completeProductData['raw_data']?.toString() ?? 'Nenhum dado disponível',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
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
      final mainImage = widget.product['itemMainPic'] ?? widget.product['image_url'] ?? '';
      if (mainImage.isNotEmpty) {
        imageUrls.add(mainImage.startsWith('http') ? mainImage : 'https:$mainImage');
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
      return Column(
        children: [
          Container(
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
          ),
          const SizedBox(height: 12),
          _buildImageThumbnails(imageUrls),
        ],
      );
    }
    
    // Se tiver múltiplas imagens, usar carousel
    return Column(
      children: [
        Container(
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
      child: cs.CarouselSlider(
        options: cs.CarouselOptions(
          height: 300,
          viewportFraction: 1.0,
          enableInfiniteScroll: imageUrls.length > 1,
          autoPlay: imageUrls.length > 1,
          autoPlayInterval: const Duration(seconds: 3),
        ),
        items: imageUrls.map((imageUrl) {
          return Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              );
            },
          );
        }).toList(),
      ),
        ),
        const SizedBox(height: 12),
        _buildImageThumbnails(imageUrls),
      ],
    );
  }

  // Widget para criar miniaturas de imagens com rolagem horizontal
  Widget _buildImageThumbnails(List<String> imageUrls) {
    return Column(
      children: [
        Container(
          height: 80,
          child: Stack(
            children: [
              // Lista horizontal de miniaturas
              ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length + _selectedImages.length,
                itemBuilder: (context, index) {
                  // Imagens existentes
                  if (index < imageUrls.length) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  
                  // Imagens selecionadas para upload
                  final selectedIndex = index - imageUrls.length;
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[selectedIndex],
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Botão de remover
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeSelectedImage(selectedIndex),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Botão de adicionar (fixo no canto direito)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: IconButton(
                    onPressed: _isUploadingImages ? null : _showImagePickerOptions,
                    icon: _isUploadingImages 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.add_photo_alternate, color: Colors.blue[600], size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Mostrar opções de seleção de imagem
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecionar Imagem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_camera,
                    label: 'Múltiplas',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMultipleImages();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Widget para opção de imagem
  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Icon(icon, color: Colors.blue[600], size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Selecionar imagem da câmera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _hasUnsavedChanges = true;
        });
        _saveDraft();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar imagem: $e')),
      );
    }
  }

  // Selecionar imagem da galeria
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _hasUnsavedChanges = true;
        });
        _saveDraft();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  // Selecionar múltiplas imagens da galeria
  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _selectedImages.add(File(image.path));
          }
          _hasUnsavedChanges = true;
        });
        _saveDraft();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagens: $e')),
      );
    }
  }

  // Remover imagem selecionada
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _hasUnsavedChanges = true;
    });
    _saveDraft();
  }



  Widget _buildMainInfoEditable() {
    return Container(
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
              Icon(Icons.info, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Informações Básicas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Título do Produto',
            hint: 'Digite o título do produto',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showDescriptionEditor,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Descrição',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.isNotEmpty 
                        ? _descriptionController.text
                        : 'Toque para editar a descrição completa do produto...',
                    style: TextStyle(
                      fontSize: 14,
                      color: _descriptionController.text.isNotEmpty 
                          ? Colors.black87 
                          : Colors.grey[500],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSectionEditable() {
    return Container(
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
              Icon(Icons.attach_money, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Preços',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Preço (R\$)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _originalPriceController,
                  label: 'Preço Original',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    final basicInfo = _completeProductData['basic_info'] ?? {};
    final rating = basicInfo['rating'] ?? widget.product['rating'] ?? 'N/A';
    final reviewCount = basicInfo['review_count'] ?? widget.product['review_count'] ?? 'N/A';
    final salesCount = basicInfo['sales_count'] ?? widget.product['sales_count'] ?? 'N/A';

    return Container(
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
              Icon(Icons.star, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Avaliações e Vendas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('Avaliação', rating.toString(), Icons.star),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('Avaliações', reviewCount.toString(), Icons.rate_review),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('Vendas', salesCount.toString(), Icons.shopping_cart),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedProductDataEditable() {
    return Container(
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
              Icon(Icons.settings, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Especificações Detalhadas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _categoryController,
                  label: 'Categoria',
                  hint: 'Digite a categoria',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _brandController,
                  label: 'Marca',
                  hint: 'Digite a marca',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _skuController,
                  label: 'SKU',
                  hint: 'Código do produto',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Peso',
                  hint: 'Ex: 500g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _dimensionsController,
                  label: 'Dimensões',
                  hint: 'Ex: 10x20x30cm',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _materialController,
                  label: 'Material',
                  hint: 'Ex: Plástico',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _colorController,
                  label: 'Cor',
                  hint: 'Ex: Preto',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _warrantyController,
                  label: 'Garantia',
                  hint: 'Ex: 1 ano',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _shippingController,
                  label: 'Informações de Envio',
                  hint: 'Ex: Frete grátis',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _tagsController,
                  label: 'Tags',
                  hint: 'Ex: eletrônico, tecnologia',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _keywordsController,
            label: 'Palavras-chave',
            hint: 'Ex: smartphone, celular',
          ),
        ],
      ),
    );
  }

  Widget _buildSEOSection() {
    return Container(
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
              Icon(Icons.search, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'SEO e Palavras-chave',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _seoTitleController,
            label: 'Título SEO',
            hint: 'Título otimizado para busca (máx. 60 caracteres)',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _seoDescriptionController,
            label: 'Descrição SEO',
            hint: 'Descrição otimizada para busca (máx. 160 caracteres)',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _keywordsController,
            label: 'Palavras-chave',
            hint: 'Ex: smartphone, celular, tecnologia (separadas por vírgula)',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Dica: Use palavras-chave relevantes separadas por vírgula para melhorar a busca do produto',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsSection() {
    final variations = _completeProductData['variations'] ?? [];
    final rawData = _completeProductData['raw_data'] ?? {};
    final skuInfo = rawData['ae_item_sku_info_dtos']?['ae_item_sku_info_d_t_o'] ?? [];
    
    // Se não há variações nem SKUs, não mostrar a seção
    if ((variations.isEmpty || variations == []) && 
        (skuInfo.isEmpty || skuInfo == [])) {
      return const SizedBox.shrink();
    }

    return Container(
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
              Icon(Icons.palette, color: Colors.pink, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Variações e Cores (Editável)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showVariationsEditor(),
                icon: Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Editar Variações',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Variações do AliExpress
          if (variations.isNotEmpty && variations != []) ...[
            const Text(
              'Variações Disponíveis:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...variations.take(5).map((variation) {
              final skuId = variation['sku_id'] ?? 'N/A';
              final price = variation['offer_sale_price'] ?? 'N/A';
              final stock = variation['sku_available_stock'] ?? 'N/A';
              final properties = variation['ae_sku_property_dtos']?['ae_sku_property_d_t_o'] ?? [];
              
              String colorName = 'N/A';
              String sizeName = 'N/A';
              
              for (var prop in properties) {
                if (prop['sku_property_name'] == 'cor') {
                  colorName = prop['sku_property_value'] ?? 'N/A';
                } else if (prop['sku_property_name'] == 'Tamanho') {
                  sizeName = prop['sku_property_value'] ?? 'N/A';
                }
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SKU ID: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(skuId),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                                colorName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Tamanho: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(sizeName),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Preço: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('R\$ $price'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Estoque: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(stock.toString()),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            if (variations.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                'E mais ${variations.length - 5} variações...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _formatAttributes(String attributes) {
    try {
      // Se for JSON, tentar fazer parse
      if (attributes.startsWith('{') || attributes.startsWith('[')) {
        final decoded = json.decode(attributes);
        if (decoded is Map) {
          return decoded.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
        } else if (decoded is List) {
          return decoded.join(', ');
        }
      }
      
      // Usar o serviço de tradução do AliExpress
      final result = _translateAttributesWithAPI(attributes);
      return result;
      
    } catch (e) {
      return attributes; // Retornar original em caso de erro
    }
  }

  String _translateAttributesWithAPI(String attributes) {
    // Verificar cache primeiro
    if (_translationCache.containsKey(attributes)) {
      return _translationCache[attributes]!;
    }
    
    // Fazer tradução local imediatamente como fallback
    final localTranslation = _translateAttributesLocal(attributes);
    _translationCache[attributes] = localTranslation;
    
    // Fazer chamada assíncrona para melhorar a tradução
    _callTranslationAPI(attributes).then((translated) {
      if (translated != attributes) {
        _translationCache[attributes] = translated;
        // Forçar rebuild se o widget ainda estiver ativo
        if (mounted) {
          setState(() {});
        }
      }
    }).catchError((e) {
      // print('❌ Erro na tradução via API: $e'); // Original print removed
    });
    
    return localTranslation;
  }

  Future<String> _callTranslationAPI(String attributes) async {
    try {
      final aliExpressService = AliExpressService();
      final translatedAttributes = await aliExpressService.translateAttributes([attributes]);
      
      if (translatedAttributes.isNotEmpty) {
        final translated = translatedAttributes.first;
        final translatedCode = translated['translated_code'] ?? '';
        final translatedValue = translated['translated_value'] ?? '';
        
        if (translatedCode.isNotEmpty && translatedValue.isNotEmpty) {
          return '$translatedCode: $translatedValue';
        } else if (translatedCode.isNotEmpty) {
          return translatedCode;
        } else {
          return attributes;
        }
      }
      
      return attributes;
    } catch (e) {
      return attributes;
    }
  }

  String _translateAttributesLocal(String attributes) {
    // Fallback local para tradução
    final attributeMap = {
      '14': 'Tamanho',
      '29': 'Cor',
      '977': 'Tipo',
      '13143': 'Cor',
      '13144': 'Tamanho',
      '13145': 'Material',
      '13146': 'Estilo',
      '13147': 'Padrão',
      '13148': 'Tipo',
      '13149': 'Forma',
      '13150': 'Função',
      '13151': 'Característica',
      '13152': 'Especificação',
      '13153': 'Modelo',
      '13154': 'Versão',
      '13155': 'Edição',
      '13156': 'Série',
      '13157': 'Coleção',
      '13158': 'Linha',
      '13159': 'Família',
      '13160': 'Categoria',
      '13161': 'Gênero',
      '13162': 'Idade',
      '13163': 'Ocasião',
      '13164': 'Tecnologia',
      '13165': 'Compatibilidade',
      '13166': 'Certificação',
      '13167': 'Origem',
      '13168': 'Marca',
      '13169': 'Fabricante',
      '13170': 'Garantia',
      '13171': 'Peso',
      '13172': 'Dimensões',
      '13173': 'Potência',
      '13174': 'Voltagem',
      '13175': 'Frequência',
      '13176': 'Capacidade',
      '13177': 'Velocidade',
      '13178': 'Resolução',
      '13179': 'Memória',
      '13180': 'Processador',
      '13181': 'Sistema Operacional',
      '13182': 'Conectividade',
      '13183': 'Bateria',
      '13184': 'Display',
      '13185': 'Câmera',
      '13186': 'Áudio',
      '13187': 'Sensor',
      '13188': 'Interface',
      '13189': 'Porta',
      '13190': 'Cabo',
      '13191': 'Adaptador',
      '13192': 'Suporte',
      '13193': 'Instrução',
      '13194': 'Manual',
      '13195': 'Embalagem',
      '13196': 'Acessório',
      '13197': 'Peça',
      '13198': 'Componente',
      '13199': 'Kit',
      '13200': 'Conjunto',
      '200003528': 'Categoria Específica',
      '200003529': 'Subcategoria',
      '200003530': 'Variante',
      '200003531': 'Opção',
      '200003532': 'Configuração',
      '200003533': 'Versão',
      '200003534': 'Edição',
      '200003535': 'Série',
      '200003536': 'Coleção',
      '200003537': 'Linha',
      '200003538': 'Família',
      '200003539': 'Gênero',
      '200003540': 'Idade',
      '200003541': 'Ocasião',
      '200003542': 'Tecnologia',
      '200003543': 'Compatibilidade',
      '200003544': 'Certificação',
      '200003545': 'Origem',
      '200003546': 'Marca',
      '200003547': 'Fabricante',
      '200003548': 'Garantia',
      '200003549': 'Peso',
      '200003550': 'Dimensões',
      // Códigos específicos mencionados pelo usuário
      '200001438': 'Cor Específica',
      '200001439': 'Tamanho Específico',
      '200001440': 'Material Específico',
      '200001441': 'Estilo Específico',
      '200001442': 'Padrão Específico',
      '200001443': 'Tipo Específico',
      '200001444': 'Forma Específica',
      '200001445': 'Função Específica',
      '200001446': 'Característica Específica',
      '200001447': 'Especificação Específica',
      '200001448': 'Modelo Específico',
      '200001449': 'Versão Específica',
      '200001450': 'Edição Específica',
      '200001451': 'Série Específica',
      '200001452': 'Coleção Específica',
      '200001453': 'Linha Específica',
      '200001454': 'Família Específica',
      '200001455': 'Categoria Específica',
      '200001456': 'Gênero Específico',
      '200001457': 'Idade Específica',
      '200001458': 'Ocasião Específica',
      '200001459': 'Tecnologia Específica',
      '200001460': 'Compatibilidade Específica',
      '200001461': 'Certificação Específica',
      '200001462': 'Origem Específica',
      '200001463': 'Marca Específica',
      '200001464': 'Fabricante Específico',
      '200001465': 'Garantia Específica',
      '200001466': 'Peso Específico',
      '200001467': 'Dimensões Específicas',
      '200001468': 'Potência Específica',
      '200001469': 'Voltagem Específica',
      '200001470': 'Frequência Específica',
      '200001471': 'Capacidade Específica',
      '200001472': 'Velocidade Específica',
      '200001473': 'Resolução Específica',
      '200001474': 'Memória Específica',
      '200001475': 'Processador Específico',
      '200001476': 'Sistema Operacional Específico',
      '200001477': 'Conectividade Específica',
      '200001478': 'Bateria Específica',
      '200001479': 'Display Específico',
      '200001480': 'Câmera Específica',
      '200001481': 'Áudio Específico',
      '200001482': 'Sensor Específico',
      '200001483': 'Interface Específica',
      '200001484': 'Porta Específica',
      '200001485': 'Cabo Específico',
      '200001486': 'Adaptador Específico',
      '200001487': 'Suporte Específico',
      '200001488': 'Instrução Específica',
      '200001489': 'Manual Específico',
      '200001490': 'Embalagem Específica',
      '200001491': 'Acessório Específico',
      '200001492': 'Peça Específica',
      '200001493': 'Componente Específico',
      '200001494': 'Kit Específico',
      '200001495': 'Conjunto Específico',
    };

    // Traduzir valores comuns
    final valueMap = {
      'red': 'Vermelho',
      'blue': 'Azul',
      'green': 'Verde',
      'yellow': 'Amarelo',
      'black': 'Preto',
      'white': 'Branco',
      'pink': 'Rosa',
      'purple': 'Roxo',
      'orange': 'Laranja',
      'brown': 'Marrom',
      'gray': 'Cinza',
      'grey': 'Cinza',
      'verde': 'Verde',
      'vermelho': 'Vermelho',
      'azul': 'Azul',
      'amarelo': 'Amarelo',
      'preto': 'Preto',
      'branco': 'Branco',
      'rosa': 'Rosa',
      'roxo': 'Roxo',
      'laranja': 'Laranja',
      'marrom': 'Marrom',
      'cinza': 'Cinza',
      'xs': 'Extra Pequeno',
      's': 'Pequeno',
      'm': 'Médio',
      'l': 'Grande',
      'xl': 'Extra Grande',
      'xxl': 'Extra Extra Grande',
      'cotton': 'Algodão',
      'polyester': 'Poliéster',
      'wool': 'Lã',
      'silk': 'Seda',
      'leather': 'Couro',
      'plastic': 'Plástico',
      'metal': 'Metal',
      'wood': 'Madeira',
      'glass': 'Vidro',
      'ceramic': 'Cerâmica',
    };

    // Processar string de atributos
    final parts = attributes.split(';');
    final translatedParts = <String>[];

    for (final part in parts) {
      if (part.contains('#')) {
        final codeValue = part.split('#');
        if (codeValue.length == 2) {
          final code = codeValue[0].trim();
          final value = codeValue[1].trim();
          
          final translatedCode = attributeMap[code] ?? 'Atributo $code';
          final translatedValue = valueMap[value.toLowerCase()] ?? value;
          
          translatedParts.add('$translatedCode: $translatedValue');
        } else {
          translatedParts.add(part);
        }
      } else if (part.contains(':')) {
        // Contar quantos ':' existem
        final colonCount = part.split(':').length - 1;
        
        if (colonCount == 1) {
          // Formato: "13143:Red"
          final codeValue = part.split(':');
          if (codeValue.length == 2) {
            final code = codeValue[0].trim();
            final value = codeValue[1].trim();
            
            final translatedCode = attributeMap[code] ?? 'Atributo $code';
            final translatedValue = valueMap[value.toLowerCase()] ?? value;
            
            translatedParts.add('$translatedCode: $translatedValue');
          } else {
            translatedParts.add(part);
          }
        } else if (colonCount == 2) {
          // Formato: "14:200001438: verde" - onde o valor já está em português
          final parts_split = part.split(':');
          if (parts_split.length == 3) {
            final code = parts_split[0].trim();
            final sub_code = parts_split[1].trim();
            final value = parts_split[2].trim();
            
            final translatedCode = attributeMap[code] ?? 'Atributo $code';
            // Se o valor já está em português, não traduzir
            final translatedValue = valueMap[value.toLowerCase()] ?? value;
            
            translatedParts.add('$translatedCode: $translatedValue');
          } else {
            translatedParts.add(part);
          }
        } else {
          // Código simples sem valor
          final code = part.trim();
          final translatedCode = attributeMap[code] ?? 'Atributo $code';
          translatedParts.add(translatedCode);
        }
      } else {
        // Código simples sem valor
        final code = part.trim();
        final translatedCode = attributeMap[code] ?? 'Atributo $code';
        translatedParts.add(translatedCode);
      }
    }

    return translatedParts.join(', ');
  }

  String _translateAttributeName(String attributeName) {
    // Tenta buscar na cache
    if (_translationCache.containsKey(attributeName)) {
      return _translationCache[attributeName]!;
    }

    // Se não estiver na cache, faz a chamada para o serviço de tradução
    final translatedName = _aliExpressService.translateAttributeName(attributeName);
    _translationCache[attributeName] = translatedName;
    return translatedName;
  }

  Color _parseColor(String colorString) {
    try {
      // Tentar converter cores comuns
      final colorMap = {
        'red': Colors.red,
        'blue': Colors.blue,
        'green': Colors.green,
        'yellow': Colors.yellow,
        'black': Colors.black,
        'white': Colors.white,
        'gray': Colors.grey,
        'grey': Colors.grey,
        'orange': Colors.orange,
        'purple': Colors.purple,
        'pink': Colors.pink,
        'brown': Colors.brown,
        'cyan': Colors.cyan,
        'teal': Colors.teal,
        'indigo': Colors.indigo,
        'lime': Colors.lime,
        'amber': Colors.amber,
        'deeporange': Colors.deepOrange,
        'lightblue': Colors.lightBlue,
        'lightgreen': Colors.lightGreen,
        'lightpink': Colors.pink[100]!,
        'lightyellow': Colors.yellow[100]!,
      };
      
      final lowerColor = colorString.toLowerCase();
      if (colorMap.containsKey(lowerColor)) {
        return colorMap[lowerColor]!;
      }
      
      // Se não encontrar, retornar cinza
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('Salvando...'),
                  ],
                )
              : const Text(
                  'Salvar Produto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildCompleteDataSection() {
    return _buildSection(
      title: 'Dados do AliExpress',
      icon: Icons.data_usage,
      color: Colors.purple,
      children: [
        ExpansionTile(
          title: const Text('Dados Completos'),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _completeProductData.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =================== PREVIEW FUNCTION ===================
  
  void _showProductPreview() {
    // Primeiro salva o draft atual
    _saveDraft();
    
    // Coleta dados atuais do formulário
    final currentProductData = {
      'id': widget.product['id'],
      'title': _nameController.text.trim(),
      'price': _priceController.text.trim(),
      'original_price': _originalPriceController.text.trim(),
      'category': _categoryController.text.trim(),
      'brand': _brandController.text.trim(),
      'image_url': widget.product['image_url'],
      'description': _descriptionController.text.trim(),
      'sku': _skuController.text.trim(),
      'weight': _weightController.text.trim(),
      'dimensions': _dimensionsController.text.trim(),
      'material': _materialController.text.trim(),
      'color': _colorController.text.trim(),
      'warranty': _warrantyController.text.trim(),
      'shipping': _shippingController.text.trim(),
      'tags': _tagsController.text.trim(),
      'keywords': _keywordsController.text.trim(),
    };
    
    // Abre o modal de preview
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductPreviewModal(
          productData: currentProductData,
          completeData: _completeProductData,
          quillController: _quillController,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // =================== AUTO-SAVE FUNCTIONS ===================
  
  String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  String _formatLastSaveTime() {
    if (_lastSaveTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSaveTime!);
    
    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else {
      return 'há ${difference.inDays}d';
    }
  }
  
  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasUnsavedChanges && !_isAutoSaving) {
        _saveDraft();
      }
    });
  }
  
  void _addControllersListeners() {
    _nameController.addListener(_markAsChanged);
    _priceController.addListener(_markAsChanged);
    _originalPriceController.addListener(_markAsChanged);
    _categoryController.addListener(_markAsChanged);
    _brandController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _skuController.addListener(_markAsChanged);
    _weightController.addListener(_markAsChanged);
    _dimensionsController.addListener(_markAsChanged);
    _materialController.addListener(_markAsChanged);
    _colorController.addListener(_markAsChanged);
    _warrantyController.addListener(_markAsChanged);
    _shippingController.addListener(_markAsChanged);
    _tagsController.addListener(_markAsChanged);
    _keywordsController.addListener(_markAsChanged);
    _seoTitleController.addListener(_markAsChanged);
    _seoDescriptionController.addListener(_markAsChanged);
  }
  
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }
  
  Future<void> _saveDraft() async {
    if (_isAutoSaving) return;
    
    setState(() {
      _isAutoSaving = true;
    });
    
    try {
      final productId = widget.product['id'];
      
      // Salvar conteúdo do Quill primeiro
      final deltaJson = _quillController.document.toDelta().toJson();
      final plainText = _quillController.document.toPlainText();
      
      final draftData = {
        'title': _nameController.text.trim(),
        'description': plainText,
        'description_delta': deltaJson,
        'price': _priceController.text.trim(),
        'original_price': _originalPriceController.text.trim(),
        'category': _categoryController.text.trim(),
        'brand': _brandController.text.trim(),
        'sku': _skuController.text.trim(),
        'weight': _weightController.text.trim(),
        'dimensions': _dimensionsController.text.trim(),
        'material': _materialController.text.trim(),
        'color': _colorController.text.trim(),
        'warranty': _warrantyController.text.trim(),
        'shipping': _shippingController.text.trim(),
        'tags': _tagsController.text.trim(),
        'keywords': _keywordsController.text.trim(),
        'last_edit': DateTime.now().toIso8601String(),
        'editor_session_id': _sessionId,
      };
      
      // Salvar no Firebase
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
            'draft_data': draftData,
            'has_unsaved_changes': true,
            'status': widget.product['status'] ?? 'draft',
          });
      
      setState(() {
        _lastSaveTime = DateTime.now();
        _hasUnsavedChanges = false;
      });
      
    } catch (e) {
      print('Erro ao salvar draft: $e');
    } finally {
      setState(() {
        _isAutoSaving = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Título é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final productId = widget.product['id'];
      
      // Preparar dados para salvar
      final productData = {
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'description_delta': _completeProductData['description_delta'],
        'price': _priceController.text.trim(),
        'original_price': _originalPriceController.text.trim(),
        'category': _categoryController.text.trim(),
        'brand': _brandController.text.trim(),
        'sku': _skuController.text.trim(),
        'weight': _weightController.text.trim(),
        'dimensions': _dimensionsController.text.trim(),
        'material': _materialController.text.trim(),
        'color': _colorController.text.trim(),
        'warranty': _warrantyController.text.trim(),
        'shipping': _shippingController.text.trim(),
        'tags': _tagsController.text.trim(),
        'keywords': _keywordsController.text.trim(),
        'status': 'aguardando-revisao',
        'updated_at': DateTime.now().toIso8601String(),
        'complete_data': _completeProductData,
      };

      // Salvar no Firebase e limpar draft
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
            ...productData,
            'draft_data': FieldValue.delete(), // Remove draft ao publicar
            'has_unsaved_changes': false,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Voltar para a tela anterior
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar produto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildDetailedProductDataComplete() {
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
                  _completeProductData['raw_data']?.toString() ?? 'Nenhum dado disponível',
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
        _buildInfoRow('Título', basicInfo['title'] ?? 'N/A'),
        _buildInfoRow('ID do Produto', basicInfo['product_id'] ?? 'N/A'),
        _buildInfoRowVertical('Descrição', _cleanHtmlDescription(basicInfo['description']?.toString() ?? '')),
        _buildInfoRow('Imagem Principal', _getFirstImageUrl(basicInfo['main_image'] ?? '')),
      ],
    );
  }

  // Função para traduzir o status do produto
  String _translateProductStatus(String status) {
    switch (status.toLowerCase()) {
      case 'on_sale':
        return 'Em Venda';
      case 'onselling':
        return 'Em Venda';
      case 'off_shelf':
        return 'Fora de Estoque';
      case 'deleted':
        return 'Deletado';
      case 'expired':
        return 'Expirado';
      case 'inactive':
        return 'Inativo';
      case 'active':
        return 'Ativo';
      case 'pending':
        return 'Pendente';
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      case 'draft':
        return 'Rascunho';
      case 'published':
        return 'Publicado';
      case 'unpublished':
        return 'Não Publicado';
      case 'suspended':
        return 'Suspenso';
      case 'banned':
        return 'Banido';
      case 'under_review':
        return 'Em Revisão';
      case 'ready':
        return 'Pronto';
      case 'processing':
        return 'Processando';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      case 'failed':
        return 'Falhou';
      case 'n/a':
      case 'na':
        return 'Não Disponível';
      default:
        return status; // Retorna o valor original se não encontrar tradução
    }
  }

  Widget _buildProductStatsSection() {
    final baseInfo = _completeProductData['raw_data']?['ae_item_base_info_dto'] ?? {};
    if (baseInfo.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.bar_chart,
      title: 'Estatísticas do Produto',
      color: Colors.purple,
      children: [
        _buildInfoRow('Vendas', baseInfo['sales_count']?.toString() ?? 'N/A'),
        _buildInfoRow('Avaliações', baseInfo['evaluation_count']?.toString() ?? 'N/A'),
        _buildInfoRow('Média de Avaliação', baseInfo['avg_evaluation_rating']?.toString() ?? 'N/A'),
        _buildInfoRow('Status do Produto', _translateProductStatus(baseInfo['product_status_type']?.toString() ?? 'N/A')),
        _buildInfoRow('Categoria ID', baseInfo['category_id']?.toString() ?? 'N/A'),
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
        _buildInfoRow('Quantidade', '${images.length} imagens'),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
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
          _buildInfoRow('Largura', '${width} cm'),
        if (height != null && height != 'N/A' && height != '' && height != 0)
          _buildInfoRow('Altura', '${height} cm'),
        if (length != null && length != 'N/A' && length != '' && length != 0)
          _buildInfoRow('Comprimento', '${length} cm'),
        if (weight != null && weight != 'N/A' && weight != '' && weight != 0)
          _buildInfoRow('Peso Bruto', '${weight} kg'),
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
        _buildInfoRow('Tempo de Entrega', '${deliveryTime} dias'),
        _buildInfoRow('País de Destino', _translateCountry(shipToCountry)),
      ],
    );
  }

  Widget _buildFreightInfoSection() {
    final freightInfo = _completeProductData['freight_info'] ?? {};
    if (freightInfo.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.local_shipping,
      title: 'Informações de Frete',
      color: Colors.indigo,
      children: [
        if (freightInfo['freight_options'] != null) ...[
          _buildInfoRow('Opções de Frete', '${freightInfo['freight_options'].length} opções'),
          const SizedBox(height: 8),
          ...freightInfo['freight_options'].take(3).map((option) {
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
                  _buildInfoRow('Serviço', option['service_name'] ?? 'N/A'),
                  _buildInfoRow('Preço', 'R\$ ${option['freight_amount'] ?? 'N/A'}'),
                  _buildInfoRow('Prazo', '${option['delivery_time'] ?? 'N/A'} dias'),
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
        _buildInfoRow('Nome da Loja', storeInfo['store_name'] ?? 'N/A'),
        _buildInfoRow('ID da Loja', storeInfo['store_id']?.toString() ?? 'N/A'),
        _buildInfoRow('País', _translateCountry(storeInfo['store_country_code'] ?? 'N/A')),
        _buildInfoRow('Avaliação de Envio', storeInfo['shipping_speed_rating'] ?? 'N/A'),
        _buildInfoRow('Avaliação de Comunicação', storeInfo['communication_rating'] ?? 'N/A'),
        _buildInfoRow('Avaliação do Produto', storeInfo['item_as_described_rating'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildProductPropertiesSection() {
    final properties = _completeProductData['raw_data']?['ae_item_properties']?['ae_item_property'] ?? [];
    if (properties.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.settings,
      title: 'Propriedades do Produto',
      color: Colors.deepPurple,
      children: [
        ...properties.map((prop) {
          final attrName = prop['attr_name'] ?? 'N/A';
          final attrValue = prop['attr_value'] ?? 'N/A';
          return _buildInfoRow(_translateAttributeName(attrName), attrValue);
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildInfoRowVertical(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _cleanHtmlDescription(String html) {
    if (html.isEmpty) return 'N/A';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _getFirstImageUrl(String imageData) {
    if (imageData.isEmpty) return 'N/A';
    if (imageData.startsWith('http')) return imageData;
    return 'https:$imageData';
  }

  String _translateCountry(String countryCode) {
    final countryMap = {
      'US': 'Estados Unidos',
      'BR': 'Brasil',
      'CN': 'China',
      'GB': 'Reino Unido',
      'DE': 'Alemanha',
      'FR': 'França',
      'IT': 'Itália',
      'ES': 'Espanha',
      'CA': 'Canadá',
      'AU': 'Austrália',
      'JP': 'Japão',
      'KR': 'Coreia do Sul',
      'IN': 'Índia',
      'RU': 'Rússia',
      'MX': 'México',
      'AR': 'Argentina',
      'CL': 'Chile',
      'CO': 'Colômbia',
      'PE': 'Peru',
      'VE': 'Venezuela',
    };
    
    return countryMap[countryCode] ?? countryCode;
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
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
      case 'preto':
      case 'black':
        return Colors.black;
      case 'branco':
      case 'white':
        return Colors.white;
      case 'rosa':
      case 'pink':
        return Colors.pink;
      case 'roxo':
      case 'purple':
        return Colors.purple;
      case 'laranja':
      case 'orange':
        return Colors.orange;
      case 'marrom':
      case 'brown':
        return Colors.brown;
      case 'cinza':
      case 'gray':
      case 'grey':
        return Colors.grey;
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

  // Modal de edição de descrição
  void _showDescriptionEditor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildDescriptionModal();
      },
    );
  }

  Widget _buildDescriptionModal() {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height + MediaQuery.of(context).padding.top,
        color: Colors.white,
        child: Column(
          children: [
            // Header removido conforme pedido
            
            // Toolbar customizada do Quill
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fonte e Tamanho
                    _buildFontFamilyPicker(),
                    _buildFontSizePickerQuill(),
                    const VerticalDivider(width: 1, thickness: 1),
                    // B / I / U após fonte
                    _buildToolbarGroup([
                      _buildFormatButton(
                        icon: Icons.format_bold,
                        tooltip: 'Negrito',
                        isActive: _boldActive,
                        onPressed: () => _toggleBold(),
                      ),
                      _buildFormatButton(
                        icon: Icons.format_italic,
                        tooltip: 'Itálico',
                        isActive: _italicActive,
                        onPressed: () => _toggleItalic(),
                      ),
                      _buildFormatButton(
                        icon: Icons.format_underline,
                        tooltip: 'Sublinhado',
                        isActive: _underlineActive,
                        onPressed: () => _toggleUnderline(),
                      ),
                    ]),
                    const VerticalDivider(width: 1, thickness: 1),
                    // Formatação de texto avançada
                    _buildToolbarGroup([
                      _buildFormatButton(
                        icon: Icons.title,
                        tooltip: 'H1',
                        isActive: false,
                        onPressed: () => _setHeader(1),
                      ),
                      _buildFormatButton(
                        icon: Icons.title,
                        tooltip: 'H2',
                        isActive: false,
                        onPressed: () => _setHeader(2),
                      ),
                      _buildFormatButton(
                        icon: Icons.title,
                        tooltip: 'H3',
                        isActive: false,
                        onPressed: () => _setHeader(3),
                      ),
                      _buildFormatButton(
                        icon: Icons.title,
                        tooltip: 'H4',
                        isActive: false,
                        onPressed: () => _setHeader(4),
                      ),
                      _buildFormatButton(
                        icon: Icons.title,
                        tooltip: 'H5',
                        isActive: false,
                        onPressed: () => _setHeader(5),
                      ),
                      _buildFormatButton(
                        icon: Icons.title,
                        tooltip: 'H6',
                        isActive: false,
                        onPressed: () => _setHeader(6),
                      ),
                      _buildFormatButton(
                        icon: Icons.strikethrough_s,
                        tooltip: 'Tachado',
                        isActive: false,
                        onPressed: () => _toggleStrike(),
                      ),
                      _buildFormatButton(
                        icon: Icons.format_quote,
                        tooltip: 'Citação',
                        isActive: false,
                        onPressed: () => _toggleBlockQuote(),
                      ),
                      _buildFormatButton(
                        icon: Icons.code,
                        tooltip: 'Código',
                        isActive: false,
                        onPressed: () => _toggleCodeBlock(),
                      ),
                      _buildFormatButton(
                        icon: Icons.check_box,
                        tooltip: 'Checklist',
                        isActive: false,
                        onPressed: () => _toggleChecklist(),
                      ),
                      _buildFormatButton(
                        icon: Icons.undo,
                        tooltip: 'Desfazer',
                        isActive: false,
                        onPressed: _undo,
                      ),
                      _buildFormatButton(
                        icon: Icons.redo,
                        tooltip: 'Refazer',
                        isActive: false,
                        onPressed: _redo,
                      ),
                    ]),
                    
                    const VerticalDivider(width: 1, thickness: 1),
                    
                    // Alinhamento
                    _buildToolbarGroup([
                      _buildFormatButton(
                        icon: Icons.format_align_left,
                        tooltip: 'Esquerda',
                        isActive: false,
                        onPressed: () => _setAlignment('left'),
                      ),
                      _buildFormatButton(
                        icon: Icons.format_align_center,
                        tooltip: 'Centro',
                        isActive: false,
                        onPressed: () => _setAlignment('center'),
                      ),
                      _buildFormatButton(
                        icon: Icons.format_align_right,
                        tooltip: 'Direita',
                        isActive: false,
                        onPressed: () => _setAlignment('right'),
                      ),
                       _buildFormatButton(
                         icon: Icons.format_align_justify,
                         tooltip: 'Justificado',
                         isActive: false,
                         onPressed: () => _setAlignment('justify'),
                      ),
                    ]),
                    
                    const VerticalDivider(width: 1, thickness: 1),
                    
                    // Listas
                    _buildToolbarGroup([
                      _buildFormatButton(
                        icon: Icons.format_list_bulleted,
                        tooltip: 'Lista',
                        isActive: false,
                        onPressed: () => _setList('bullet'),
                      ),
                      _buildFormatButton(
                        icon: Icons.format_list_numbered,
                        tooltip: 'Numerada',
                        isActive: false,
                        onPressed: () => _setList('ordered'),
                      ),
                    ]),
                    
                    const VerticalDivider(width: 1, thickness: 1),
                    
                    // Cores
                    _buildColorPicker(),
                    
                    const VerticalDivider(width: 1, thickness: 1),

                    // Link
                    _buildFormatButton(
                      icon: Icons.link,
                      tooltip: 'Inserir link',
                      isActive: false,
                      onPressed: _insertLink,
                    ),

                    const VerticalDivider(width: 1, thickness: 1),

                    // Imagem
                    _buildFormatButton(
                      icon: Icons.image,
                      tooltip: 'Inserir imagem',
                      isActive: false,
                      onPressed: _insertImage,
                    ),
                    
                    const VerticalDivider(width: 1, thickness: 1),
                    
                    // Templates
                    _buildFormatButton(
                      icon: Icons.description,
                      tooltip: 'Templates',
                      isActive: false,
                      onPressed: () => _showTemplateDialog(),
                    ),
                    
                    const VerticalDivider(width: 1, thickness: 1),
                    
                    // Limpar formatação
                    _buildFormatButton(
                      icon: Icons.format_clear,
                      tooltip: 'Limpar',
                      isActive: false,
                      onPressed: () => _clearFormat(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Editor Quill
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: QuillEditor(
                  controller: _quillController,
                  scrollController: ScrollController(),
                  focusNode: _quillFocusNode,
                  config: QuillEditorConfig(
                    embedBuilders: [
                      ...FlutterQuillEmbeds.editorBuilders(),
                    ],
                    customStyles: DefaultStyles(
                      sizeSmall: const TextStyle(fontSize: 12),
                      sizeLarge: const TextStyle(fontSize: 28),
                      sizeHuge: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              ),
            ),
            
            // Botões de ação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  // Botão cancelar
                  Expanded(
                    flex: 2,
                    child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Botão visualizar
                  Expanded(
                    flex: 2,
                    child: TextButton.icon(
                        onPressed: () => _previewDescription(),
                      icon: const Icon(Icons.preview, size: 18),
                      label: const Text('Ver', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Botão salvar
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                        onPressed: () => _saveDescription(),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Salvar', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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

  // Widget para grupo de botões da toolbar
  Widget _buildToolbarGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: children,
      ),
    );
  }

  // Widget para botão de formatação
  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
      onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isActive ? AppTheme.primaryColor : Colors.grey[700],
        ),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // Widget para seletor de cor
  Widget _buildColorPicker() {
    return PopupMenuButton<Color>(
      tooltip: 'Cor do Texto',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _colorActive ?? Colors.black,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(
          Icons.format_color_text,
          color: Colors.white,
          size: 20,
        ),
      ),
      itemBuilder: (context) => [
        Colors.black,
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
        Colors.pink,
        Colors.brown,
        Colors.grey,
      ].map((color) => PopupMenuItem(
        value: color,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
      )).toList(),
      onSelected: (color) => _setTextColor(color),
    );
  }

  // Widget para seletor de tamanho da fonte
  Widget _buildFontSizePicker() {
    return PopupMenuButton<double>(
      tooltip: 'Tamanho da Fonte',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_fontSizeActive.toInt()}',
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
        ),
      itemBuilder: (context) => [12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0]
          .map((size) => PopupMenuItem(
                value: size,
                child: Text('${size.toInt()}'),
              ))
          .toList(),
      onSelected: (size) => _setFontSize(size),
    );
  }

  // Widget: seletor de família de fonte (Quill 'font')
  Widget _buildFontFamilyPicker() {
    // Map: Label visível -> valor de atributo quill
    final Map<String, String> items = {
      'Sans Serif': 'sans-serif',
      'Serif': 'serif',
      'Monospace': 'monospace',
      'Roboto': 'roboto',
      'Arial': 'arial',
      'Times New Roman': 'times-new-roman',
      'Courier New': 'courier-new',
      'Georgia': 'georgia',
      'Verdana': 'verdana',
      'Trebuchet MS': 'trebuchet-ms',
      'Comic Sans MS': 'comic-sans-ms',
      'Tahoma': 'tahoma',
      'Impact': 'impact',
    };
    return PopupMenuButton<String>(
      tooltip: 'Fonte',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.font_download, size: 18),
            const SizedBox(width: 6),
            Text(_fontFamilyActiveLabel, style: const TextStyle(fontSize: 13)),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => items.entries
          .map((e) => PopupMenuItem<String>(
                value: e.value,
                child: Text(e.key),
              ))
          .toList(),
      onSelected: (value) {
        // Atualiza também o label a partir do valor selecionado
        final label = items.entries.firstWhere((e) => e.value == value).key;
        _setFontFamilyWithLabel(value, label);
      },
    );
  }

  // Widget: seletor de tamanho (Quill 'size') usando valores numéricos suportados
  Widget _buildFontSizePickerQuill() {
    final List<(String label, String? value)> sizes = [
      ('Normal', null),
      ('4', '4'),
      ('6', '6'),
      ('8', '8'),
      ('10', '10'),
      ('12', '12'),
      ('14', '14'),
      ('16', '16'),
      ('18', '18'),
      ('20', '20'),
      ('24', '24'),
      ('28', '28'),
      ('32', '32'),
      ('36', '36'),
      ('40', '40'),
      ('48', '48'),
      ('56', '56'),
      ('64', '64'),
      ('72', '72'),
      ('80', '80'),
      ('90', '90'),
    ];
    return PopupMenuButton<(String label, String? value)>(
      tooltip: 'Tamanho da Fonte',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_size, size: 18),
            const SizedBox(width: 6),
            Text(_fontSizeLabel, style: const TextStyle(fontSize: 13)),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => sizes
          .map((opt) => PopupMenuItem<(String label, String? value)>(
                value: opt,
                child: Text(opt.$1),
              ))
          .toList(),
      onSelected: (opt) {
        _setFontSizeQuill(opt.$2, label: opt.$1);
      },
    );
  }

  void _setFontFamilyWithLabel(String value, String label) {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final style = _quillController.getSelectionStyle().attributes;
    final current = style[Attribute.font.key]?.value;
    final shouldClear = current == value;
    _quillController.formatSelection(
      shouldClear ? Attribute.fromKeyValue('font', null) : Attribute.fromKeyValue('font', value),
    );
    setState(() {
      _fontFamilyActive = value;
      _fontFamilyActiveLabel = label;
    });
  }

  void _setFontSizeQuill(String? sizeValue, {required String label}) {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final style = _quillController.getSelectionStyle().attributes;
    final current = style[Attribute.size.key]?.value;
    final shouldClear = current == sizeValue || (sizeValue == null && current != null);
    // Para manter compatibilidade, se o valor for '12'/'20'/'32', podemos mapear também para small/large/huge
    String? mapped = sizeValue;
    if (sizeValue == '12') mapped = 'small';
    if (sizeValue == '20') mapped = 'large';
    if (sizeValue == '32') mapped = 'huge';
    _quillController.formatSelection(
      shouldClear ? Attribute.fromKeyValue('size', null) : Attribute.fromKeyValue('size', mapped),
    );
    setState(() {
      _fontSizeLabel = label;
    });
  }

  // Métodos para manipulação do editor - SOLUÇÃO CORRETA BASEADA NA DOCUMENTAÇÃO
  void _toggleBold() {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final attrs = _quillController.getSelectionStyle().attributes;
    final isOn = attrs.containsKey(Attribute.bold.key);
    final isCaret = selection.isCollapsed;
    _quillController.formatSelection(
      isOn ? Attribute.fromKeyValue(Attribute.bold.key, null) : Attribute.bold,
    );
    _updateActiveFormats();
  }

  void _toggleItalic() {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final attrs = _quillController.getSelectionStyle().attributes;
    final isOn = attrs.containsKey(Attribute.italic.key);
    final isCaret = selection.isCollapsed;
    _quillController.formatSelection(
      isOn ? Attribute.fromKeyValue(Attribute.italic.key, null) : Attribute.italic,
    );
      _updateActiveFormats();
    }

  void _toggleUnderline() {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final attrs = _quillController.getSelectionStyle().attributes;
    final isOn = attrs.containsKey(Attribute.underline.key);
    final isCaret = selection.isCollapsed;
    _quillController.formatSelection(
      isOn ? Attribute.fromKeyValue(Attribute.underline.key, null) : Attribute.underline,
    );
    _updateActiveFormats();
  }

  void _toggleStrike() {
    final selection = _quillController.selection;
    if (selection.isValid) {
      _quillController.formatSelection(Attribute.strikeThrough);
      _updateActiveFormats();
    }
  }

  void _toggleBlockQuote() {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final style = _quillController.getSelectionStyle().attributes;
    final isActive = style.containsKey(Attribute.blockQuote.key);
    _quillController.formatSelection(
      isActive
          ? Attribute.fromKeyValue(Attribute.blockQuote.key, null)
          : Attribute.blockQuote,
    );
  }

  void _toggleCodeBlock() {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final style = _quillController.getSelectionStyle().attributes;
    final isActive = style.containsKey(Attribute.codeBlock.key);
    _quillController.formatSelection(
      isActive
          ? Attribute.fromKeyValue(Attribute.codeBlock.key, null)
          : Attribute.codeBlock,
    );
  }

  void _toggleChecklist() {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final style = _quillController.getSelectionStyle().attributes;
    final current = style[Attribute.list.key]?.value;
    final newValue = current == 'checked' ? null : 'checked';
    _quillController.formatSelection(Attribute.fromKeyValue('list', newValue));
  }

  void _setHeader(int level) {
    final selection = _quillController.selection;
    if (!selection.isValid) return;
    final style = _quillController.getSelectionStyle().attributes;
    final current = style[Attribute.header.key]?.value;
    final shouldClear = current == level;
    _quillController.formatSelection(
      shouldClear ? Attribute.header : HeaderAttribute(level: level),
    );
  }

  void _undo() {
    _quillController.undo();
  }

  void _redo() {
    _quillController.redo();
  }

  void _setAlignment(String alignment) {
    final selection = _quillController.selection;
    if (selection.isValid) {
      final style = _quillController.getSelectionStyle().attributes;
      final current = style[Attribute.align.key]?.value;
      final String? targetValue = alignment == 'left' ? null : alignment;
      final shouldClear = current == targetValue || (alignment == 'left' && current != null);
      _quillController.formatSelection(
        shouldClear ? Attribute.fromKeyValue('align', null) : Attribute.fromKeyValue('align', targetValue),
      );
    }
  }

  void _setList(String type) {
    final selection = _quillController.selection;
    if (selection.isValid) {
      final style = _quillController.getSelectionStyle().attributes;
      final current = style[Attribute.list.key]?.value;
      if (type == 'bullet') {
        _quillController.formatSelection(
          current == 'bullet' ? Attribute.fromKeyValue('list', null) : Attribute.ul,
        );
      } else if (type == 'ordered') {
        _quillController.formatSelection(
          current == 'ordered' ? Attribute.fromKeyValue('list', null) : Attribute.ol,
        );
      }
    }
  }

  void _setTextColor(Color color) {
    final selection = _quillController.selection;
    if (selection.isValid) {
      final style = _quillController.getSelectionStyle().attributes;
      final current = style[Attribute.color.key]?.value?.toString();
      final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      final shouldClear = current != null && current.toLowerCase() == hex.toLowerCase();
      _quillController.formatSelection(
        shouldClear ? Attribute.fromKeyValue('color', null) : Attribute.fromKeyValue('color', hex),
      );
      setState(() {
      _colorActive = color;
      });
    }
  }

  void _setFontSize(double size) {
    final selection = _quillController.selection;
    if (selection.isValid) {
      // Mantido para compatibilidade, mas preferimos _setFontSizeQuill()
      _quillController
          .formatSelection(Attribute.fromKeyValue('size', '${size.toInt()}px'));
      setState(() {
        _fontSizeActive = size;
      });
    }
  }

  void _insertLink() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inserir Link'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://exemplo.com',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                _quillController
                    .formatSelection(Attribute.fromKeyValue('link', url));
              } else {
                // se vazio, remove link
                _quillController
                    .formatSelection(Attribute.fromKeyValue('link', null));
              }
              Navigator.pop(context);
            },
            child: const Text('Inserir'),
          ),
        ],
      ),
    );
  }

  void _insertImage() {
    final imageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inserir Imagem'),
        content: TextField(
          controller: imageController,
          decoration: const InputDecoration(
            labelText: 'URL da Imagem',
            hintText: 'https://exemplo.com/imagem.jpg',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = imageController.text.trim();
              if (url.isNotEmpty) {
                final index = _quillController.selection.baseOffset;
                _quillController.document.insert(index, BlockEmbed.image(url));
                _quillController.updateSelection(
                  TextSelection.collapsed(offset: index + 1),
                  ChangeSource.local,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Inserir'),
          ),
        ],
      ),
    );
  }

  void _clearFormat() {
    // Remove formatação aplicando novamente cada atributo
    _quillController.formatSelection(Attribute.bold);
    _quillController.formatSelection(Attribute.italic);
    _quillController.formatSelection(Attribute.underline);
    _updateActiveFormats();
  }

  void _updateActiveFormats() {
    final selection = _quillController.selection;
    if (selection.isValid) {
      final format = _quillController.getSelectionStyle();
      setState(() {
        _boldActive = format.containsKey(Attribute.bold.key);
        _italicActive = format.containsKey(Attribute.italic.key);
        _underlineActive = format.containsKey(Attribute.underline.key);
      });
    }
  }

  void _previewDescription() {
    final html = _quillController.document.toDelta().toJson();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visualização da Descrição'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _quillController.document.toPlainText(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _saveDescription() {
    // 1) Salvar preview em texto simples
    final plain = _quillController.document.toPlainText();
    _descriptionController.text = plain;

    // 2) Salvar Delta JSON no mapa de dados completo
    try {
      final deltaJson = _quillController.document.toDelta().toJson();
      _completeProductData['description_delta'] = deltaJson;
    } catch (_) {}

    // 3) Marcar como alterado para trigger auto-save
    _markAsChanged();
    
    // 4) Salvar draft imediatamente 
    _saveDraft();
    
    // Mostrar feedback de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Descrição salva com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    Navigator.of(context).pop();
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inserir Template de Descrição'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTemplateButton('Título Principal', '🎯 TÍTULO PRINCIPAL\n[Escreva um título impactante aqui]'),
              _buildTemplateButton('Subtítulo', '📝 SUBTÍTULO\n[Escreva um subtítulo atrativo]'),
              _buildTemplateButton('Lista de Características', '📋 LISTA DE CARACTERÍSTICAS\n• [Característica 1]\n• [Característica 2]\n• [Característica 3]'),
              _buildTemplateButton('Destaques', '⭐ DESTAQUES\n✨ [Destaque 1]\n✨ [Destaque 2]\n✨ [Destaque 3]'),
              _buildTemplateButton('Especificações', '⚙️ ESPECIFICAÇÕES TÉCNICAS\n• Material: [Especificar]\n• Peso: [Especificar]\n• Dimensões: [Especificar]'),
              _buildTemplateButton('Benefícios', '✨ BENEFÍCIOS PRINCIPAIS\n• [Benefício 1]\n• [Benefício 2]\n• [Benefício 3]'),
              _buildTemplateButton('Instruções de Cuidado', '🧺 INSTRUÇÕES DE CUIDADO\n• [Instrução 1]\n• [Instrução 2]\n• [Instrução 3]'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateButton(String title, String template) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          _insertTemplate(template);
          Navigator.pop(context);
        },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  void _insertTemplate(String template) {
    final currentPosition = _quillController.selection.baseOffset;
    _quillController.document.insert(currentPosition, template);
  }

  // Mostrar diálogo de publicação
  void _showPublishingDialog() {
    // Validar produto antes de mostrar o diálogo
    Map<String, dynamic> productData = _getCurrentProductData();
    
    // Log dos dados sendo validados
    print('📋 === DADOS DO PRODUTO PARA VALIDAÇÃO ===');
    print('  - Nome: "${productData['name']}"');
    print('  - Preço: ${productData['price']}');
    print('  - Categoria: "${productData['category']}"');
    print('  - Descrição: ${productData['description']?.toString().length ?? 0} caracteres');
    print('  - Imagens existentes: ${(productData['images'] as List?)?.length ?? 0}');
    print('  - Imagens selecionadas: ${_selectedImages.length}');
    print('  - Variações: ${(productData['variations'] as List?)?.length ?? 0}');
    print('  - Estoque: ${productData['stock']}');
    print('  - Palavras-chave: ${productData['keywords']}');
    print('📋 === FIM DOS DADOS ===\n');
    
    ValidationResult validation = ProductValidationService.validateProduct(productData);

    // Log detalhado da validação
    print('🔍 === VALIDAÇÃO DO PRODUTO ===');
    print('📋 Status: ${validation.isValid ? '✅ VÁLIDO' : '❌ INVÁLIDO'}');
    print('📊 Resumo: ${validation.errors.length} erros, ${validation.warnings.length} avisos');
    
    if (validation.errors.isNotEmpty) {
      print('\n❌ ERROS ENCONTRADOS:');
      for (int i = 0; i < validation.errors.length; i++) {
        print('  ${i + 1}. ${validation.errors[i]}');
      }
    }
    
    if (validation.warnings.isNotEmpty) {
      print('\n⚠️ AVISOS:');
      for (int i = 0; i < validation.warnings.length; i++) {
        print('  ${i + 1}. ${validation.warnings[i]}');
      }
    }
    
    print('🔍 === FIM DA VALIDAÇÃO ===\n');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                validation.isValid ? Icons.check_circle : Icons.error,
                color: validation.isValid ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Publicar Produto'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ProductValidationService.getValidationSummary(validation),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: validation.isValid ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (validation.errors.isNotEmpty) ...[
                  const Text(
                    '❌ Erros encontrados:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ...validation.errors.map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $error', style: const TextStyle(color: Colors.red)),
                  )),
                  const SizedBox(height: 16),
                ],
                
                if (validation.warnings.isNotEmpty) ...[
                  const Text(
                    '⚠️ Avisos:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  ...validation.warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $warning', style: const TextStyle(color: Colors.orange)),
                  )),
                  const SizedBox(height: 16),
                ],
                
                if (validation.isValid) ...[
                  const Text(
                    '📋 Resumo da publicação:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('• Nome: ${_nameController.text}'),
                  Text('• Preço: R\$ ${_priceController.text}'),
                  Text('• Categoria: ${_categoryController.text}'),
                  Text('• Imagens: ${_getTotalImageCount()}'),
                  if (_selectedImages.isNotEmpty)
                    Text('• Novas imagens: ${_selectedImages.length}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            if (validation.isValid)
              ElevatedButton(
                onPressed: _isPublishing ? null : _publishProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publicar'),
              ),
          ],
        );
      },
    );
  }

  // Publicar produto
  Future<void> _publishProduct() async {
    setState(() {
      _isPublishing = true;
    });

    try {
      Map<String, dynamic> productData = _getCurrentProductData();
      
      PublishingResult result = await ProductPublishingService.publishProduct(
        productData,
        _selectedImages,
      );

      print('🚀 Publicação: ${result.success ? '✅ Sucesso' : '❌ Falha'} - ${result.message}');

      Navigator.of(context).pop(); // Fechar diálogo

      if (result.success) {
        // Limpar imagens selecionadas após publicação
        setState(() {
          _selectedImages.clear();
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar de volta para a tela de gerenciamento e ir para aba "Publicados"
        Navigator.of(context).pop();
        
        // Navegar para a tela de gerenciamento de produtos com parâmetro para ir para aba "Publicados"
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminManageProductsScreen(),
            settings: RouteSettings(
              arguments: {'initialTab': 1}, // 1 = aba "Publicados"
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Fechar diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  // Obter dados atuais do produto
  Map<String, dynamic> _getCurrentProductData() {
    // Processar variações corretamente
    List<Map<String, dynamic>> processedVariations = [];
    List<dynamic> rawVariations = _completeProductData['variations'] ?? [];
    
    print('🔍 === PROCESSANDO VARIAÇÕES ===');
    print('📊 Variações brutas encontradas: ${rawVariations.length}');
    
    for (int i = 0; i < rawVariations.length; i++) {
      var variation = rawVariations[i];
      print('  Variação $i: $variation');
      
      // Processar variação do AliExpress
      if (variation is Map<String, dynamic>) {
        // Extrair nome da variação (cor, tamanho, etc.)
        String variationName = 'Variação ${i + 1}';
        if (variation['ae_sku_property_dtos'] != null && 
            variation['ae_sku_property_dtos']['ae_sku_property_d_t_o'] != null) {
          var properties = variation['ae_sku_property_dtos']['ae_sku_property_d_t_o'] as List;
          if (properties.isNotEmpty) {
            var firstProperty = properties.first;
            variationName = firstProperty['sku_property_value'] ?? 'Variação ${i + 1}';
          }
        }
        
        Map<String, dynamic> processedVariation = {
          'name': variationName,
          'price': double.tryParse(variation['sku_price']?.toString() ?? '') ?? 
                   double.tryParse(variation['offer_sale_price']?.toString() ?? '') ?? 0.0,
          'stock': int.tryParse(variation['sku_available_stock']?.toString() ?? '') ?? 0,
          'sku': variation['sku_id']?.toString() ?? '',
          'color': variationName,
          'size': variationName,
        };
        
        processedVariations.add(processedVariation);
        print('  ✅ Processada: ${processedVariation['name']} - R\$ ${processedVariation['price']} - Estoque: ${processedVariation['stock']}');
      }
    }
    
    print('🔍 === FIM DO PROCESSAMENTO ===\n');
    
    return {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'description_html': _quillController.document.toPlainText(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'original_price': double.tryParse(_originalPriceController.text),
      'category': _categoryController.text,
      'brand': _brandController.text,
      'sku': _skuController.text,
      'weight': _weightController.text,
      'dimensions': _dimensionsController.text,
      'material': _materialController.text,
      'color': _colorController.text,
      'warranty': _warrantyController.text,
      'shipping': _shippingController.text,
      'tags': _tagsController.text,
      'keywords': _keywordsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'images': _getExistingImages(),
      'selected_images': _selectedImages,
      'variations': processedVariations,
      'stock': processedVariations.isNotEmpty ? 
               processedVariations.map((v) => v['stock'] as int).reduce((a, b) => a + b) : 0,
      'aliexpress_id': widget.product['aliexpress_id'],
      'has_unsaved_changes': _hasUnsavedChanges,
    };
  }

  // Obter imagens existentes
  List<String> _getExistingImages() {
    List<String> images = [];
    
    // Imagens do AliExpress
    if (_completeProductData.isNotEmpty) {
      images = ProductDetailService.extractImageGallery(_completeProductData);
    }
    
    // Fallback para imagem básica
    if (images.isEmpty) {
      final mainImage = widget.product['itemMainPic'] ?? widget.product['image_url'] ?? '';
      if (mainImage.isNotEmpty) {
        images.add(mainImage.startsWith('http') ? mainImage : 'https:$mainImage');
      }
    }
    
    return images;
  }

  // Obter total de imagens
  int _getTotalImageCount() {
    return _getExistingImages().length + _selectedImages.length;
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                      color: Colors.orange,
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
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.search,
                  title: 'Buscar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/aliexpress');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  title: 'Produtos Importados',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/imported-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Gerenciar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/manage-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categorias',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/categories');
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
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.orange : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }

  void _showVariationsEditor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Variações'),
          content: const Text('Editor de variações será implementado aqui.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
} 