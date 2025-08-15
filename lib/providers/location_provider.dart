import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  UserLocation? _currentLocation;
  bool _isLoading = false;
  String? _error;
  bool _hasPermission = false;
  Map<String, dynamic>? _savedAddress;
  bool _hasSavedAddress = false;

  // Getters
  UserLocation? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermission => _hasPermission;
  bool get hasLocation => _currentLocation != null && _currentLocation!.isValid;
  bool get hasSavedAddress => _hasSavedAddress;
  Map<String, dynamic>? get savedAddress => _savedAddress;

  // Inicializar localização
  Future<void> initializeLocation() async {
    _setLoading(true);
    _clearError();

    try {
      // Primeiro, verificar se o usuário tem endereços salvos
      await _loadSavedAddress();
      
      // Se não tem endereço salvo, usar localização atual
      if (!_hasSavedAddress) {
        // Verificar permissões
        bool permissionGranted = await _locationService.requestLocationPermission();
        _hasPermission = permissionGranted;

        if (!permissionGranted) {
          _setError('Permissão de localização necessária para melhor experiência');
          _setLoading(false);
          return;
        }

        // Obter localização
        await getCurrentLocation();
      }
    } catch (e) {
      _setError('Erro ao inicializar localização: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carregar endereço salvo do usuário
  Future<void> _loadSavedAddress() async {
    try {
      // Por enquanto, vamos simular que não há endereço salvo
      // Em uma implementação real, você precisaria ter acesso ao AuthService
      // e buscar os dados do usuário no Firestore
      _hasSavedAddress = false;
      _savedAddress = null;
    } catch (e) {
      _hasSavedAddress = false;
      _savedAddress = null;
    }
  }

  // Método público para carregar endereço salvo com AuthService
  Future<void> loadSavedAddressWithAuth(AuthService authService) async {
    try {
      final user = authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userData = doc.data();
        if (userData != null && userData['selectedAddress'] != null) {
          _savedAddress = Map<String, dynamic>.from(userData['selectedAddress']);
          _hasSavedAddress = true;
          notifyListeners();
        } else {
          _hasSavedAddress = false;
          _savedAddress = null;
        }
      }
    } catch (e) {
      _hasSavedAddress = false;
      _savedAddress = null;
    }
  }

  // Obter localização atual
  Future<void> getCurrentLocation() async {
    _setLoading(true);
    _clearError();

    try {
      print('🎯 Iniciando obtenção de localização com alta precisão...');
      Map<String, dynamic>? locationData = await _locationService.getFullLocation();
      
      if (locationData != null) {
        try {
          print('📍 Dados de localização obtidos: $locationData');
          _currentLocation = UserLocation.fromPosition(locationData);
          
          // Validar se as coordenadas são razoáveis para o Brasil
          if (_currentLocation != null) {
            bool isValid = _locationService.isValidBrazilianCoordinates(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
            );
            
            if (!isValid) {
              print('⚠️ Coordenadas fora do Brasil detectadas');
              _setError('Localização parece estar fora do Brasil. Verifique o GPS.');
            } else {
              print('✅ Coordenadas válidas para o Brasil');
            }
            
            // Mostrar precisão da localização
            if (_currentLocation!.accuracy != null) {
              String accuracyDesc = _locationService.getAccuracyDescription(_currentLocation!.accuracy!);
              print('📍 Precisão da localização: $accuracyDesc');
            }
          }
          
          print('📍 Localização criada: ${_currentLocation!.address}');
          
          // SEMPRE tentar obter endereço, mesmo se já tiver um
          print('🔄 Forçando atualização do endereço...');
          await _updateAddressFromCoordinates();
          
          notifyListeners();
        } catch (e) {
          print('❌ Erro ao criar UserLocation: $e');
          _setError('Erro ao processar dados de localização');
        }
      } else {
        print('❌ Nenhum dado de localização obtido');
        _setError('Não foi possível obter a localização atual');
      }
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      _setError('Erro ao obter localização: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar endereço a partir das coordenadas
  Future<void> _updateAddressFromCoordinates() async {
    if (_currentLocation == null) return;
    
    print('🔄 Atualizando endereço para coordenadas: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    
    try {
      String? address = await _locationService.getAddressFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      
      print('📍 Endereço retornado: $address');
      
      if (address != null && address.isNotEmpty) {
        print('✅ Atualizando localização com novo endereço');
        _currentLocation = _currentLocation!.copyWith(address: address);
        notifyListeners();
      } else {
        print('⚠️ Endereço vazio ou nulo retornado');
      }
    } catch (e) {
      print('❌ Erro ao atualizar endereço: $e');
    }
  }

  // Obter localização aproximada (mais rápida)
  Future<void> getApproximateLocation() async {
    _setLoading(true);
    _clearError();

    try {
      var position = await _locationService.getApproximateLocation();
      
      if (position != null) {
        String? address;
        try {
          address = await _locationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
        } catch (e) {
          print('Erro ao obter endereço: $e');
          address = null;
        }

        _currentLocation = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
          address: address,
        );
        
        notifyListeners();
      } else {
        _setError('Não foi possível obter a localização aproximada');
      }
    } catch (e) {
      _setError('Erro ao obter localização aproximada: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar localização manualmente
  void updateLocation(UserLocation location) {
    _currentLocation = location;
    _clearError();
    notifyListeners();
  }

  // Limpar localização
  void clearLocation() {
    _currentLocation = null;
    _clearError();
    notifyListeners();
  }

  // Definir endereço salvo
  void setSavedAddress(Map<String, dynamic> address) {
    _savedAddress = address;
    _hasSavedAddress = true;
    notifyListeners();
  }

  // Limpar endereço salvo
  void clearSavedAddress() {
    _savedAddress = null;
    _hasSavedAddress = false;
    notifyListeners();
  }

  // Atualizar endereço salvo
  Future<void> updateSavedAddress() async {
    await _loadSavedAddress();
  }

  // Forçar atualização do endereço atual
  Future<void> refreshAddress() async {
    if (_currentLocation != null && hasLocation) {
      await _updateAddressFromCoordinates();
    }
  }

  // Calcular distância até um ponto
  double calculateDistanceTo(double latitude, double longitude) {
    if (!hasLocation || _currentLocation == null) return -1;
    
    try {
      final location = _currentLocation!;
      return _locationService.calculateDistance(
        location.latitude,
        location.longitude,
        latitude,
        longitude,
      );
    } catch (e) {
      print('Erro ao calcular distância: $e');
      return -1;
    }
  }

  // Verificar se está dentro de uma área
  bool isWithinRadius(double centerLat, double centerLng, double radiusInMeters) {
    if (!hasLocation || _currentLocation == null) return false;
    
    try {
      final location = _currentLocation!;
      return _locationService.isWithinRadius(
        centerLat,
        centerLng,
        location.latitude,
        location.longitude,
        radiusInMeters,
      );
    } catch (e) {
      print('Erro ao verificar raio: $e');
      return false;
    }
  }

  // Obter endereço formatado
  String getFormattedAddress() {
    try {
      print('📍 getFormattedAddress() chamado');
      print('  - hasSavedAddress: $_hasSavedAddress');
      print('  - currentLocation: ${_currentLocation != null}');
      print('  - hasLocation: $hasLocation');
      
      // Prioridade: endereço salvo > localização atual
      if (_hasSavedAddress && _savedAddress != null) {
        print('  - Usando endereço salvo');
        return _formatSavedAddress();
      }
      
      if (_currentLocation == null || !hasLocation) {
        print('  - Localização não disponível');
        return 'Localização não disponível';
      }
      
      final location = _currentLocation!;
      print('  - Endereço atual: ${location.address}');
      print('  - Coordenadas: ${location.latitude}, ${location.longitude}');
      
      // Mostrar informações de precisão se disponível
      if (location.accuracy != null) {
        String accuracyDesc = _locationService.getAccuracyDescription(location.accuracy!);
        print('  - Precisão: $accuracyDesc');
      }
      
      // Se temos um endereço válido, usar ele
      if (location.address != null && location.address!.isNotEmpty && 
          !location.address!.contains('Localização:')) {
        print('  - Retornando endereço válido: ${location.address}');
        return location.address!;
      }
      
      // Verificação adicional de segurança
      if (location.latitude == 0.0 && location.longitude == 0.0) {
        print('  - Coordenadas inválidas');
        return 'Localização não disponível';
      }
      
      // Se não temos endereço ou é apenas coordenadas, tentar obter endereço novamente
      if (location.address == null || location.address!.isEmpty || 
          location.address!.contains('Localização:')) {
        print('  - Endereço inválido, retornando coordenadas formatadas');
        // Retornar coordenadas formatadas de forma mais amigável com precisão
        String baseText = 'Localização: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        if (location.accuracy != null) {
          String accuracyDesc = _locationService.getAccuracyDescription(location.accuracy!);
          return '$baseText ($accuracyDesc)';
        }
        return baseText;
      }
      
      print('  - Retornando endereço final: ${location.address}');
      return location.address!;
    } catch (e) {
      print('❌ Erro ao formatar endereço: $e');
      return 'Localização não disponível';
    }
  }

  // Formatar endereço salvo
  String _formatSavedAddress() {
    if (_savedAddress == null) return 'Endereço não disponível';
    
    try {
      final address = _savedAddress!;
      final street = address['street'] ?? '';
      final number = address['number'] ?? '';
      final neighborhood = address['neighborhood'] ?? '';
      final city = address['city'] ?? '';
      final state = address['state'] ?? '';
      
      if (street.isNotEmpty && number.isNotEmpty) {
        return '$street, $number - $neighborhood, $city/$state';
      } else if (street.isNotEmpty) {
        return '$street - $neighborhood, $city/$state';
      } else {
        return '$city/$state';
      }
    } catch (e) {
      return 'Endereço não disponível';
    }
  }

  // Obter cidade atual
  String? getCurrentCity() {
    try {
      if (_currentLocation == null) return null;
      return _currentLocation!.city;
    } catch (e) {
      print('Erro ao obter cidade: $e');
      return null;
    }
  }

  // Obter estado atual
  String? getCurrentState() {
    try {
      if (_currentLocation == null) return null;
      return _currentLocation!.state;
    } catch (e) {
      print('Erro ao obter estado: $e');
      return null;
    }
  }

  // Verificar se está em uma cidade específica
  bool isInCity(String cityName) {
    if (!hasLocation || _currentLocation == null) return false;
    
    try {
      String? currentCity = getCurrentCity();
      if (currentCity == null || currentCity.isEmpty) return false;
      
      return currentCity.toLowerCase().contains(cityName.toLowerCase());
    } catch (e) {
      print('Erro ao verificar cidade: $e');
      return false;
    }
  }

  // Verificar se está em um estado específico
  bool isInState(String stateName) {
    if (!hasLocation || _currentLocation == null) return false;
    
    try {
      String? currentState = getCurrentState();
      if (currentState == null || currentState.isEmpty) return false;
      
      return currentState.toLowerCase().contains(stateName.toLowerCase());
    } catch (e) {
      print('Erro ao verificar estado: $e');
      return false;
    }
  }

  // Métodos privados para gerenciar estado
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
  }

  // Disposer
  @override
  void dispose() {
    super.dispose();
  }
}
