import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _selectedPaymentMethod = 'mercadopago';
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = authService.isLoggedIn;
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });

    // Se não estiver logado, mostrar tela de login
    if (!isLoggedIn) {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Seu carrinho está vazio',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione produtos para continuar',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final subtotal = cartProvider.totalPrice;
          final shipping = cartProvider.shippingCost;
          final total = subtotal + shipping;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumo do pedido
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo do Pedido',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de produtos
                        ...cartProvider.items.map((item) => _buildOrderItem(
                          item.product.name,
                          'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                          item.quantity,
                        )),
                        
                        const Divider(),
                        
                        // Totais
                        _buildTotalRow('Subtotal:', 'R\$ ${subtotal.toStringAsFixed(2)}'),
                        _buildTotalRow('Frete:', 'R\$ ${shipping.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildTotalRow('Total:', 'R\$ ${total.toStringAsFixed(2)}', isTotal: true),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Dados de entrega
                Consumer<AddressProvider>(
                  builder: (context, addressProvider, child) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                const Text(
                                  'Endereço de Entrega',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (addressProvider.hasAddress)
                                  TextButton(
                                    onPressed: () => _showAddressDialog(context),
                                    child: const Text('Alterar'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (addressProvider.hasAddress) ...[
                              Text(
                                addressProvider.fullAddress ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              _buildShippingSection(context),
                            ] else ...[
                              _buildCepInputSection(context),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Forma de pagamento
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payment, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Forma de Pagamento',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _showPaymentMethodDialog(),
                              child: const Text('Alterar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentMethodOption(),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Botão finalizar compra
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingOrder ? null : () => _processOrder(cartProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLoggedIn 
                                ? 'Finalizar Compra - R\$ ${total.toStringAsFixed(2)}'
                                : 'Fazer Login para Finalizar',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                if (!_isLoggedIn) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                         context.go('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Já tenho uma conta',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Termos
                const Text(
                  'Ao finalizar a compra, você concorda com nossos Termos de Uso e Política de Privacidade.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(String name, String price, int quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name x$quantity',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption() {
    switch (_selectedPaymentMethod) {
      case 'mercadopago':
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF009EE3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'MP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Checkout Mercado Pago',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF009EE3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Recomendado',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        );
      case 'pix':
        return Row(
          children: [
            const Icon(Icons.pix, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Pix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        );
      case 'credit_card':
        return Row(
          children: [
            const Icon(Icons.credit_card, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Cartão de Crédito',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        );
      case 'boleto':
        return Row(
          children: [
            const Icon(Icons.receipt, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Boleto Bancário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forma de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentOption('mercadopago', 'Checkout Mercado Pago', Icons.payment, const Color(0xFF009EE3), 'Múltiplas formas de pagamento'),
            _buildPaymentOption('pix', 'Pix', Icons.pix, Colors.green, 'Pagamento instantâneo'),
            _buildPaymentOption('credit_card', 'Cartão de Crédito', Icons.credit_card, Colors.blue, 'Parcelado em até 12x'),
            _buildPaymentOption('boleto', 'Boleto Bancário', Icons.receipt, Colors.orange, 'Vencimento em 3 dias'),
          ],
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

  Widget _buildPaymentOption(String value, String title, IconData icon, Color color, String description) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue!;
        });
        context.pop();
      },
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _processOrder(CartProvider cartProvider) async {
    setState(() {
      _isProcessingOrder = true;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      
      if (user == null) {
        // Redirecionar para login
        context.go('/login');
        return;
      }

      final subtotal = cartProvider.totalPrice;
      final shipping = cartProvider.shippingCost;
      final total = subtotal + shipping;

      // Gerar ID único para o pedido
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      // Obter endereço do provider
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      if (!addressProvider.hasAddress) {
        throw Exception('Endereço de entrega não informado');
      }

      // Preparar dados dos itens
      final items = cartProvider.items.map((item) => {
        'id': item.product.id,
        'title': item.product.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
        'variation': item.variation?.toJson(),
      }).toList();

      // Salvar pedido no Firebase com status "aguardando pagamento"
      await _saveOrderToFirebase(
        orderId: orderId,
        user: user,
        items: items,
        total: total,
        shipping: shipping,
        addressProvider: addressProvider,
        paymentMethod: _selectedPaymentMethod,
      );

      // Criar preferência de pagamento no MercadoPago
      final preference = await PaymentService.createPaymentPreference(
        orderId: orderId,
        totalAmount: total,
        customerEmail: user.email ?? '',
        customerName: user.displayName ?? 'Cliente',
        customerPhone: user.phoneNumber ?? '11999999999',
        items: items,
        shippingAddress: addressProvider.toMap(),
      );

      if (preference != null && preference.initPoint != null) {
        // Abrir checkout do MercadoPago
        final success = await launchUrl(
          Uri.parse(preference.initPoint!),
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          // Limpar carrinho após redirecionamento
          cartProvider.clearCart();
          
          // Mostrar mensagem de sucesso
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Pedido criado! Redirecionando para o MercadoPago...'),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Ver Pedidos',
                  onPressed: () => context.go('/meus-pedidos'),
                ),
              ),
            );
            
            // Redirecionar para página de pedidos após um delay
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                context.go('/meus-pedidos');
              }
            });
          }
        } else {
          throw Exception('Não foi possível abrir o checkout do MercadoPago');
        }
      } else {
        throw Exception('Erro ao criar preferência de pagamento');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar pedido: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }



  // Salvar pedido no servidor Python que salva no Firebase
  Future<void> _saveOrderToFirebase({
    required String orderId,
    required dynamic user,
    required List<Map<String, dynamic>> items,
    required double total,
    required double shipping,
    required AddressProvider addressProvider,
    required String paymentMethod,
  }) async {
    try {
      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
        'items': items,
        'total': total,
        'shipping': shipping,
        'shippingAddress': addressProvider.toMap(),
        'paymentMethod': paymentMethod,
      };

      // Fazer requisição para o servidor Python
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/save'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          print('✅ Pedido salvo via servidor Python: $orderId - Status: aguardando_pagamento');
        } else {
          throw Exception('Erro do servidor: ${result['message']}');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode} - ${response.body}');
      }
      } catch (e) {
      print('❌ Erro ao salvar pedido via servidor: $e');
      throw Exception('Erro ao salvar pedido: $e');
    }
  }

  // Seção de input de CEP
  Widget _buildCepInputSection(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final cepController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Digite seu CEP para calcular o frete:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: cepController,
                decoration: const InputDecoration(
                  hintText: '00000-000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: TextInputType.number,
                maxLength: 9,
                onChanged: (value) {
                  // Formatar CEP automaticamente
                  if (value.length == 5 && !value.contains('-')) {
                    cepController.text = '$value-';
                    cepController.selection = TextSelection.fromPosition(
                      TextPosition(offset: cepController.text.length),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: addressProvider.isLoading
                  ? null
                  : () async {
                      if (cepController.text.isNotEmpty) {
                        final success = await addressProvider.searchAddressByCep(cepController.text);
                        if (success) {
                          // Calcular frete automaticamente
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          await cartProvider.calculateShipping(cepController.text);
                        }
                      }
                    },
              child: addressProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Calcular'),
            ),
          ],
        ),
        if (addressProvider.error != null) ...[
          const SizedBox(height: 8),
          Text(
            addressProvider.error!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      ],
    );
  }

  // Seção de informações de frete
  Widget _buildShippingSection(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações de Entrega:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    cartProvider.shippingCost == 0
                        ? 'Frete Grátis'
                        : 'Frete: R\$ ${cartProvider.shippingCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: cartProvider.shippingCost == 0 ? Colors.green : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  const Text('Entrega em 12 até 28 dias'),
                ],
              ),
              if (cartProvider.shippingCost == 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Frete gratuito aplicado',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      addressProvider.fullAddress ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dialog para alterar endereço
  void _showAddressDialog(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final cepController = TextEditingController(text: addressProvider.cep);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Endereço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cepController,
              decoration: const InputDecoration(
                labelText: 'CEP',
                hintText: '00000-000',
              ),
              keyboardType: TextInputType.number,
              maxLength: 9,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cepController.text.isNotEmpty) {
                final success = await addressProvider.searchAddressByCep(cepController.text);
                if (success) {
                  // Recalcular frete
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  await cartProvider.calculateShipping(cepController.text);
                  context.pop();
                }
              }
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
} 