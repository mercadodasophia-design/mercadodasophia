import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_variation.dart';
import '../theme/app_theme.dart';

class ProductVariationsWidget extends StatefulWidget {
  final Product product;
  final Function(ProductVariation?) onVariationSelected;
  final ProductVariation? selectedVariation;

  const ProductVariationsWidget({
    super.key,
    required this.product,
    required this.onVariationSelected,
    this.selectedVariation,
  });

  @override
  State<ProductVariationsWidget> createState() => _ProductVariationsWidgetState();
}

class _ProductVariationsWidgetState extends State<ProductVariationsWidget> {
  String? selectedColor;
  String? selectedSize;
  ProductVariation? currentVariation;

  @override
  void initState() {
    super.initState();
    // Inicializar com a primeira variação disponível ou a selecionada
    if (widget.selectedVariation != null) {
      currentVariation = widget.selectedVariation;
      selectedColor = widget.selectedVariation!.color;
      selectedSize = widget.selectedVariation!.size;
    } else if (widget.product.variations.isNotEmpty) {
      final firstAvailable = widget.product.variations.firstWhere(
        (v) => v.hasStock,
        orElse: () => widget.product.variations.first,
      );
      currentVariation = firstAvailable;
      selectedColor = firstAvailable.color;
      selectedSize = firstAvailable.size;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.product.hasVariations) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de Cores
        if (widget.product.availableColors.isNotEmpty) ...[
          _buildColorSection(),
          const SizedBox(height: 16),
        ],
        
        // Seção de Tamanhos
        if (widget.product.availableSizes.isNotEmpty) ...[
          _buildSizeSection(),
          const SizedBox(height: 16),
        ],
        
        // Informações da variação selecionada
        _buildVariationInfo(),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.availableColors.map((color) {
            final isSelected = selectedColor == color;
            final hasStock = widget.product.variations
                .where((v) => v.color == color)
                .any((v) => v.hasStock);
            
            return GestureDetector(
              onTap: hasStock ? () => _selectColor(color) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : 
                         hasStock ? Colors.grey[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : 
                           hasStock ? Colors.grey[300]! : Colors.red[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      color,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : 
                               hasStock ? Colors.black87 : Colors.red[700],
                      ),
                    ),
                    if (!hasStock) const SizedBox(width: 4),
                    if (!hasStock)
                      const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 14,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Disponível',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Sem estoque',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tamanho',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.availableSizes.map((size) {
            final isSelected = selectedSize == size;
            final hasStock = widget.product.variations
                .where((v) => v.size == size)
                .any((v) => v.hasStock);
            
            return GestureDetector(
              onTap: hasStock ? () => _selectSize(size) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : 
                         hasStock ? Colors.grey[100] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : 
                           hasStock ? Colors.grey[300]! : Colors.red[300]!,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : !hasStock ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : 
                           hasStock ? Colors.black87 : Colors.red[400],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Disponível',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Sem estoque',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariationInfo() {
    // Se não há variação selecionada, mostrar mensagem de instrução
    if (currentVariation == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getSelectionInstruction(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final variation = currentVariation!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: variation.hasStock ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: variation.hasStock ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                variation.hasStock ? Icons.check_circle : Icons.error,
                color: variation.hasStock ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                variation.hasStock ? 'Variação Disponível' : 'Variação Indisponível',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: variation.hasStock ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variation.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${variation.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: variation.hasStock ? AppTheme.primaryColor : Colors.grey[600],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: variation.hasStock ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      variation.hasStock 
                          ? '${variation.stock} em estoque'
                          : 'Sem estoque',
                      style: TextStyle(
                        fontSize: 12,
                        color: variation.hasStock ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!variation.hasStock) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta variação não pode ser adicionada ao carrinho pois está sem estoque.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectColor(String color) {
    setState(() {
      selectedColor = color;
      _updateCurrentVariation();
    });
  }

  void _selectSize(String size) {
    setState(() {
      selectedSize = size;
      _updateCurrentVariation();
    });
  }

  void _updateCurrentVariation() {
    // Verificar se temos seleções válidas
    bool hasValidSelection = false;
    
    // Se o produto tem apenas cores (sem tamanhos)
    if (widget.product.availableColors.isNotEmpty && widget.product.availableSizes.isEmpty) {
      hasValidSelection = selectedColor != null;
    }
    // Se o produto tem apenas tamanhos (sem cores)
    else if (widget.product.availableSizes.isNotEmpty && widget.product.availableColors.isEmpty) {
      hasValidSelection = selectedSize != null;
    }
    // Se o produto tem cores e tamanhos
    else if (widget.product.availableColors.isNotEmpty && widget.product.availableSizes.isNotEmpty) {
      hasValidSelection = selectedColor != null && selectedSize != null;
    }
    
    if (!hasValidSelection) {
      setState(() {
        currentVariation = null;
      });
      widget.onVariationSelected(null);
      return;
    }

    // Encontrar a variação que corresponde à seleção atual
    ProductVariation? variation;
    
    try {
      variation = widget.product.variations.firstWhere(
        (v) {
          bool colorMatch = selectedColor == null || v.color == selectedColor;
          bool sizeMatch = selectedSize == null || v.size == selectedSize;
          return colorMatch && sizeMatch;
        },
        orElse: () => ProductVariation(
          id: '',
          productId: widget.product.id,
          color: selectedColor,
          size: selectedSize,
          price: widget.product.price,
          stock: 0,
          sku: '',
        ),
      );
    } catch (e) {
      // Se não encontrar variação, criar uma vazia
      variation = ProductVariation(
        id: '',
        productId: widget.product.id,
        color: selectedColor,
        size: selectedSize,
        price: widget.product.price,
        stock: 0,
        sku: '',
      );
    }

    setState(() {
      currentVariation = variation;
    });

    // Notificar o callback apenas se a variação tem estoque
    if (variation != null && variation.hasStock) {
      widget.onVariationSelected(variation);
    } else {
      // Se não tem estoque, notificar com null para indicar que não pode ser selecionada
      widget.onVariationSelected(null);
    }
  }

  String _getSelectionInstruction() {
    // Se o produto tem apenas cores (sem tamanhos)
    if (widget.product.availableColors.isNotEmpty && widget.product.availableSizes.isEmpty) {
      return 'Selecione uma cor para continuar';
    }
    // Se o produto tem apenas tamanhos (sem cores)
    else if (widget.product.availableSizes.isNotEmpty && widget.product.availableColors.isEmpty) {
      return 'Selecione um tamanho para continuar';
    }
    // Se o produto tem cores e tamanhos
    else if (widget.product.availableColors.isNotEmpty && widget.product.availableSizes.isNotEmpty) {
      return 'Selecione uma cor e um tamanho para continuar';
    }
    // Caso padrão
    else {
      return 'Selecione as opções do produto para continuar';
    }
  }

  Color _getColorFromName(String colorName) {
    final name = colorName.toLowerCase();
    
    switch (name) {
      case 'preto':
      case 'black':
        return Colors.black;
      case 'branco':
      case 'white':
        return Colors.white;
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
        return Colors.purple;
      case 'cinza':
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'marrom':
      case 'brown':
        return Colors.brown;
      default:
        // Gerar uma cor baseada no hash do nome
        return Color((colorName.hashCode * 0xFFFFFF) & 0xFFFFFF).withOpacity(1.0);
    }
  }
}

