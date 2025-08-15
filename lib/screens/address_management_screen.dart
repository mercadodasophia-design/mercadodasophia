import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cep_service.dart';
import '../providers/location_provider.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSearchingCep = false;
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = doc.data();
        if (userData != null && userData['addresses'] != null) {
          setState(() {
            _addresses = List<Map<String, dynamic>>.from(userData['addresses']);
            _selectedAddress = userData['selectedAddress'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar endereços: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCep() async {
    final cep = _cepController.text;
    
    if (!CepService.isValidCep(cep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CEP deve ter 8 dígitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearchingCep = true;
    });

    try {
      final response = await CepService.searchCep(cep);

      if (response != null) {
        _streetController.text = response['logradouro'] ?? '';
        _neighborhoodController.text = response['bairro'] ?? '';
        _cityController.text = response['localidade'] ?? '';
        _stateController.text = response['uf'] ?? '';
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço encontrado!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar CEP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearchingCep = false;
      });
    }
  }



  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
                          final newAddress = {
           'id': DateTime.now().millisecondsSinceEpoch.toString(),
           'cep': _cepController.text,
           'street': _streetController.text,
           'number': _numberController.text,
           'complement': _complementController.text,
           'neighborhood': _neighborhoodController.text,
           'city': _cityController.text,
           'state': _stateController.text,
           'isDefault': _addresses.isEmpty, // Primeiro endereço é padrão
           'createdAt': DateTime.now().toIso8601String(),
         };

         final updatedAddresses = [..._addresses, newAddress];
         
         // Se for o primeiro endereço, definir como padrão
         Map<String, dynamic>? selectedAddress = _selectedAddress;
         if (_addresses.isEmpty) {
           selectedAddress = newAddress;
         }
         
         await FirebaseFirestore.instance
             .collection('users')
             .doc(user.uid)
             .update({
           'addresses': updatedAddresses,
           if (selectedAddress != null) 'selectedAddress': selectedAddress,
         });

         setState(() {
           _addresses = updatedAddresses;
           if (selectedAddress != null) {
             _selectedAddress = selectedAddress;
           }
         });

         // Atualizar LocationProvider com o novo endereço se for o primeiro
         final locationProvider = Provider.of<LocationProvider>(context, listen: false);
         if (_addresses.isEmpty) {
           locationProvider.setSavedAddress(newAddress);
         }

        _clearForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar endereço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setDefaultAddress(Map<String, dynamic> address) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final updatedAddresses = _addresses.map((addr) {
          if (addr['id'] == address['id']) {
            return {...addr, 'isDefault': true};
          } else {
            return {...addr, 'isDefault': false};
          }
        }).toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'addresses': updatedAddresses,
          'selectedAddress': address,
        });

        setState(() {
          _addresses = updatedAddresses;
          _selectedAddress = address;
        });

        // Atualizar LocationProvider com o novo endereço padrão
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        locationProvider.setSavedAddress(address);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço definido como padrão!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao definir endereço padrão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Endereço'),
        content: const Text('Tem certeza que deseja excluir este endereço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final updatedAddresses = _addresses.where((addr) => addr['id'] != address['id']).toList();
        
        // Se o endereço excluído era o padrão, definir o primeiro como padrão
        Map<String, dynamic>? newDefaultAddress;
        if (address['isDefault'] == true && updatedAddresses.isNotEmpty) {
          updatedAddresses[0]['isDefault'] = true;
          newDefaultAddress = updatedAddresses[0];
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'addresses': updatedAddresses,
          if (newDefaultAddress != null) 'selectedAddress': newDefaultAddress,
        });

                 setState(() {
           _addresses = updatedAddresses;
           if (newDefaultAddress != null) {
             _selectedAddress = newDefaultAddress;
           } else {
             _selectedAddress = null;
           }
         });

         // Atualizar LocationProvider se o endereço excluído era o padrão
         final locationProvider = Provider.of<LocationProvider>(context, listen: false);
         if (address['isDefault'] == true) {
           if (newDefaultAddress != null) {
             locationProvider.setSavedAddress(newDefaultAddress);
           } else {
             locationProvider.clearSavedAddress();
           }
         }

         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Endereço excluído com sucesso!'),
             backgroundColor: Colors.green,
           ),
         );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir endereço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _cepController.clear();
    _streetController.clear();
    _numberController.clear();
    _complementController.clear();
    _neighborhoodController.clear();
    _cityController.clear();
    _stateController.clear();
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
          'Meus Endereços',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                                 // Informações sobre endereços
                 Container(
                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.blue.shade50,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.blue.shade200),
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           'Você pode ter vários endereços de entrega. O endereço marcado como "Padrão" será usado automaticamente na home.',
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.blue.shade700,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 
                 // Formulário para adicionar endereço
                 Container(
                   margin: const EdgeInsets.all(16),
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.1),
                         blurRadius: 4,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                   child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Novo Endereço',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // CEP
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cepController,
                                decoration: const InputDecoration(
                                  labelText: 'CEP',
                                  hintText: '00000-000',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o CEP';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isSearchingCep ? null : _searchCep,
                              child: _isSearchingCep
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Buscar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Rua
                        TextFormField(
                          controller: _streetController,
                          decoration: const InputDecoration(
                            labelText: 'Rua/Avenida',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite a rua';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Número e Complemento
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _numberController,
                                decoration: const InputDecoration(
                                  labelText: 'Número',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o número';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _complementController,
                                decoration: const InputDecoration(
                                  labelText: 'Complemento (opcional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Bairro
                        TextFormField(
                          controller: _neighborhoodController,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite o bairro';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Cidade e Estado
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'Cidade',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite a cidade';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o estado';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Salvar Endereço',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lista de endereços
                Expanded(
                  child: _addresses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum endereço cadastrado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            final isDefault = address['isDefault'] == true;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${address['street']}, ${address['number']}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (address['complement']?.isNotEmpty == true)
                                                Text(
                                                  address['complement'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Text(
                                                '${address['neighborhood']}, ${address['city']} - ${address['state']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'CEP: ${address['cep']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Padrão',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                                                         Row(
                                       children: [
                                         if (!isDefault)
                                           Expanded(
                                             child: OutlinedButton(
                                               onPressed: () => _setDefaultAddress(address),
                                               child: const Text('Definir como Padrão'),
                                             ),
                                           ),
                                         const SizedBox(width: 8),
                                         Expanded(
                                           child: OutlinedButton(
                                             onPressed: () => _deleteAddress(address),
                                             style: OutlinedButton.styleFrom(
                                               foregroundColor: Colors.red,
                                             ),
                                             child: const Text('Excluir'),
                                           ),
                                         ),
                                       ],
                                     ),
                                     if (isDefault)
                                       const Padding(
                                         padding: EdgeInsets.only(top: 8),
                                         child: Text(
                                           'Este é seu endereço padrão de entrega',
                                           style: TextStyle(
                                             fontSize: 12,
                                             color: Colors.green,
                                             fontWeight: FontWeight.w500,
                                           ),
                                         ),
                                       ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
