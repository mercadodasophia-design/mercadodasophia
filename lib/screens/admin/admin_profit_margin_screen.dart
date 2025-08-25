import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_auth_service.dart';

class AdminProfitMarginScreen extends StatefulWidget {
  const AdminProfitMarginScreen({super.key});

  @override
  State<AdminProfitMarginScreen> createState() => _AdminProfitMarginScreenState();
}

class _AdminProfitMarginScreenState extends State<AdminProfitMarginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _generalMarginController = TextEditingController();
  final _productMarginController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  double _generalMargin = 0.0;
  Map<String, double> _productMargins = {};
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _loadProfitMargins();
  }

  @override
  void dispose() {
    _generalMarginController.dispose();
    _productMarginController.dispose();
    super.dispose();
  }

  Future<void> _loadProfitMargins() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final firestore = FirebaseFirestore.instance;

      // Carregar margem geral
      final generalDoc = await firestore.collection('settings').doc('profit_margin').get();
      if (generalDoc.exists) {
        final data = generalDoc.data()!;
        _generalMargin = (data['general_margin'] ?? 0.0).toDouble();
        _generalMarginController.text = _generalMargin.toString();
      }

      // Carregar margens específicas de produtos
      final productMarginsDoc = await firestore.collection('settings').doc('product_margins').get();
      if (productMarginsDoc.exists) {
        final data = productMarginsDoc.data()!;
        _productMargins = Map<String, double>.from(data);
      }

      // Carregar produtos
      final productsSnapshot = await firestore.collection('products').get();
      _products = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Produto sem nome',
          'price': (data['price'] ?? 0.0).toDouble(),
          'originalPrice': (data['originalPrice'] ?? data['price'] ?? 0.0).toDouble(),
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Erro ao carregar margens de lucro: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGeneralMargin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final newMargin = double.parse(_generalMarginController.text);
      
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('settings').doc('profit_margin').set({
        'general_margin': newMargin,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _generalMargin = newMargin;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Margem geral salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar margem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProductMargin() async {
    if (_selectedProductId == null) return;
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final newMargin = double.parse(_productMarginController.text);
      
      final firestore = FirebaseFirestore.instance;
      
      // Salvar margem específica do produto
      await firestore.collection('settings').doc('product_margins').set({
        ..._productMargins,
        _selectedProductId!: newMargin,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Atualizar preço do produto com a nova margem
      final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
      final originalPrice = product['originalPrice'] as double;
      final newPrice = originalPrice * (1 + newMargin / 100);

      await firestore.collection('products').doc(_selectedProductId).update({
        'price': newPrice,
        'profitMargin': newMargin,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _productMargins[_selectedProductId!] = newMargin;
        _isSaving = false;
        _selectedProductId = null;
        _productMarginController.clear();
      });

      // Recarregar produtos para atualizar preços
      await _loadProfitMargins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Margem do produto salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar margem do produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyGeneralMarginToAllProducts() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final product in _products) {
        final originalPrice = product['originalPrice'] as double;
        final newPrice = originalPrice * (1 + _generalMargin / 100);
        
        final productRef = firestore.collection('products').doc(product['id']);
        batch.update(productRef, {
          'price': newPrice,
          'profitMargin': _generalMargin,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();

      setState(() {
        _isSaving = false;
      });

      // Recarregar produtos
      await _loadProfitMargins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Margem geral aplicada a todos os produtos!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aplicar margem geral: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getProductMargin(String productId) {
    return _productMargins[productId] ?? _generalMargin;
  }

  double _getProductPrice(String productId) {
    final product = _products.firstWhere((p) => p['id'] == productId);
    final originalPrice = product['originalPrice'] as double;
    final margin = _getProductMargin(productId);
    return originalPrice * (1 + margin / 100);
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
        title: const Text('Gerenciar Margem de Lucro'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Margem Geral
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Margem Geral de Lucro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Esta margem será aplicada a todos os produtos que não tenham margem específica definida.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _generalMarginController,
                              decoration: const InputDecoration(
                                labelText: 'Margem (%)',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Digite a margem';
                                }
                                final margin = double.tryParse(value);
                                if (margin == null || margin < 0) {
                                  return 'Margem inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveGeneralMargin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _applyGeneralMarginToAllProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Aplicar a Todos os Produtos'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Margens Específicas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Margens Específicas por Produto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Defina margens específicas para produtos individuais. Produtos sem margem específica usarão a margem geral.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Seleção de produto
                      DropdownButtonFormField<String>(
                        value: _selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Produto',
                          border: OutlineInputBorder(),
                        ),
                        items: _products.map((product) {
                          return DropdownMenuItem(
                            value: product['id'],
                            child: Text(product['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductId = value;
                            if (value != null) {
                              final margin = _getProductMargin(value);
                              _productMarginController.text = margin.toString();
                            } else {
                              _productMarginController.clear();
                            }
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Margem do produto
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _productMarginController,
                              decoration: const InputDecoration(
                                labelText: 'Margem do Produto (%)',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Digite a margem';
                                }
                                final margin = double.tryParse(value);
                                if (margin == null || margin < 0) {
                                  return 'Margem inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSaving || _selectedProductId == null ? null : _saveProductMargin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Lista de produtos com margens
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Produtos e Margens',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final productId = product['id'] as String;
                          final margin = _getProductMargin(productId);
                          final originalPrice = product['originalPrice'] as double;
                          final currentPrice = _getProductPrice(productId);
                          final isCustomMargin = _productMargins.containsKey(productId);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Preço Original: R\$ ${originalPrice.toStringAsFixed(2)}'),
                                  Text('Preço Atual: R\$ ${currentPrice.toStringAsFixed(2)}'),
                                  Text(
                                    'Margem: ${margin.toStringAsFixed(1)}% ${isCustomMargin ? '(Específica)' : '(Geral)'}',
                                    style: TextStyle(
                                      color: isCustomMargin ? Colors.blue : Colors.grey,
                                      fontWeight: isCustomMargin ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                isCustomMargin ? Icons.star : Icons.star_border,
                                color: isCustomMargin ? Colors.blue : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
