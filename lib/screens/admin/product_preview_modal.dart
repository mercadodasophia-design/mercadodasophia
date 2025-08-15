import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter_quill/flutter_quill.dart';

class ProductPreviewModal extends StatefulWidget {
  final Map<String, dynamic> productData;
  final Map<String, dynamic> completeData;
  final QuillController quillController;

  const ProductPreviewModal({
    Key? key,
    required this.productData,
    required this.completeData,
    required this.quillController,
  }) : super(key: key);

  @override
  State<ProductPreviewModal> createState() => _ProductPreviewModalState();
}

class _ProductPreviewModalState extends State<ProductPreviewModal> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  String? _selectedVariation;

  List<String> get _productImages {
    final images = <String>[];
    
    // Imagem principal
    if (widget.productData['image_url'] != null) {
      images.add(widget.productData['image_url']);
    }
    
    // Galeria de imagens do AliExpress
    final gallery = widget.completeData['gallery'] as List?;
    if (gallery != null) {
      for (final img in gallery) {
        if (img is String && img.isNotEmpty) {
          images.add(img.startsWith('http') ? img : 'https:$img');
        }
      }
    }
    
    // Se não há imagens, usar placeholder
    if (images.isEmpty) {
      images.add('https://via.placeholder.com/400x400?text=Produto');
    }
    
    return images;
  }

  String get _formattedDescription {
    // Por enquanto, usa apenas texto simples
    // TODO: Implementar conversão Delta para HTML quando necessário
    return widget.quillController.document.toPlainText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Preview do Produto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copiado!')),
              );
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 60), // Espaço reduzido para botões fixos otimizados
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SLIDE DE IMAGENS
                  _buildImageCarousel(),
                  
                  // 2. NOME DO PRODUTO
                  _buildProductName(),
                  
                  // 3. DATA DE CHEGADA E ENDEREÇO
                  _buildDeliveryInfo(),
                  
                  // 4. ESTOQUE DISPONÍVEL
                  _buildStockInfo(),
                  
                  // 5. DEVOLUÇÕES E GARANTIAS
                  _buildWarrantyInfo(),
                  
                  // 6. DESCRIÇÃO DO PRODUTO
                  _buildDescription(),
                  
                  // 7. QUALIDADE DE SERVIÇOS
                  _buildServiceQuality(),
                  
                  // 8. CARACTERÍSTICAS DO PRODUTO
                  _buildProductSpecs(),
                  
                  // 9. MEIOS DE PAGAMENTO
                  _buildPaymentMethods(),
                  
                  // 10. SISTEMA DE AVALIAÇÕES
                  _buildReviewsSystem(),
                  
                  // 11. PRODUTOS SIMILARES
                  _buildSimilarProducts(),
                ],
              ),
            ),
          ),
          
          // 12. BOTÕES FIXOS NO FIM (sem rolagem)
          _buildFixedBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 400,
      color: Colors.grey[50],
      child: Stack(
        children: [
          cs.CarouselSlider(
            options: cs.CarouselOptions(
              height: 400,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: _productImages.length > 1,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),
            items: _productImages.map((imageUrl) {
              return Container(
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          Text('Imagem não disponível'),
                        ],
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
          
          // Indicador de páginas
          if (_productImages.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _productImages.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key 
                        ? Colors.orange 
                        : Colors.white.withOpacity(0.6),
                    ),
                  );
                }).toList(),
              ),
            ),
            
          // Botão de favorito
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.grey),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adicionado aos favoritos!')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. NOME DO PRODUTO
  Widget _buildProductName() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productData['title'] ?? 'Nome do Produto',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          
          // Preços
          Row(
            children: [
              if (widget.productData['original_price'] != null &&
                  widget.productData['original_price'] != widget.productData['price'])
                Text(
                  'R\$ ${widget.productData['original_price']}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                'R\$ ${widget.productData['price'] ?? '0,00'}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              if (widget.productData['original_price'] != null &&
                  widget.productData['original_price'] != widget.productData['price'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '25% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          // Variações (se existir)
          if (widget.completeData['skus'] != null) ...[
            const SizedBox(height: 16),
            _buildVariations(),
          ],
        ],
      ),
    );
  }

  // 3. DATA DE CHEGADA E ENDEREÇO
  Widget _buildDeliveryInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Informações de Entrega',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Data de chegada
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[600], size: 18),
              const SizedBox(width: 8),
              const Text(
                'Chegada prevista: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _getDeliveryDate(),
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Endereço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.blue[600], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entregar em:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rua das Flores, 123 - Vila Esperança\nSão Paulo, SP - CEP: 12345-678',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alterar endereço de entrega')),
                        );
                      },
                      child: Text(
                        'Alterar endereço',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Info adicional de frete
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frete GRÁTIS • Envio rápido garantido',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 7));
    final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    return '${weekdays[deliveryDate.weekday % 7]}, ${deliveryDate.day} de ${months[deliveryDate.month - 1]}';
  }

  Widget _buildVariations() {
    final skus = widget.completeData['skus'] as List?;
    if (skus == null || skus.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variações:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: skus.take(5).map((sku) {
            final variation = sku['skuPropertyName'] ?? 'Variação';
            final isSelected = _selectedVariation == variation;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVariation = isSelected ? null : variation;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
                ),
                child: Text(
                  variation,
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.black,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 4. ESTOQUE DISPONÍVEL
  Widget _buildStockInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estoque Disponível',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '47 unidades',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Em estoque',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. DEVOLUÇÕES E GARANTIAS
  Widget _buildWarrantyInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Garantias e Devoluções',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildWarrantyItem(
            Icons.assignment_return,
            'Devolução Gratuita',
            '30 dias para trocar ou devolver',
            Colors.orange[600]!,
          ),
          const SizedBox(height: 8),
          _buildWarrantyItem(
            Icons.verified_user,
            'Garantia da Loja',
            '90 dias de garantia completa',
            Colors.orange[600]!,
          ),
          const SizedBox(height: 8),
          _buildWarrantyItem(
            Icons.support_agent,
            'Suporte Especializado',
            'Atendimento dedicado pós-venda',
            Colors.orange[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  // 6. DESCRIÇÃO DO PRODUTO
  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Descrição do Produto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              _formattedDescription.isNotEmpty 
                ? _formattedDescription 
                : 'Descrição do produto será exibida aqui após a edição no Quill Editor...',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. QUALIDADE DE SERVIÇOS
  Widget _buildServiceQuality() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_outline, color: Colors.purple[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Qualidade de Serviços',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildServiceItem(
            Icons.speed,
            'Envio Rápido',
            'Produtos despachados em até 24h',
            Colors.purple[600]!,
          ),
          const SizedBox(height: 8),
          _buildServiceItem(
            Icons.security,
            'Compra Protegida',
            'Seus dados seguros e pagamento garantido',
            Colors.purple[600]!,
          ),
          const SizedBox(height: 8),
          _buildServiceItem(
            Icons.headset_mic,
            'Atendimento Premium',
            'Suporte especializado 7 dias por semana',
            Colors.purple[600]!,
          ),
          const SizedBox(height: 8),
          _buildServiceItem(
            Icons.emoji_events,
            'Qualidade Garantida',
            'Produtos selecionados e testados',
            Colors.purple[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 8. CARACTERÍSTICAS DO PRODUTO
  Widget _buildProductSpecs() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.engineering, color: Colors.indigo[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Características do Produto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildSpecRow('Marca', widget.productData['brand'] ?? 'Mercado da Sophia'),
                _buildSpecRow('SKU', widget.productData['sku'] ?? 'MS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
                _buildSpecRow('Peso', widget.productData['weight'] ?? '0.5 kg'),
                _buildSpecRow('Dimensões', widget.productData['dimensions'] ?? '15 x 10 x 5 cm'),
                _buildSpecRow('Material', widget.productData['material'] ?? 'Material de alta qualidade'),
                _buildSpecRow('Cor', widget.productData['color'] ?? 'Variável'),
                _buildSpecRow('Garantia', widget.productData['warranty'] ?? '90 dias', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 9. MEIOS DE PAGAMENTO
  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.green[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Meios de Pagamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Cartões de crédito
          Row(
            children: [
              Icon(Icons.credit_card, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cartão de Crédito',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildPaymentCard('💳', 'Visa'),
              _buildPaymentCard('💳', 'Mastercard'),
              _buildPaymentCard('💳', 'Elo'),
              _buildPaymentCard('💳', 'Amex'),
            ],
          ),
          const SizedBox(height: 12),
          
          // PIX
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PIX',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Aprovação instantânea',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '5% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Boleto
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Boleto Bancário',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                '(2-3 dias úteis)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(String icon, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 10. SISTEMA DE AVALIAÇÕES E COMENTÁRIOS
  Widget _buildReviewsSystem() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rate, color: Colors.amber[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Avaliações e Comentários',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Resumo das avaliações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        Icons.star,
                        size: 16,
                        color: index < 5 ? Colors.amber[600] : Colors.grey[300],
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '127 avaliações',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, 89),
                      _buildRatingBar(4, 23),
                      _buildRatingBar(3, 8),
                      _buildRatingBar(2, 3),
                      _buildRatingBar(1, 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Comentários
          const Text(
            'Comentários dos clientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildReviewItem(
            'Maria S.',
            5,
            'Produto excelente! Chegou rapidinho e exatamente como nas fotos. Recomendo!',
            'há 2 dias',
            'M',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildReviewItem(
            'João P.',
            5,
            'Muito satisfeito com a compra. Qualidade surpreendente e entrega no prazo.',
            'há 5 dias',
            'J',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildReviewItem(
            'Ana L.',
            4,
            'Bom produto, mas a embalagem poderia ser melhor. No geral, recomendo.',
            'há 1 semana',
            'A',
            Colors.purple,
          ),
          const SizedBox(height: 16),
          
          // Botão ver mais
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ver todas as avaliações')),
                );
              },
              child: const Text(
                'Ver todas as 127 avaliações',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars'),
          const SizedBox(width: 4),
          Icon(Icons.star, size: 12, color: Colors.amber[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, int rating, String comment, String time, String initial, Color avatarColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarColor,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          Icons.star,
                          size: 14,
                          color: index < rating ? Colors.amber[600] : Colors.grey[300],
                        )),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 11. PRODUTOS SIMILARES (Lista horizontal com rolagem)
  Widget _buildSimilarProducts() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: Colors.indigo[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Produtos Similares',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (context, index) {
                final products = [
                  {'name': 'iPhone 14 Pro', 'price': '899.90', 'originalPrice': '999.90', 'rating': 4.9},
                  {'name': 'Samsung Galaxy S23', 'price': '749.90', 'originalPrice': '849.90', 'rating': 4.7},
                  {'name': 'iPhone 13', 'price': '699.90', 'originalPrice': '799.90', 'rating': 4.8},
                  {'name': 'Xiaomi Mi 13', 'price': '549.90', 'originalPrice': '649.90', 'rating': 4.6},
                  {'name': 'OnePlus 11', 'price': '629.90', 'originalPrice': '729.90', 'rating': 4.5},
                  {'name': 'Google Pixel 7', 'price': '579.90', 'originalPrice': '679.90', 'rating': 4.4},
                ];
                
                final product = products[index];
                
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                            color: Colors.grey[100],
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(Icons.smartphone, size: 50, color: Colors.grey),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '15% OFF',
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
                          ),
                        ),
                      ),
                      
                      // Informações do produto
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber[600], size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${product['rating']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (product['originalPrice'] != product['price'])
                                Text(
                                  'R\$ ${product['originalPrice']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                'R\$ ${_formatPrice(product['price'])}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 12. BOTÕES FIXOS NO FIM (sem rolagem) - OTIMIZADO
  Widget _buildFixedBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linha 1: Quantidade + Preço Total (compacto)
            Row(
              children: [
                // Controle de quantidade compacto
                Row(
                  children: [
                    const Text(
                      'Qtd:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove, size: 16),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Preço total compacto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'R\$ ${(_calculateTotalPrice()).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Linha 2: Botões de ação principais (mais compactos)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$_quantity produto(s) adicionado(s) ao carrinho!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: const Text(
                      'CARRINHO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.orange, width: 2),
                      foregroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Comprando $_quantity produto(s) agora!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text(
                      'COMPRAR',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalPrice() {
    final priceString = widget.productData['price'] ?? '0,00';
    final price = double.tryParse(priceString.replaceAll(',', '.')) ?? 0.0;
    return price * _quantity;
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
