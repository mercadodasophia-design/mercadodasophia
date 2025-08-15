import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/shipping_service.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ShippingCalculatorWidget extends StatefulWidget {
  final Product product;
  final Function(double) onShippingSelected;

  const ShippingCalculatorWidget({
    super.key,
    required this.product,
    required this.onShippingSelected,
  });

  @override
  State<ShippingCalculatorWidget> createState() => _ShippingCalculatorWidgetState();
}

class _ShippingCalculatorWidgetState extends State<ShippingCalculatorWidget> {
  final ShippingService _shippingService = ShippingService();
  final TextEditingController _cepController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _shippingData;
  String? _selectedService;
  String? _userCep;

  @override
  void initState() {
    super.initState();
    _loadUserCep();
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCep() async {
    try {
      final cep = await _shippingService.getUserCep();
      if (cep != null) {
        setState(() {
          _userCep = cep;
          _cepController.text = cep;
        });
        // Calcular frete automaticamente se o usuário tem CEP salvo
        await _calculateShipping();
      }
    } catch (e) {
      print('Erro ao carregar CEP do usuário: $e');
    }
  }

  Future<void> _calculateShipping() async {
    final cep = _cepController.text.trim();
    if (cep.isEmpty) {
      setState(() {
        _error = 'Digite um CEP válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _shippingData = null;
    });

    try {
      final result = await _shippingService.calculateShipping(
        product: widget.product,
        cep: cep,
      );

             setState(() {
         _isLoading = false;
         if (result['success']) {
           _shippingData = result;
           // Selecionar automaticamente o primeiro serviço disponível
           final shippingOptions = result['shipping'] as List<dynamic>?;
           if (shippingOptions != null && shippingOptions.isNotEmpty) {
             final firstOption = shippingOptions.first;
             _selectedService = firstOption['service_code'] ?? 'OWN_ECONOMY';
             final price = firstOption['price'] ?? 0.0;
             widget.onShippingSelected(price);
           }
         } else {
           _error = result['error'] ?? 'Erro ao calcular frete';
         }
       });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao calcular frete: $e';
      });
    }
  }

  void _selectShippingService(String serviceCode, double price) {
    setState(() {
      _selectedService = serviceCode;
    });
    widget.onShippingSelected(price);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Calcular Frete',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo CEP
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cepController,
                  decoration: InputDecoration(
                    labelText: 'CEP',
                    hintText: '00000-000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  inputFormatters: [
                    // Formatar CEP
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateShipping,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Calcular'),
              ),
            ],
          ),

          // Erro
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Resultado do frete
          if (_shippingData != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Endereço
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatAddress(_shippingData!['address']),
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Opções de frete
                  _buildShippingOptions(),
                ],
              ),
            ),
          ],

          // Informações adicionais
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Frete calculado para ${_cepController.text.isNotEmpty ? _cepController.text : 'seu CEP'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOptions() {
    final shippingOptions = _shippingData!['shipping'] as List<dynamic>?;
    if (shippingOptions == null || shippingOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opções de Entrega:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
                 // Listar todas as opções disponíveis
         ...shippingOptions.map((option) {
           final serviceCode = option['service_code'] ?? '';
           final serviceName = option['service_name'] ?? 'Frete';
           final price = (option['price'] ?? 0.0).toDouble();
           final deliveryTime = _parseDeliveryTime(option['estimated_days']);
           final carrier = option['carrier'] ?? '';
          
          return Column(
            children: [
              _buildShippingOption(
                serviceCode: serviceCode,
                serviceName: serviceName,
                price: price,
                deliveryTime: deliveryTime,
                carrier: carrier,
                isSelected: _selectedService == serviceCode,
              ),
              if (shippingOptions.indexOf(option) < shippingOptions.length - 1)
                const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildShippingOption({
    required String serviceCode,
    required String serviceName,
    required double price,
    required int deliveryTime,
    String? carrier,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectShippingService(serviceCode, price),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Informações do serviço
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : Colors.black87,
                    ),
                  ),
                                     Text(
                     'Entrega em $deliveryTime dias úteis',
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.grey[600],
                     ),
                   ),
                   if (carrier != null && carrier.isNotEmpty) ...[
                     Text(
                       'Via $carrier',
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.grey[500],
                       ),
                     ),
                   ],
                ],
              ),
            ),
            
            // Preço
            Text(
              'R\$ ${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = [
      address['logradouro'],
      address['bairro'],
      address['localidade'],
      address['uf'],
    ].where((part) => part != null && part.isNotEmpty).toList();
    
    return parts.join(', ');
  }

  // Parsear tempo de entrega
  int _parseDeliveryTime(dynamic estimatedDays) {
    if (estimatedDays == null) return 0;
    if (estimatedDays is int) return estimatedDays;
    if (estimatedDays is double) return estimatedDays.toInt();
    if (estimatedDays is String) {
      final cleanDays = estimatedDays.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanDays.isEmpty) return 0;
      return int.tryParse(cleanDays) ?? 0;
    }
    return 0;
  }
}
