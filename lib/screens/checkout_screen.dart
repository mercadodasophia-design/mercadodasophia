import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'client_login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientLoginScreen(),
          ),
        );
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

    if (!_isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Text('Redirecionando para login...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    
                    // Produtos (exemplo)
                    _buildOrderItem('Produto Exemplo 1', 'R\$ 29,90', 1),
                    _buildOrderItem('Produto Exemplo 2', 'R\$ 45,50', 2),
                    
                    const Divider(),
                    
                    // Totais
                    _buildTotalRow('Subtotal:', 'R\$ 120,90'),
                    _buildTotalRow('Frete:', 'R\$ 15,00'),
                    const Divider(),
                    _buildTotalRow('Total:', 'R\$ 135,90', isTotal: true),
                  ],
                ),
              ),
            ),
            
                    const SizedBox(height: 24),
                    
            // Dados de entrega
            Card(
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
                        TextButton(
                          onPressed: () {
                            // TODO: Implementar edição de endereço
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Editar endereço em desenvolvimento'),
                              ),
                            );
                          },
                          child: const Text('Editar'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rua das Flores, 123 - Apto 45\nCentro, São Paulo/SP\nCEP: 01234-567',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
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
                          onPressed: () {
                            // TODO: Implementar seleção de pagamento
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Seleção de pagamento em desenvolvimento'),
                              ),
                            );
                          },
                          child: const Text('Alterar'),
            ),
          ],
        ),
                    const SizedBox(height: 12),
        Row(
          children: [
                        const Icon(Icons.pix, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Pix',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Recomendado',
                            style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Botão finalizar compra
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementar finalização da compra
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Finalização da compra em desenvolvimento'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Finalizar Compra - R\$ 135,90',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            
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
} 