import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../services/freight_service.dart';

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
  final TextEditingController _cepController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _shippingData;
  String? _selectedService;
  String? _userCep;
  bool _isUserLoggedIn = false;
  String? _userAddress;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }

  void _checkUserStatus() {
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isAuthenticated;
    
    setState(() {
      _isUserLoggedIn = isLoggedIn;
    });
    
    if (isLoggedIn) {
      _loadUserAddress();
    }
  }

  Future<void> _loadUserAddress() async {
    try {
      final locationProvider = context.read<LocationProvider>();
      
      // Verificar se o usuário tem endereço salvo
      if (locationProvider.hasSavedAddress && locationProvider.savedAddress != null) {
        final address = locationProvider.savedAddress!;
        print('🏠 Endereço salvo encontrado: $address');
        
        final cep = address['cep'] ?? '';
        final street = address['street'] ?? '';
        final number = address['number'] ?? '';
        final neighborhood = address['neighborhood'] ?? '';
        final city = address['city'] ?? '';
        final state = address['state'] ?? '';
        
        print('📍 Campos do endereço:');
        print('  - CEP: $cep');
        print('  - Street: $street');
        print('  - Number: $number');
        print('  - Neighborhood: $neighborhood');
        print('  - City: $city');
        print('  - State: $state');
        
        setState(() {
          _userAddress = '$street, $number - $neighborhood, $city - $state';
          _userCep = cep;
          _cepController.text = cep;
        });
        
        // Calcular frete real para usuário logado
        await _calculateShipping();
             } else if (locationProvider.hasLocation && locationProvider.currentLocation != null) {
         // Usar localização atual se não tiver endereço salvo
         final location = locationProvider.currentLocation!;
         setState(() {
           _userAddress = location.address ?? location.formattedAddress;
           _userCep = location.postalCode ?? '';
           _cepController.text = location.postalCode ?? '';
         });
        
        // Calcular frete real para usuário logado
        await _calculateShipping();
      } else {
        // Se não tem endereço nem localização, mostrar mensagem
        setState(() {
          _userAddress = 'Endereço não configurado';
          _userCep = '';
        });
      }
    } catch (e) {
      print('Erro ao carregar endereço do usuário: $e');
      setState(() {
        _userAddress = 'Erro ao carregar endereço';
        _userCep = '';
      });
    }
  }

  // Buscar endereço do CEP via ViaCEP
  Future<Map<String, dynamic>> _getCepAddress(String cep) async {
    try {
      // Limpar CEP (remover hífens e espaços)
      final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanCep.length != 8) {
        throw Exception('CEP inválido');
      }

      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['erro'] == true) {
          throw Exception('CEP não encontrado');
        }

        return {
          'logradouro': data['logradouro'] ?? '',
          'bairro': data['bairro'] ?? '',
          'localidade': data['localidade'] ?? '',
          'uf': data['uf'] ?? '',
          'cep': data['cep'] ?? cep,
        };
      } else {
        throw Exception('Erro ao buscar CEP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao buscar endereço do CEP $cep: $e');
      rethrow;
    }
  }

  // Método removido - não é mais necessário pois o FreightService
  // calcula o frete diretamente em BRL usando a API dos Correios

  Future<void> _simulateShippingCalculation() async {
    print('🚀 _simulateShippingCalculation() iniciado');
    
    setState(() {
      _isLoading = true;
      _error = null;
      _shippingData = null;
    });

    // Buscar endereço real do CEP
    final cep = _cepController.text.trim();
    Map<String, dynamic>? realAddress;
    
    if (cep.isNotEmpty) {
      try {
        realAddress = await _getCepAddress(cep);
        print('📍 Endereço encontrado para CEP $cep: $realAddress');
      } catch (e) {
        print('❌ Erro ao buscar endereço do CEP: $e');
        // Usar endereço padrão se falhar
        realAddress = {
          'logradouro': 'Endereço não encontrado',
          'bairro': '',
          'localidade': 'São Paulo',
          'uf': 'SP',
        };
      }
    } else {
      // Usar endereço padrão se não há CEP
      realAddress = {
        'logradouro': 'CEP não informado',
        'bairro': '',
        'localidade': 'São Paulo',
        'uf': 'SP',
      };
    }

    // Simular delay de carregamento
    await Future.delayed(const Duration(seconds: 1));
    print('⏱️ Delay concluído, verificando frete...');

    // Verificar se o produto tem frete gratuito
    bool hasFreeShipping = widget.product.hasFreeShipping;

    if (hasFreeShipping) {
      // Frete gratuito
      print('🚢 Frete Grátis - produto marcado como frete grátis');
      
      final simulatedData = {
        'success': true,
        'address': realAddress,
        'shipping': [
          {
            'service_code': 'FREE_SHIPPING',
            'service_name': 'Frete Grátis',
            'price': 0.0,
            'estimated_days': FreightService.getEstimatedDeliveryDays(),
            'carrier': 'Correios',
          },
        ],
      };

      setState(() {
        _isLoading = false;
        _shippingData = simulatedData;
        _selectedService = 'FREE_SHIPPING';
        widget.onShippingSelected(0.0);
      });
      return;
    }

    // Calcular frete usando o FreightService
    print('🚚 Calculando frete usando API dos Correios...');
    
    try {
      final freightValue = await FreightService.calculateFreight(
        destinationCep: cep,
        weight: widget.product.weight ?? 0.0,
        length: widget.product.length ?? 0.0,
        height: widget.product.height ?? 0.0,
        width: widget.product.width ?? 0.0,
        diameter: widget.product.diameter,
        formato: widget.product.formato,
      );
      
      print('✅ Frete calculado: R\$ ${freightValue.toStringAsFixed(2)}');
      
      final simulatedData = {
        'success': true,
        'address': realAddress,
        'shipping': [
          {
            'service_code': 'PAC',
            'service_name': freightValue == 20.0 ? 'Frete Padrão' : 'Frete Calculado',
            'price': freightValue,
            'estimated_days': FreightService.getEstimatedDeliveryDays(),
            'carrier': 'Correios',
          },
        ],
      };

      setState(() {
        _isLoading = false;
        _shippingData = simulatedData;
        _selectedService = 'PAC';
        widget.onShippingSelected(freightValue);
      });
      
    } catch (e) {
      print('❌ Erro ao calcular frete: $e');
      
      // Em caso de erro, usar frete padrão
      final simulatedData = {
        'success': true,
        'address': realAddress,
        'shipping': [
          {
            'service_code': 'DEFAULT',
            'service_name': 'Frete Padrão',
            'price': 20.0,
            'estimated_days': FreightService.getEstimatedDeliveryDays(),
            'carrier': 'Correios',
          },
        ],
      };

      setState(() {
        _isLoading = false;
        _shippingData = simulatedData;
        _selectedService = 'DEFAULT';
        widget.onShippingSelected(20.0);
      });
    }

    // Este código foi removido pois agora usamos o FreightService
    // que calcula o frete diretamente em BRL usando a API dos Correios
  }

  Future<void> _calculateShipping() async {
    print('🚀 _calculateShipping() chamado');
    
    final cep = _cepController.text.trim();
    print('📝 CEP digitado: "$cep"');
    
    if (cep.isEmpty) {
      print('❌ CEP vazio');
      setState(() {
        _error = 'Digite um CEP válido';
      });
      return;
    }

    print('✅ CEP válido, iniciando cálculo...');
    setState(() {
      _isLoading = true;
      _error = null;
      _shippingData = null;
    });

    try {
      // Sempre usar simulação com valor real do AliExpress (tanto para logados quanto não logados)
      await _simulateShippingCalculation();
    } catch (e) {
      print('❌ Erro no _calculateShipping: $e');
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
              Text(
                _isUserLoggedIn ? 'Endereço de Entrega' : 'Calcular Frete',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interface diferente baseada no status de login
          if (_isUserLoggedIn) ...[
            _buildLoggedInUserInterface(),
          ] else ...[
            _buildGuestUserInterface(),
          ],

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
                    _calculateDeliveryDates(deliveryTime),
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

  Widget _buildLoggedInUserInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Endereço do usuário logado
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.home, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Endereço Cadastrado:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      _userAddress ?? 'Carregando...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Botões de ação
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  print('🔘 Botão Calcular Frete clicado!');
                  print('📊 Estado _isLoading: $_isLoading');
                  _calculateShipping();
                },
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
                    : const Text('Calcular Frete'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar tela para alterar endereço
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade de alterar endereço será implementada em breve'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.edit_location, size: 18),
              label: const Text('Alterar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestUserInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mensagem para usuário não logado
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Faça login para usar seu endereço salvo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Digite um CEP para calcular o frete',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Campo CEP para usuário não logado
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
              onPressed: _isLoading ? null : () {
                print('🔘 Botão Calcular (usuário não logado) clicado!');
                print('📊 Estado _isLoading: $_isLoading');
                _calculateShipping();
              },
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
      ],
    );
  }

  // Calcular datas de entrega
  String _calculateDeliveryDates(int estimatedDays) {
    final now = DateTime.now();
    final startDate = now.add(Duration(days: 12)); // Mínimo 12 dias
    final endDate = now.add(Duration(days: 28));   // Máximo 28 dias
    
    final startDay = startDate.day;
    final startMonth = _getMonthName(startDate.month);
    final startYear = startDate.year;
    
    final endDay = endDate.day;
    final endMonth = _getMonthName(endDate.month);
    final endYear = endDate.year;
    
    if (startYear == endYear) {
      if (startMonth == endMonth) {
        return 'Entrega em $startDay até $endDay de $startMonth de $startYear';
      } else {
        return 'Entrega em $startDay de $startMonth até $endDay de $endMonth de $startYear';
      }
    } else {
      return 'Entrega em $startDay de $startMonth de $startYear até $endDay de $endMonth de $endYear';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return months[month - 1];
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
