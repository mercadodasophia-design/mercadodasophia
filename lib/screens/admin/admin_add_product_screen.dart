import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para os campos
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _ofertaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _tipoController = TextEditingController();
  final _origemController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _aliexpressIdController = TextEditingController();
  final _envioController = TextEditingController();
  
  // Lista de imagens
  List<String> _images = [];
  List<dynamic> _imageFiles = []; // Para compatibilidade Web/Mobile
  
  // Lista de variações
  List<ProductVariation> _variacoes = [];
  
  // Estados
  bool _isLoading = false;
  bool _hasOferta = false;
  String _selectedSection = 'Loja'; // 'Loja' ou 'SexyShop'
  
  // Categorias disponíveis
  final List<String> _categorias = [
    'Garrafeira',
    'Compotas e Mel',
    'Doces',
    'Chás e Refrescos',
    'Queijos e Pão',
    'Outros'
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _ofertaController.dispose();
    _marcaController.dispose();
    _tipoController.dispose();
    _origemController.dispose();
    _categoriaController.dispose();
    _aliexpressIdController.dispose();
    _envioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        if (kIsWeb) {
          _imageFiles.add(image); // Para Web, usar XFile diretamente
        } else {
          _imageFiles.add(File(image.path)); // Para Mobile, usar File
        }
        _images.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      _images.removeAt(index);
    });
  }

  void _addVariacao() {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma imagem antes de criar variações'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => _VariacaoDialog(
        availableImages: _images,
        availableImageFiles: _imageFiles,
        onSave: (variacao) {
          setState(() {
            _variacoes.add(variacao);
          });
        },
      ),
    );
  }

  void _removeVariacao(int index) {
    setState(() {
      _variacoes.removeAt(index);
    });
  }

  void _showAddCategoryDialog() {
    final TextEditingController newCategoryController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Nova Categoria'),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        content: SizedBox(
          width: 300,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite o nome da nova categoria:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Eletrônicos, Roupas, etc.',
                    isDense: true,
                  ),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o nome da categoria';
                    }
                    if (_categorias.contains(value.trim())) {
                      return 'Esta categoria já existe';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) {
                    if (formKey.currentState!.validate()) {
                      final newCategory = newCategoryController.text.trim();
                      if (newCategory.isNotEmpty && !_categorias.contains(newCategory)) {
                        setState(() {
                          _categorias.add(newCategory);
                          _categoriaController.text = newCategory;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Categoria "$newCategory" adicionada com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newCategory = newCategoryController.text.trim();
                if (newCategory.isNotEmpty && !_categorias.contains(newCategory)) {
                  setState(() {
                    _categorias.add(newCategory);
                    _categoriaController.text = newCategory;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Categoria "$newCategory" adicionada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma imagem'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Upload das imagens
      final List<String> imageUrls = [];
      for (int i = 0; i < _imageFiles.length; i++) {
        final imageUrl = await _uploadImage(_imageFiles[i], 'products/${DateTime.now().millisecondsSinceEpoch}_$i');
        imageUrls.add(imageUrl);
      }

      // Criar produto
      final product = Product(
        aliexpressId: _aliexpressIdController.text.trim().isEmpty ? null : _aliexpressIdController.text.trim(),
        images: imageUrls,
        titulo: _tituloController.text.trim(),
        variacoes: _variacoes.isEmpty ? [
          ProductVariation(
            skuId: 'default',
            preco: double.parse(_precoController.text),
          )
        ] : _variacoes,
        descricao: _descricaoController.text.trim(),
        preco: double.parse(_precoController.text),
        oferta: null, // Campo oferta fica nulo
        descontoPercentual: _hasOferta ? double.parse(_ofertaController.text) : null,
        marca: _marcaController.text.trim(),
        tipo: _tipoController.text.trim(),
        origem: _origemController.text.trim(),
        categoria: _categoriaController.text.trim(),
        dataPost: DateTime.now(),
        idAdmin: user.uid,
        envio: _envioController.text.trim().isEmpty ? null : _envioController.text.trim(),
        secao: _selectedSection, // Adicionar seção
      );

      // Salvar no Firebase
      await FirebaseFirestore.instance.collection('products').add(product.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar produto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadImage(dynamic imageFile, String path) async {
    final Reference storageRef = FirebaseStorage.instance.ref().child(path);
    late UploadTask uploadTask;
    
    if (kIsWeb && imageFile is XFile) {
      // Para Web, usar bytes
      final bytes = await imageFile.readAsBytes();
      uploadTask = storageRef.putData(bytes);
    } else if (imageFile is File) {
      // Para Mobile, usar File
      uploadTask = storageRef.putFile(imageFile);
    } else {
      throw Exception('Tipo de arquivo não suportado');
    }
    
    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Adicionar Produto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin/login');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagens
                    _buildImagesSection(),
                    const SizedBox(height: 24),
                    
                    // Informações básicas
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    
                    // Variações
                    _buildVariationsSection(),
                    const SizedBox(height: 24),
                    
                    // Botão salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Salvar Produto',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imagens do Produto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid de imagens
            if (_images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb && _imageFiles[index] is XFile
                            ? FutureBuilder<Uint8List>(
                                future: (_imageFiles[index] as XFile).readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    );
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                            : Image.file(
                                _imageFiles[index] as File,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            
            const SizedBox(height: 16),
            
            // Botão adicionar imagem
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Adicionar Imagem'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Básicas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título do Produto *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o título do produto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Seção do produto
            DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(
                labelText: 'Seção do Produto *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Loja',
                  child: Text('Loja (produtos/secao: Loja)'),
                ),
                DropdownMenuItem(
                  value: 'SexyShop',
                  child: Text('SexyShop (produtos/secao: SexyShop)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSection = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione uma seção';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite a descrição do produto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precoController,
                    decoration: const InputDecoration(
                      labelText: 'Preço *',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite o preço';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Digite um preço válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ofertaController,
                    decoration: const InputDecoration(
                      labelText: 'Desconto (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                      hintText: 'Ex: 20 (para 20% de desconto)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _hasOferta,
                    validator: _hasOferta ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite a porcentagem de desconto';
                      }
                      final percentage = double.tryParse(value);
                      if (percentage == null || percentage < 0 || percentage > 100) {
                        return 'Digite um valor entre 0 e 100';
                      }
                      return null;
                    } : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            CheckboxListTile(
              title: const Text('Produto em oferta (desconto)'),
              subtitle: _hasOferta ? const Text('Informe a porcentagem de desconto acima') : null,
              value: _hasOferta,
              onChanged: (value) {
                setState(() {
                  _hasOferta = value ?? false;
                  if (!_hasOferta) {
                    _ofertaController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite a marca';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tipoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite o tipo';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _origemController,
                    decoration: const InputDecoration(
                      labelText: 'Origem *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite a origem';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _categoriaController.text.isEmpty ? null : _categoriaController.text,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ..._categorias.map((categoria) {
                            return DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria),
                            );
                          }).toList(),
                          const DropdownMenuItem(
                            value: 'nova_categoria',
                            child: Row(
                              children: [
                                Icon(Icons.add, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Adicionar nova categoria...'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == 'nova_categoria') {
                            _showAddCategoryDialog();
                          } else {
                            setState(() {
                              _categoriaController.text = value ?? '';
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione uma categoria';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _envioController,
              decoration: const InputDecoration(
                labelText: 'Tipo de Envio (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Ex: entrega grátis, pago',
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _aliexpressIdController,
              decoration: const InputDecoration(
                labelText: 'ID AliExpress (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Variações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addVariacao,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_variacoes.isEmpty)
              const Text(
                'Nenhuma variação adicionada. O produto será criado com uma variação padrão.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variacoes.length,
                itemBuilder: (context, index) {
                  final variacao = _variacoes[index];
                  return ListTile(
                    title: Text(variacao.displayName),
                    subtitle: Text('R\$ ${variacao.preco.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeVariacao(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mercado da Sophia',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Itens do menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/admin/dashboard');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.image,
                  title: 'Banner',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/banners');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_box,
                  title: 'Adicionar Produto',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Gerenciar Produtos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/manage-products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag,
                  title: 'Gestão de Pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/orders');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categorias',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/categories');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Usuários',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/users');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/admin/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

// Dialog para adicionar variação
class _VariacaoDialog extends StatefulWidget {
  final Function(ProductVariation) onSave;
  final List<String> availableImages;
  final List<dynamic> availableImageFiles;

  const _VariacaoDialog({
    required this.onSave,
    required this.availableImages,
    required this.availableImageFiles,
  });

  @override
  State<_VariacaoDialog> createState() => _VariacaoDialogState();
}

class _VariacaoDialogState extends State<_VariacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _skuIdController = TextEditingController();
  final _corController = TextEditingController();
  final _tamanhoController = TextEditingController();
  final _precoController = TextEditingController();
  int? _selectedImageIndex;

  @override
  void dispose() {
    _skuIdController.dispose();
    _corController.dispose();
    _tamanhoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final selectedImagePath = _selectedImageIndex != null 
        ? widget.availableImages[_selectedImageIndex!] 
        : null;

    final variacao = ProductVariation(
      skuId: _skuIdController.text.trim(),
      color: _corController.text.trim().isEmpty ? null : _corController.text.trim(),
      size: _tamanhoController.text.trim().isEmpty ? null : _tamanhoController.text.trim(),
      image: selectedImagePath,
      preco: double.parse(_precoController.text),
    );

    widget.onSave(variacao);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Variação'),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            TextFormField(
              controller: _skuIdController,
              decoration: const InputDecoration(
                labelText: 'SKU ID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o SKU ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _corController,
              decoration: const InputDecoration(
                labelText: 'Cor (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _tamanhoController,
              decoration: const InputDecoration(
                labelText: 'Tamanho (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _precoController,
              decoration: const InputDecoration(
                labelText: 'Preço *',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o preço';
                }
                if (double.tryParse(value) == null) {
                  return 'Digite um preço válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Seleção de imagem
            const Text(
              'Selecionar Imagem (opcional):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.availableImages.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma imagem disponível',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: List.generate(
                          widget.availableImages.length,
                          (index) {
                            final isSelected = _selectedImageIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageIndex = isSelected ? null : index;
                                });
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: kIsWeb && widget.availableImageFiles[index] is XFile
                                      ? FutureBuilder<Uint8List>(
                                          future: (widget.availableImageFiles[index] as XFile).readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          widget.availableImageFiles[index] as File,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
    actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
