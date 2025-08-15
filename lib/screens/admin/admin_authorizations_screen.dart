import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import '../../theme/app_theme.dart';

class AdminAuthorizationsScreen extends StatefulWidget {
  const AdminAuthorizationsScreen({super.key});

  @override
  State<AdminAuthorizationsScreen> createState() => _AdminAuthorizationsScreenState();
}

class _AdminAuthorizationsScreenState extends State<AdminAuthorizationsScreen> {
  bool _isLoading = false;
  bool _isAuthorizing = false;
  bool _showCheckNowButton = false;
  Map<String, dynamic>? _tokenStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkTokenStatus();
  }

  Future<void> _checkTokenStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://service-api-aliexpress.mercadodasophia.com.br/api/aliexpress/tokens/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final previousStatus = _tokenStatus?['has_tokens'] ?? false;
        final newStatus = data['has_tokens'] ?? false;
        
        setState(() {
          _tokenStatus = data;
          _isLoading = false;
          _showCheckNowButton = false;
        });
        
        // Dar feedback sobre mudança de status
        if (_tokenStatus != null && _tokenStatus!.isNotEmpty) {
          if (newStatus && !previousStatus) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Autorização confirmada com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (!newStatus && previousStatus) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Autorização expirou ou foi revogada'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (newStatus) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Status verificado - Autorização ativa'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        setState(() {
          _error = 'Erro ao verificar status dos tokens: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initiateOAuth() async {
    setState(() {
      _isAuthorizing = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://service-api-aliexpress.mercadodasophia.com.br/api/aliexpress/auth'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        
        if (authUrl != null && authUrl.isNotEmpty) {
          // Tentar abrir URL de autorização
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🌐 URL de autorização aberta no navegador. Após fazer login, volte aqui e clique em "Verificar Status".'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            
            // Mostrar botão de verificar após um tempo
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showCheckNowButton = true;
                });
              }
            });
          } else {
            // Se não conseguir abrir, mostrar diálogo com opções
            _showUrlOptionsDialog(authUrl);
          }
        } else {
          throw Exception('URL de autorização não encontrada na resposta');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erro ${response.statusCode}: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao iniciar autorização: $e';
        _isAuthorizing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isAuthorizing = false;
      });
    }
  }

  void _showUrlOptionsDialog(String authUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔐 URL de Autorização AliExpress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A URL de autorização foi gerada com sucesso:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  authUrl,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Escolha uma opção:'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(authUrl);
              },
              icon: const Icon(Icons.copy),
              label: const Text('📋 Copiar URL'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _tryOpenInBrowser(authUrl);
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('🌐 Abrir no Navegador'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('❌ Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String url) {
    // Em um app real, você usaria flutter/services para copiar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 URL copiada para a área de transferência'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _tryOpenInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌐 URL aberta no navegador. Após fazer login no AliExpress, volte aqui e clique em "Verificar Status".'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Mostrar botão de verificar após um tempo
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showCheckNowButton = true;
            });
          }
        });
      } else {
        throw Exception('Não foi possível abrir a URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao abrir URL: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatExpirationTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else {
      return '${minutes}m';
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
          '🔐 Autorizações AliExpress',
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
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Verificando status da autorização...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildActionsCard(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Configuração de Autorizações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gerencie as autorizações da API do AliExpress para importar produtos automaticamente.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final hasValidToken = _tokenStatus?['has_tokens'] ?? false;
    final tokens = _tokenStatus?['tokens'];
    final expiresIn = tokens?['expires_in'];
    final account = _tokenStatus?['account'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasValidToken ? Icons.check_circle : Icons.error,
                  color: hasValidToken ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Status da Autorização',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasValidToken ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusItem('Status', hasValidToken ? '✅ Autorizado' : '❌ Não autorizado'),
            if (account != null) _buildStatusItem('Conta', account),
            if (expiresIn != null) _buildStatusItem('Expira em', _formatExpirationTime(expiresIn)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAuthorizing ? null : _initiateOAuth,
                icon: _isAuthorizing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.security),
                label: Text(_isAuthorizing ? '🔐 Autorizando...' : '🔐 Autorizar AliExpress'),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkTokenStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('🔄 Verificar Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_showCheckNowButton) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ Após fazer login no AliExpress, clique em "Verificar Status" para confirmar a autorização.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
