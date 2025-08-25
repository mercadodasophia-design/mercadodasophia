import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/google_signin_validator.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    // Verificar se o usuário já está logado
    if (_authService.isAuthenticated) {
      // Se já estiver logado, redirecionar para produtos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/produtos');
        }
      });
    }
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
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/system/logo/da Sophia.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shopping_bag,
                          size: 60,
                          color: AppTheme.primaryColor,
                        );
                      },
                    ),
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
                  'Faça login para uma experiência personalizada',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Botão para continuar sem login
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          context.go('/produtos');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Continuar sem login',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
                        _isLogin ? 'Entrar na Loja' : 'Criar Conta',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin 
                          ? 'Acesse sua conta para ver pedidos e favoritos'
                          : 'Crie sua conta para facilitar suas compras',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
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
                            // Campo de nome (apenas no cadastro)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                style: const TextStyle(color: AppTheme.textPrimaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Nome Completo',
                                  hintText: 'Digite seu nome completo',
                                  prefixIcon: const Icon(Icons.person_outlined, color: AppTheme.textSecondaryColor),
                                  labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                                  hintStyle: const TextStyle(color: AppTheme.textLightColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, digite seu nome';
                                  }
                                  if (value.length < 2) {
                                    return 'O nome deve ter pelo menos 2 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Campo de telefone (apenas no cadastro)
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: AppTheme.textPrimaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Telefone (Opcional)',
                                  hintText: '(85) 99764-0050',
                                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textSecondaryColor),
                                  labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                                  hintStyle: const TextStyle(color: AppTheme.textLightColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  // Telefone é opcional, então não precisa de validação obrigatória
                                  if (value != null && value.isNotEmpty) {
                                    // Validação básica de telefone brasileiro
                                    final phoneRegex = RegExp(r'^\(?[1-9]{2}\)? ?(?:[2-8]|9[1-9])[0-9]{3}\-?[0-9]{4}$');
                                    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
                                      return 'Digite um telefone válido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Campo de email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: AppTheme.textPrimaryColor),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Digite seu email',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondaryColor),
                                labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                                hintStyle: const TextStyle(color: AppTheme.textLightColor),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
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
                              style: const TextStyle(color: AppTheme.textPrimaryColor),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: 'Digite sua senha',
                                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.textSecondaryColor),
                                labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                                hintStyle: const TextStyle(color: AppTheme.textLightColor),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                    color: AppTheme.textSecondaryColor,
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
                                if (!_isLogin && value.length < 8) {
                                  return 'A senha deve ter pelo menos 8 caracteres';
                                }
                                if (!_isLogin && !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                                  return 'A senha deve conter letra maiúscula, minúscula e número';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Indicador de força da senha (apenas no cadastro)
                            if (!_isLogin) ...[
                              _buildPasswordStrengthIndicator(),
                              const SizedBox(height: 16),
                            ],
                            
                            // Campo de confirmação de senha (apenas no cadastro)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(color: AppTheme.textPrimaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Senha',
                                  hintText: 'Confirme sua senha',
                                  prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.textSecondaryColor),
                                  labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                                  hintStyle: const TextStyle(color: AppTheme.textLightColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword 
                                        ? Icons.visibility_off 
                                        : Icons.visibility,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, confirme sua senha';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'As senhas não coincidem';
                                  }
                                  return null;
                                },
                              ),
                            ],
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
                                      _isLogin ? 'Entrar na Loja' : 'Criar Conta',
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
                                  // Limpar campos ao alternar
                                  _nameController.clear();
                                  _emailController.clear();
                                  _phoneController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                });
                              },
                              child: Text(
                                _isLogin 
                                  ? 'Não tem uma conta? Cadastre-se'
                                  : 'Já tem uma conta? Entrar',
                                style: const TextStyle(color: AppTheme.primaryColor),
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
                const SizedBox(height: 16),
                
                // Botão de diagnóstico (apenas em debug)
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  TextButton(
                    onPressed: _isLoading ? null : _showDiagnosticReport,
                    child: const Text(
                      '🔧 Diagnóstico Google Sign-In',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
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
      final credential = await _authService.signInWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login com Google realizado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/produtos');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login com Google: $e'),
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

  void _showDiagnosticReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await GoogleSignInValidator.generateValidationReport();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔧 Diagnóstico Google Sign-In'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Status: ${report['overallStatus']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: report['overallStatus'] == 'VALID' ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (report['configuration']['success'].isNotEmpty) ...[
                    const Text('✅ Sucessos:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...report['configuration']['success'].map((msg) => Text('• $msg')),
                    const SizedBox(height: 8),
                  ],
                  
                  if (report['configuration']['warnings'].isNotEmpty) ...[
                    const Text('⚠️ Avisos:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...report['configuration']['warnings'].map((msg) => Text('• $msg')),
                    const SizedBox(height: 8),
                  ],
                  
                  if (report['configuration']['errors'].isNotEmpty) ...[
                    const Text('❌ Erros:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...report['configuration']['errors'].map((msg) => Text('• $msg')),
                    const SizedBox(height: 8),
                  ],
                  
                  if (report['recommendations'].isNotEmpty) ...[
                    const Text('💡 Recomendações:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...report['recommendations'].map((msg) => Text('• $msg')),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar diagnóstico: $e'),
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
        if (_isLogin) {
          // Login
          await _authService.signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );
        } else {
          // Cadastro
          await _authService.signUpWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? 'Login realizado com sucesso!' : 'Conta criada com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.go('/produtos');
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

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int score = 0;
    String message = '';
    Color color = Colors.grey;

    // Verificar comprimento
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Verificar complexidade
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Definir mensagem e cor baseada no score
    if (score <= 2) {
      message = 'Fraca';
      color = Colors.red;
    } else if (score <= 4) {
      message = 'Média';
      color = Colors.orange;
    } else if (score <= 6) {
      message = 'Forte';
      color = Colors.green;
    } else {
      message = 'Muito forte';
      color = Colors.green.shade700;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Força da senha: $message',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 7,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}



