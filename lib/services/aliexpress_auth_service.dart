import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AliExpressAuthService extends ChangeNotifier {
  static const String _baseUrl = 'https://service-api-aliexpress.mercadodasophia.com.br';
  
  bool _isAuthorized = false;
  bool _isLoading = false;
  Map<String, dynamic>? _tokenStatus;
  String? _error;

  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get tokenStatus => _tokenStatus;
  String? get error => _error;

  /// Verifica o status da autorização AliExpress
  Future<bool> checkAuthorizationStatus({bool silent = false}) async {
    print('🔍 AliExpressAuthService: Iniciando verificação de autorização (silent: $silent)');
    
    if (!silent) {
      _setLoading(true);
      _clearError();
    }

    try {
      print('🌐 Fazendo requisição para: $_baseUrl/api/aliexpress/tokens/status');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/aliexpress/tokens/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Status code: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _tokenStatus = data;
        
        // Verificar se tem token válido
        final hasTokens = data['has_tokens'] ?? false;
        final tokens = data['tokens'] ?? {};
        final hasAccessToken = tokens['has_access_token'] ?? false;
        final hasRefreshToken = tokens['has_refresh_token'] ?? false;
        
        _isAuthorized = hasTokens && hasAccessToken;
        
        print('🔍 Verificação de tokens:');
        print('  - hasTokens: $hasTokens');
        print('  - hasAccessToken: $hasAccessToken');
        print('  - hasRefreshToken: $hasRefreshToken');
        print('  - isAuthorized: $_isAuthorized');
        
        if (!silent) {
          _setLoading(false);
        }
        return _isAuthorized;
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro na verificação: $e');
      if (!silent) {
        _setError('Erro ao verificar autorização: $e');
        _setLoading(false);
      }
      return false;
    }
  }

  /// Inicia o processo de autorização OAuth
  Future<String?> initiateOAuth() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/aliexpress/auth'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authUrl = data['auth_url'];
        
        if (authUrl != null && authUrl.isNotEmpty) {
          _setLoading(false);
          return authUrl;
        } else {
          throw Exception('URL de autorização não encontrada na resposta');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erro ${response.statusCode}: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      _setError('Erro ao iniciar autorização: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Tenta fazer refresh do token
  Future<bool> refreshToken() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/aliexpress/token/refresh'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Atualizar status após refresh
          await checkAuthorizationStatus();
          _setLoading(false);
          return true;
        } else {
          throw Exception(data['message'] ?? 'Erro desconhecido no refresh');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erro ${response.statusCode}: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      _setError('Erro ao fazer refresh do token: $e');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isAuthorized = false;
    _isLoading = false;
    _tokenStatus = null;
    _error = null;
    notifyListeners();
  }
}
