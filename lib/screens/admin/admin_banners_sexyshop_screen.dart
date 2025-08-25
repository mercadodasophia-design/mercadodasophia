import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/banner_model.dart' as banner_model;
import '../../services/banner_service.dart';
import '../../services/auth_service.dart';

class AdminBannersSexyShopScreen extends StatefulWidget {
  const AdminBannersSexyShopScreen({super.key});

  @override
  State<AdminBannersSexyShopScreen> createState() => _AdminBannersSexyShopScreenState();
}

class _AdminBannersSexyShopScreenState extends State<AdminBannersSexyShopScreen> {
  final BannerService _bannerService = BannerService();
  List<banner_model.Banner> _banners = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final banners = await _bannerService.getSexyShopBanners();
      setState(() {
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar banners: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBannerStatus(banner_model.Banner banner) async {
    try {
      await _bannerService.toggleBannerStatus(
        banner.id, 
        !banner.isAtivo
      );
      
      await _loadBanners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            banner.isAtivo 
              ? 'Banner desativado com sucesso!' 
              : 'Banner ativado com sucesso!'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBanner(banner_model.Banner banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o banner "${banner.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bannerService.deleteBanner(banner.id);
        
        await _loadBanners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Banners SexyShop',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBanners,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBanners,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _banners.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: const Color(0xFFFF6B9D),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum banner encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione banners para o SexyShop',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBanners,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagem do banner
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.network(
                                      banner.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                
                                // Informações do banner
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              banner.nome,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: banner.isAtivo
                                                  ? const Color(0xFFFF6B9D)
                                                  : Colors.grey,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              banner.isAtivo ? 'Ativo' : 'Inativo',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      if (banner.linkProduto != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Link: ${banner.linkProduto}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[600],
                                          ),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 8),
                                      Text(
                                        'Data: ${_formatDate(banner.data)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Botões de ação
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _toggleBannerStatus(banner),
                                              icon: Icon(
                                                banner.isAtivo
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                              label: Text(
                                                banner.isAtivo
                                                    ? 'Desativar'
                                                    : 'Ativar',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: banner.isAtivo
                                                    ? Colors.orange
                                                    : const Color(0xFFFF6B9D),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _deleteBanner(banner),
                                              icon: const Icon(Icons.delete),
                                              label: const Text('Excluir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
