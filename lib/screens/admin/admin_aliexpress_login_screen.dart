import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/aliexpress_auth_service.dart';
import '../../theme/app_theme.dart';

class AdminAliExpressLoginScreen extends StatefulWidget {
  const AdminAliExpressLoginScreen({super.key});

  @override
  State<AdminAliExpressLoginScreen> createState() => _AdminAliExpressLoginScreenState();
}

class _AdminAliExpressLoginScreenState extends State<AdminAliExpressLoginScreen> {
  bool _showCheckButton = false;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar chamar setState durante o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthorizationOnStart();
    });
  }

  Future<void> _checkAuthorizationOnStart() async {
    final authService = Provider.of<AliExpressAuthService>(context, listen: false);
    final isAuthorized = await authService.checkAuthorizationStatus(silent: true);
    
    if (isAuthorized && mounted) {
      _navigateToDashboard();
    }
  }

  Future<void> _initiateOAuth() async {
    final authService = Provider.of<AliExpressAuthService>(context, listen: false);
    
    final authUrl = await authService.initiateOAuth();
    
    if (authUrl != null && mounted) {
      // Tentar abrir URL de autorização
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌐 URL de autorização aberta no navegador. Após fazer login, volte aqui e clique em "Verificar Autorização".'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Mostrar botão de verificar após um tempo
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showCheckButton = true;
            });
          }
        });
      } else {
        _showUrlDialog(authUrl);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: ${authService.error}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _checkAuthorization() async {
    final authService = Provider.of<AliExpressAuthService>(context, listen: false);
    final isAuthorized = await authService.checkAuthorizationStatus();
    
    if (isAuthorized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Autorização confirmada! Redirecionando...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Aguardar um pouco para mostrar a mensagem
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToDashboard();
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${authService.error ?? 'Autorização ainda não confirmada. Tente novamente.'}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshToken() async {
    final authService = Provider.of<AliExpressAuthService>(context, listen: false);
    final success = await authService.refreshToken();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Token atualizado! Redirecionando...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToDashboard();
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao atualizar token: ${authService.error}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed('/admin_dashboard');
  }

  void _showUrlDialog(String authUrl) {
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
              const Text('Copie e cole esta URL no seu navegador para fazer a autorização.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo/Ícone
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Título
                      const Text(
                        'Mercado da Sophia',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Painel Administrativo',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Status da autorização
                      Consumer<AliExpressAuthService>(
                        builder: (context, authService, child) {
                          if (authService.isLoading) {
                            return const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Verificando autorização...'),
                              ],
                            );
                          }
                          
                          return Column(
                            children: [
                              // Status atual
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: authService.isAuthorized 
                                    ? Colors.green.shade50 
                                    : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: authService.isAuthorized 
                                      ? Colors.green.shade200 
                                      : Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      authService.isAuthorized 
                                        ? Icons.check_circle 
                                        : Icons.warning,
                                      color: authService.isAuthorized 
                                        ? Colors.green 
                                        : Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        authService.isAuthorized
                                          ? 'Autorização AliExpress ativa'
                                          : 'Autorização AliExpress necessária',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: authService.isAuthorized 
                                            ? Colors.green.shade700 
                                            : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Botões de ação
                              if (!authService.isAuthorized) ...[
                                ElevatedButton.icon(
                                  onPressed: _initiateOAuth,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Fazer Login AliExpress'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                if (_showCheckButton)
                                  OutlinedButton.icon(
                                    onPressed: _checkAuthorization,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Verificar Autorização'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: _navigateToDashboard,
                                  icon: const Icon(Icons.dashboard),
                                  label: const Text('Entrar no Painel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                TextButton.icon(
                                  onPressed: _refreshToken,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Atualizar Token'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                              
                              // Mensagem de erro
                              if (authService.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authService.error!,
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
