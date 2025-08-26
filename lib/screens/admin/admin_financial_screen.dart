import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminFinancialScreen extends StatefulWidget {
  const AdminFinancialScreen({super.key});

  @override
  State<AdminFinancialScreen> createState() => _AdminFinancialScreenState();
}

class _AdminFinancialScreenState extends State<AdminFinancialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _generalMarginController = TextEditingController();
  final _productIdController = TextEditingController();
  final _productMarginController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  
  // Dados atuais
  double _currentGeneralMargin = 0.0;
  Map<String, double> _productMargins = {};
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadFinancialSettings();
  }

  @override
  void dispose() {
    _generalMarginController.dispose();
    _productIdController.dispose();
    _productMarginController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar configurações gerais
      final generalDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('financial')
          .get();

      if (generalDoc.exists) {
        final data = generalDoc.data()!;
        _currentGeneralMargin = (data['general_margin'] ?? 0.0).toDouble();
        _generalMarginController.text = _currentGeneralMargin.toString();
      } else {
        _generalMarginController.text = '0.0';
      }

      // Carregar margens específicas de produtos
      final productMarginsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('product_margins')
          .get();

      if (productMarginsDoc.exists) {
        final data = productMarginsDoc.data()!;
        _productMargins = Map<String, double>.from(data);
      }

      // Carregar lista de produtos para referência
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(50) // Limitar para performance
          .get();

      _products = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['titulo'] ?? 'Produto sem título',
          'price': (data['preco'] ?? 0.0).toDouble(),
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar configurações: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGeneralMargin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      final margin = double.parse(_generalMarginController.text);
      
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('financial')
          .set({
        'general_margin': margin,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _currentGeneralMargin = margin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Margem geral salva: ${margin.toStringAsFixed(1)}%'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isSaving = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Erro ao salvar margem geral: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _addProductMargin() async {
    if (_productIdController.text.isEmpty || _productMarginController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o ID do produto e a margem'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      final productId = _productIdController.text.trim();
      final margin = double.parse(_productMarginController.text);

      // Verificar se o produto existe
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Salvar margem específica
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('product_margins')
          .set({
        productId: margin,
      }, SetOptions(merge: true));

      _productMargins[productId] = margin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Margem específica salva: ${margin.toStringAsFixed(1)}%'),
          backgroundColor: Colors.green,
        ),
      );

      _productIdController.clear();
      _productMarginController.clear();

      setState(() {
        _isSaving = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Erro ao salvar margem específica: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _removeProductMargin(String productId) async {
    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('product_margins')
          .update({
        productId: FieldValue.delete(),
      });

      _productMargins.remove(productId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Margem específica removida'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isSaving = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Erro ao remover margem específica: $e';
        _isSaving = false;
      });
    }
  }

  String _getProductTitle(String productId) {
    final product = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => {'title': 'Produto não encontrado'},
    );
    return product['title'] as String;
  }

  double _calculateFinalPrice(double basePrice, double margin) {
    return basePrice * (1 + margin / 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFinancialSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFinancialSettings,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Margem Geral
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Margem de Lucro Geral',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Esta margem será aplicada a todos os produtos que não tenham margem específica definida.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _generalMarginController,
                                        decoration: const InputDecoration(
                                          labelText: 'Margem (%)',
                                          hintText: 'Ex: 100',
                                          suffixText: '%',
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
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Salvar'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Exemplo de Cálculo:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Produto base: R\$ 20,00'),
                                      Text('Margem: ${_currentGeneralMargin.toStringAsFixed(1)}%'),
                                      Text(
                                        'Preço final: R\$ ${_calculateFinalPrice(20.0, _currentGeneralMargin).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                                'Defina margens específicas para produtos individuais. Estas margens têm prioridade sobre a margem geral.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              
                              // Formulário para adicionar margem específica
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _productIdController,
                                      decoration: const InputDecoration(
                                        labelText: 'ID do Produto',
                                        hintText: 'Ex: produto_123',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _productMarginController,
                                      decoration: const InputDecoration(
                                        labelText: 'Margem (%)',
                                        hintText: 'Ex: 50',
                                        suffixText: '%',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isSaving ? null : _addProductMargin,
                                    child: const Text('Adicionar'),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Lista de margens específicas
                              if (_productMargins.isNotEmpty) ...[
                                const Text(
                                  'Margens Específicas Ativas:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...(_productMargins.entries.map((entry) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(_getProductTitle(entry.key)),
                                      subtitle: Text('ID: ${entry.key}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${entry.value.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _removeProductMargin(entry.key),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList()),
                              ] else ...[
                                const Text(
                                  'Nenhuma margem específica definida',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Lista de Produtos para Referência
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Produtos Disponíveis (últimos 50)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Use os IDs abaixo para definir margens específicas:',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ...(_products.map((product) {
                                final productId = product['id'] as String;
                                final hasSpecificMargin = _productMargins.containsKey(productId);
                                final margin = hasSpecificMargin 
                                    ? _productMargins[productId]! 
                                    : _currentGeneralMargin;
                                final finalPrice = _calculateFinalPrice(
                                  product['price'] as double, 
                                  margin
                                );
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: hasSpecificMargin ? Colors.orange[50] : null,
                                  child: ListTile(
                                    title: Text(product['title'] as String),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ID: $productId'),
                                        Text('Preço base: R\$ ${(product['price'] as double).toStringAsFixed(2)}'),
                                        Text(
                                          'Preço final: R\$ ${finalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          hasSpecificMargin 
                                              ? 'Margem específica: ${margin.toStringAsFixed(1)}%'
                                              : 'Margem geral: ${margin.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: hasSpecificMargin ? Colors.orange[700] : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: hasSpecificMargin
                                        ? const Icon(Icons.star, color: Colors.orange)
                                        : null,
                                  ),
                                );
                              }).toList()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
