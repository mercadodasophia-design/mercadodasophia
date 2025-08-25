import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  String selectedFilter = 'Todos';

  final List<Map<String, dynamic>> coupons = [
    {
      'code': 'SOPHIA10',
      'discount': '10%',
      'description': 'Desconto de 10% em toda a loja',
      'validUntil': '31/12/2024',
      'minValue': 50.0,
      'color': Colors.green,
      'icon': Icons.local_offer,
      'isActive': true,
    },
    {
      'code': 'FRETE0',
      'discount': 'Frete Grátis',
      'description': 'Frete grátis em compras acima de R\$ 100',
      'validUntil': '15/01/2025',
      'minValue': 100.0,
      'color': Colors.blue,
      'icon': Icons.local_shipping,
      'isActive': true,
    },
    {
      'code': 'DOCES20',
      'discount': '20%',
      'description': '20% de desconto em doces e sobremesas',
      'validUntil': '20/12/2024',
      'minValue': 30.0,
      'color': Colors.purple,
      'icon': Icons.cake,
      'isActive': true,
    },
    {
      'code': 'PRIMEIRA',
      'discount': '15%',
      'description': '15% de desconto na primeira compra',
      'validUntil': '30/12/2024',
      'minValue': 25.0,
      'color': Colors.orange,
      'icon': Icons.star,
      'isActive': true,
    },
    {
      'code': 'LIQUIDA',
      'discount': '30%',
      'description': '30% de desconto em produtos selecionados',
      'validUntil': '10/12/2024',
      'minValue': 40.0,
      'color': Colors.red,
      'icon': Icons.flash_on,
      'isActive': false,
    },
  ];

  List<Map<String, dynamic>> get filteredCoupons {
    if (selectedFilter == 'Todos') {
      return coupons;
    } else if (selectedFilter == 'Ativos') {
      return coupons.where((coupon) => coupon['isActive']).toList();
    } else if (selectedFilter == 'Expirados') {
      return coupons.where((coupon) => !coupon['isActive']).toList();
    }
    return coupons;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
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
          'Cupons',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
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
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cupons Disponíveis',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${filteredCoupons.length} cupons disponíveis',
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
                        'CUPONS',
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
            
            // Filtros
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', selectedFilter == 'Todos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ativos', selectedFilter == 'Ativos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expirados', selectedFilter == 'Expirados'),
                  ],
                ),
              ),
            ),
            
            // Lista de cupons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: filteredCoupons.map((coupon) => _buildCouponCard(coupon)).toList(),
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          selectedFilter = label;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              coupon['color'].withOpacity(0.1),
              coupon['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do cupom
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: coupon['color'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      coupon['icon'],
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon['code'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          coupon['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: coupon['isActive'] ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      coupon['isActive'] ? 'ATIVO' : 'EXPIRADO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Desconto
              Row(
                children: [
                  Text(
                    coupon['discount'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: coupon['color'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'de desconto',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Validade e valor mínimo
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Válido até: ${coupon['validUntil']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    'Mín: R\$ ${coupon['minValue'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: coupon['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Botão de usar cupom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: coupon['isActive'] ? () => _useCoupon(coupon) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coupon['isActive'] ? coupon['color'] : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    coupon['isActive'] ? 'Usar Cupom' : 'Cupom Expirado',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useCoupon(Map<String, dynamic> coupon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cupom ${coupon['code']} aplicado com sucesso!'),
        backgroundColor: AppTheme.primaryColor,
        action: SnackBarAction(
          label: 'Ver Carrinho',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  Widget _buildFooterCategory(String label) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        // Navegar para produtos com categoria selecionada
        Navigator.pushReplacementNamed(context, '/products');
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
} 