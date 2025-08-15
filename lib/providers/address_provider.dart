import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressProvider with ChangeNotifier {
  String? _cep;
  String? _street;
  String? _neighborhood;
  String? _city;
  String? _state;
  String? _fullAddress;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get cep => _cep;
  String? get street => _street;
  String? get neighborhood => _neighborhood;
  String? get city => _city;
  String? get state => _state;
  String? get fullAddress => _fullAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAddress => _cep != null && _street != null;

  // Buscar endereço por CEP
  Future<bool> searchAddressByCep(String cep) async {
    setState(true);
    _clearError();

    try {
      // Limpar CEP (remover caracteres especiais)
      final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanCep.length != 8) {
        _setError('CEP deve ter 8 dígitos');
        setState(false);
        return false;
      }

      // Buscar endereço via API ViaCEP
      final url = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['erro'] == true) {
          _setError('CEP não encontrado');
          setState(false);
          return false;
        }

        // Atualizar endereço
        _cep = cleanCep;
        _street = data['logradouro'] ?? '';
        _neighborhood = data['bairro'] ?? '';
        _city = data['localidade'] ?? '';
        _state = data['uf'] ?? '';
        _fullAddress = _buildFullAddress();

        setState(false);
        notifyListeners();
        return true;
      } else {
        _setError('Erro ao buscar CEP');
        setState(false);
        return false;
      }
    } catch (e) {
      _setError('Erro ao buscar endereço: $e');
      setState(false);
      return false;
    }
  }

  // Definir endereço manualmente
  void setAddress({
    required String cep,
    required String street,
    required String neighborhood,
    required String city,
    required String state,
  }) {
    _cep = cep;
    _street = street;
    _neighborhood = neighborhood;
    _city = city;
    _state = state;
    _fullAddress = _buildFullAddress();
    _clearError();
    notifyListeners();
  }

  // Limpar endereço
  void clearAddress() {
    _cep = null;
    _street = null;
    _neighborhood = null;
    _city = null;
    _state = null;
    _fullAddress = null;
    _clearError();
    notifyListeners();
  }

  // Construir endereço completo
  String _buildFullAddress() {
    final parts = <String>[];
    
    if (_street?.isNotEmpty == true) parts.add(_street!);
    if (_neighborhood?.isNotEmpty == true) parts.add(_neighborhood!);
    if (_city?.isNotEmpty == true) parts.add(_city!);
    if (_state?.isNotEmpty == true) parts.add(_state!);
    if (_cep?.isNotEmpty == true) parts.add('CEP: $_cep');
    
    return parts.join(', ');
  }

  // Formatar CEP com máscara
  String formatCep(String cep) {
    final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCep.length <= 5) {
      return cleanCep;
    } else {
      return '${cleanCep.substring(0, 5)}-${cleanCep.substring(5)}';
    }
  }

  // Validar CEP
  bool isValidCep(String cep) {
    final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
    return cleanCep.length == 8;
  }

  // Métodos auxiliares
  void setState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Converter para Map (útil para salvar no Firebase)
  Map<String, dynamic> toMap() {
    return {
      'cep': _cep,
      'street': _street,
      'neighborhood': _neighborhood,
      'city': _city,
      'state': _state,
      'fullAddress': _fullAddress,
    };
  }

  // Carregar de Map (útil para carregar do Firebase)
  void fromMap(Map<String, dynamic> map) {
    _cep = map['cep'];
    _street = map['street'];
    _neighborhood = map['neighborhood'];
    _city = map['city'];
    _state = map['state'];
    _fullAddress = map['fullAddress'] ?? _buildFullAddress();
    notifyListeners();
  }
}

