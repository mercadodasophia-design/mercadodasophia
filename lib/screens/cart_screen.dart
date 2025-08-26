import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar carrinho quando a tela for inicializada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initializeCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (cartProvider.error != null) {
            return _buildErrorWidget(cartProvider.error!);
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyCart();
          }

          return kIsWeb ? _buildWebLayout(cartProvider) : _buildMobileLayout(cartProvider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/produtos');
          }
        },
      ),
      title: const Text(
        'Carrinho de Compras',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isEmpty) return const SizedBox.shrink();
            
            return IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () => _showClearCartDialog(cartProvider),
              tooltip: 'Limpar Carrinho',
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar carrinho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().initializeCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tentar Novamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Seu carrinho está vazio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Adicione produtos para começar suas compras',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continuar Comprando',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(CartProvider cartProvider) {
    return Row(
      children: [
        // Lista de itens (70% da largura)
        Expanded(
          flex: 7,
          child: _buildItemsList(cartProvider),
        ),
        // Resumo do pedido (30% da largura)
        Expanded(
          flex: 3,
          child: _buildOrderSummary(cartProvider),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(CartProvider cartProvider) {
    return Column(
      children: [
        // Lista de itens
        Expanded(
          child: _buildItemsList(cartProvider),
        ),
        // Resumo do pedido
        _buildOrderSummary(cartProvider),
      ],
    );
  }

  Widget _buildItemsList(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Itens no Carrinho (${cartProvider.itemCount})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Lista de itens (sem espaçamento extra)
          ...cartProvider.items.map((item) => _buildCartItemCard(item, cartProvider)),
          
          // Aviso sobre itens indisponíveis
          if (cartProvider.hasUnavailableItems) ...[
            const SizedBox(height: 16),
            _buildUnavailableItemsWarning(cartProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações do produto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Controles de quantidade
                  Row(
                    children: [
                      _buildQuantityControl(item, cartProvider),
                      const Spacer(),
                      Text(
                        'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  // Aviso de indisponibilidade
                  if (!item.isAvailable) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        'Item indisponível',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Botão remover
            IconButton(
              onPressed: () => _showRemoveItemDialog(item, cartProvider),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remover item',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, CartProvider cartProvider) {
    return Row(
      children: [
        IconButton(
          onPressed: item.quantity > 1
              ? () => cartProvider.updateItemQuantity(item.id, item.quantity - 1)
              : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            item.quantity.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: item.isAvailable
              ? () => cartProvider.updateItemQuantity(item.id, item.quantity + 1)
              : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableItemsWarning(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itens indisponíveis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alguns itens no seu carrinho não estão mais disponíveis.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showRemoveUnavailableItemsDialog(cartProvider),
            child: Text(
              'Remover',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
            width: kIsWeb ? 1 : 0,
          ),
          top: BorderSide(
            color: Colors.grey[300]!,
            width: kIsWeb ? 0 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Pedido',
            style: TextStyle(
              fontSize: kIsWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Detalhes do pedido
          _buildOrderDetail('Subtotal', 'R\$ ${cartProvider.totalPrice.toStringAsFixed(2)}'),
          _buildOrderDetail('Frete', _getShippingText(cartProvider)),
          _buildOrderDetail('Taxas', 'R\$ 0,00'),
          const Divider(height: 32),
          _buildOrderDetail(
            'Total',
            'R\$ ${(cartProvider.totalPrice + cartProvider.shippingCost).toStringAsFixed(2)}',
            isTotal: true,
          ),
          
          const SizedBox(height: 16),
          
          // Excelências da loja
          _buildStoreExcellence(),
          
          const SizedBox(height: 24),
          
          // Botão finalizar compra
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: cartProvider.hasUnavailableItems ? null : () {
                // Navegar para a tela de checkout
                context.go('/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Finalizar Compra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botão continuar comprando
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continuar Comprando',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Método para obter texto do frete
  String _getShippingText(CartProvider cartProvider) {
    if (cartProvider.items.isEmpty) {
      return 'R\$ 0,00';
    }
    
    // Usar o shippingCost calculado pelo provider
    if (cartProvider.shippingCost > 0) {
      return 'R\$ ${cartProvider.shippingCost.toStringAsFixed(2)}';
    }
    
    // Verificar se algum produto tem frete gratuito
    bool hasFreeShipping = cartProvider.items.any((item) => 
      item.product.envio != null && 
      (item.product.envio!.toLowerCase().contains('grátis') || 
       item.product.envio!.toLowerCase().contains('gratis') || 
       item.product.envio!.toLowerCase().contains('free'))
    );
    
    if (hasFreeShipping) {
      return 'Grátis';
    }
    
    // Valor padrão se não há informações de frete
    return 'R\$ 15,00';
  }

  // Widget para excelências da loja
  Widget _buildStoreExcellence() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vantagens Mercado da Sophia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 12),
          
          // Lista de benefícios
          _buildExcellenceItem(
            icon: Icons.local_shipping,
            title: 'Frete Grátis',
            description: 'Em compras selecionadas',
          ),
          _buildExcellenceItem(
            icon: Icons.replay,
            title: 'Devolução Grátis',
            description: 'Até 30 dias para trocar',
          ),
          _buildExcellenceItem(
            icon: Icons.credit_card,
            title: 'Formas de Pagamento',
            description: 'Cartão, PIX, Boleto',
          ),
          _buildExcellenceItem(
            icon: Icons.security,
            title: 'Compra Segura',
            description: 'Seus dados protegidos',
          ),
          _buildExcellenceItem(
            icon: Icons.support_agent,
            title: 'Suporte Especializado',
            description: 'Atendimento via WhatsApp',
          ),
        ],
      ),
    );
  }

  // Item individual da excelência
  Widget _buildExcellenceItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 16,
          ),
        ],
      ),
    );
  }

  // Diálogos
  void _showRemoveItemDialog(CartItem item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Item'),
        content: Text('Deseja remover "${item.displayName}" do carrinho?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeItem(item.id);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Carrinho'),
        content: const Text('Deseja remover todos os itens do carrinho?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showRemoveUnavailableItemsDialog(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Itens Indisponíveis'),
        content: const Text('Deseja remover todos os itens indisponíveis do carrinho?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeUnavailableItems();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
} 