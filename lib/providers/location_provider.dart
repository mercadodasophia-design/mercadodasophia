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
      Map<String, dynamic>? locationData = await _locationService.getFullLocation();
      
      if (locationData != null) {
        try {
          _currentLocation = UserLocation.fromPosition(locationData);
          notifyListeners();
        } catch (e) {
          print('Erro ao criar UserLocation: $e');
          _setError('Erro ao processar dados de localização');
        }
      } else {
        _setError('Não foi possível obter a localização atual');
      }
    } catch (e) {
      _setError('Erro ao obter localização: $e');
    } finally {
      _setLoading(false);
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
      // Prioridade: endereço salvo > localização atual
      if (_hasSavedAddress && _savedAddress != null) {
        return _formatSavedAddress();
      }
      
      if (_currentLocation == null || !hasLocation) return 'Localização não disponível';
      
      final location = _currentLocation!;
      if (location.address != null && location.address!.isNotEmpty) {
        return location.address!;
      }
      
      // Verificação adicional de segurança
      if (location.latitude == 0.0 && location.longitude == 0.0) {
        return 'Localização não disponível';
      }
      
      return location.coordinatesString;
    } catch (e) {
      print('Erro ao formatar endereço: $e');
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
