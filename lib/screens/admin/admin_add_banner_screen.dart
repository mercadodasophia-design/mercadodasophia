import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/banner_model.dart' as banner_model;
import '../../services/banner_service.dart';

class AdminAddBannerScreen extends StatefulWidget {
  const AdminAddBannerScreen({super.key});

  @override
  State<AdminAddBannerScreen> createState() => _AdminAddBannerScreenState();
}

class _AdminAddBannerScreenState extends State<AdminAddBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _linkProdutoController = TextEditingController();
  
  BannerService _bannerService = BannerService();
  String _selectedSection = 'Loja'; // 'Loja' ou 'SexyShop'
  dynamic _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _linkProdutoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao selecionar imagem: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      String imageUrl;
      if (kIsWeb) {
        // Para web, usar putData
        final Uint8List bytes = await _selectedImage.readAsBytes();
        final ref = FirebaseStorage.instance
            .ref()
            .child('banners/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(bytes);
        imageUrl = await ref.getDownloadURL();
      } else {
        // Para mobile, usar putFile
        final ref = FirebaseStorage.instance
            .ref()
            .child('banners/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage);
        imageUrl = await ref.getDownloadURL();
      }

      setState(() {
        _isUploading = false;
      });

      return imageUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      _showErrorSnackBar('Selecione uma imagem para o banner');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload da imagem
      final imageUrl = await _uploadImage();
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obter ID do admin logado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuário não autenticado');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Criar banner
      final banner = banner_model.Banner(
        id: '',
        nome: _nomeController.text.trim(),
        image: imageUrl,
        data: DateTime.now(),
        linkProduto: _linkProdutoController.text.trim().isEmpty 
            ? null 
            : _linkProdutoController.text.trim(),
        isAtivo: true,
        idAdmin: user.uid,
        secao: _selectedSection,
      );

      // Salvar no Firebase
      await _bannerService.addBanner(banner);

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Banner adicionado com sucesso!');
      
      // Limpar formulário
      _formKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erro ao salvar banner: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'Adicionar Banner',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card principal
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do Banner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Seção do banner
                      DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Seção do Banner',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Loja',
                            child: Text('Loja (banners/secao: Loja)'),
                          ),
                          DropdownMenuItem(
                            value: 'SexyShop',
                            child: Text('SexyShop (banners/secao: SexyShop)'),
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

                      // Nome do banner
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Banner',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite o nome do banner';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Link do produto (opcional)
                      TextFormField(
                        controller: _linkProdutoController,
                        decoration: const InputDecoration(
                          labelText: 'Link do Produto (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          hintText: 'https://exemplo.com/produto',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Upload de imagem
                      const Text(
                        'Imagem do Banner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Preview da imagem
                      if (_selectedImage != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImage.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  )
                                : Image.file(
                                    _selectedImage,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Botão para selecionar imagem
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: const Icon(Icons.photo_camera),
                          label: Text(_selectedImage == null 
                              ? 'Selecionar Imagem' 
                              : 'Alterar Imagem'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botão salvar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isUploading ? null : _saveBanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading || _isUploading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Salvando...'),
                                  ],
                                )
                              : const Text(
                                  'Salvar Banner',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Informações sobre as seções
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações sobre as Seções',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                                             const Text(
                         '• Loja: Banners exibidos na página principal da loja (coleção: banners)',
                         style: TextStyle(fontSize: 14),
                       ),
                      const SizedBox(height: 4),
                                             const Text(
                         '• SexyShop: Banners exibidos na seção SexyShop (coleção: banners)',
                         style: TextStyle(fontSize: 14),
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
