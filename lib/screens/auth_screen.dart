import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Logo e título
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 60,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Mercado da Sophia',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Produtos selecionados com carinho',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Card de autenticação
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Título do card
                      Text(
                        _isLogin ? 'Entrar' : 'Cadastrar',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                                              // Botão Google
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.g_mobiledata, size: 24),
                            label: Text(_isLoading ? 'Entrando...' : 'Entrar com Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Divisor
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ou',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Formulário
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Campo de email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Digite seu email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                hintStyle: TextStyle(color: AppTheme.textLightColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu email';
                                }
                                if (!value.contains('@')) {
                                  return 'Por favor, digite um email válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo de senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: 'Digite sua senha',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                hintStyle: TextStyle(color: AppTheme.textLightColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite sua senha';
                                }
                                if (value.length < 6) {
                                  return 'A senha deve ter pelo menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Botão de ação principal
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleEmailSignIn,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Entrar' : 'Cadastrar',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Link para alternar entre login/cadastro
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin 
                                  ? 'Não tem uma conta? Cadastre-se'
                                  : 'Já tem uma conta? Entrar',
                                style: TextStyle(color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Termos de uso
                Text(
                  'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login com Google realizado com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pushReplacementNamed(context, '/products');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro no login com Google'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleEmailSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        bool success;
        if (_isLogin) {
          success = await _authService.signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );
        } else {
          success = await _authService.signUpWithEmail(
            _emailController.text,
            _passwordController.text,
          );
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? 'Login realizado com sucesso!' : 'Cadastro realizado com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pushReplacementNamed(context, '/products');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? 'Email ou senha incorretos' : 'Erro no cadastro'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
} 