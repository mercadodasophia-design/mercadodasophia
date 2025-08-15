import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Verificar e solicitar permissões de localização
  Future<bool> requestLocationPermission() async {
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviços de localização estão desabilitados');
      }

      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      return true;
    } catch (e) {
      print('Erro ao solicitar permissão de localização: $e');
      return false;
    }
  }

  // Obter localização atual com alta precisão
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      print('📍 Obtendo localização com alta precisão...');
      
      // Primeira tentativa com alta precisão
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('📍 Localização obtida: ${position.latitude}, ${position.longitude}');
      print('📍 Precisão: ${position.accuracy} metros');

      return position;
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  // Obter localização com múltiplas tentativas para melhor precisão
  Future<Position?> getHighAccuracyLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      print('🎯 Obtendo localização com múltiplas tentativas...');
      
      List<Position> positions = [];
      
      // Fazer 3 tentativas para obter a melhor precisão
      for (int i = 0; i < 3; i++) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          
          positions.add(position);
          print('📍 Tentativa ${i + 1}: ${position.latitude}, ${position.longitude} (precisão: ${position.accuracy}m)');
          
          // Se a precisão for muito boa, usar imediatamente
          if (position.accuracy <= 10) {
            print('✅ Precisão excelente encontrada!');
            return position;
          }
          
          // Pequena pausa entre tentativas
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('⚠️ Tentativa ${i + 1} falhou: $e');
        }
      }
      
      if (positions.isEmpty) {
        print('❌ Nenhuma posição obtida');
        return null;
      }
      
      // Usar a posição com melhor precisão
      Position bestPosition = positions.reduce((a, b) => a.accuracy < b.accuracy ? a : b);
      print('✅ Melhor posição selecionada: ${bestPosition.latitude}, ${bestPosition.longitude} (precisão: ${bestPosition.accuracy}m)');
      
      return bestPosition;
    } catch (e) {
      print('❌ Erro ao obter localização de alta precisão: $e');
      return null;
    }
  }

  // Obter endereço a partir das coordenadas
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      print('🔍 Tentando obter endereço para: $latitude, $longitude');
      
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      print('📍 Placemarks encontrados: ${placemarks.length}');
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        print('📍 Dados do placemark:');
        print('  - Street: ${place.street}');
        print('  - SubThoroughfare: ${place.subThoroughfare}');
        print('  - SubLocality: ${place.subLocality}');
        print('  - Locality: ${place.locality}');
        print('  - AdministrativeArea: ${place.administrativeArea}');
        print('  - PostalCode: ${place.postalCode}');
        
        // Construir endereço com prioridade para informações mais específicas
        List<String> addressParts = [];
        
        // Rua e número (mais específico)
        if (place.street != null && place.street!.isNotEmpty) {
          String street = place.street!;
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            street = '${place.subThoroughfare}, $street';
          }
          addressParts.add(street);
        }
        
        // Bairro
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        // Cidade
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        // Estado
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        // CEP
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add('CEP: ${place.postalCode}');
        }
        
        print('📍 Partes do endereço: $addressParts');
        
        // Se temos pelo menos cidade e estado, retornar
        if (addressParts.isNotEmpty) {
          final result = addressParts.join(', ');
          print('✅ Endereço obtido: $result');
          return result;
        }
      }
      
      print('⚠️ Nenhum placemark encontrado ou dados insuficientes');
      // Fallback: retornar coordenadas formatadas de forma mais amigável
      return 'Localização: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('❌ Erro ao obter endereço: $e');
      // Fallback em caso de erro
      return 'Localização: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  // Obter localização completa (posição + endereço) com alta precisão
  Future<Map<String, dynamic>?> getFullLocation() async {
    try {
      print('🎯 Obtendo localização completa com alta precisão...');
      
      Position? position = await getHighAccuracyLocation();
      if (position == null) {
        print('❌ Não foi possível obter posição');
        return null;
      }

      print('📍 Posição obtida: ${position.latitude}, ${position.longitude}');
      print('📍 Precisão: ${position.accuracy} metros');

      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print('📍 Endereço obtido: $address');

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp?.toIso8601String(),
        'address': address,
      };
    } catch (e) {
      print('❌ Erro ao obter localização completa: $e');
      return null;
    }
  }

  // Calcular distância entre duas coordenadas usando fórmula de Haversine
  double calculateDistance(double startLatitude, double startLongitude, 
                          double endLatitude, double endLongitude) {
    try {
      // Converter graus para radianos
      const double earthRadius = 6371000; // Raio da Terra em metros
      
      double lat1Rad = _degreesToRadians(startLatitude);
      double lat2Rad = _degreesToRadians(endLatitude);
      double deltaLatRad = _degreesToRadians(endLatitude - startLatitude);
      double deltaLonRad = _degreesToRadians(endLongitude - startLongitude);
      
      // Fórmula de Haversine
      double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                 cos(lat1Rad) * cos(lat2Rad) *
                 sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
      
      double c = 2 * asin(sqrt(a));
      double distance = earthRadius * c;
      
      print('📍 Distância calculada: ${distance.toStringAsFixed(2)} metros');
      return distance;
    } catch (e) {
      print('❌ Erro ao calcular distância: $e');
      // Fallback para o método do Geolocator
      return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude,
      );
    }
  }

  // Converter graus para radianos
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Verificar se está dentro de uma área específica
  bool isWithinRadius(double centerLat, double centerLng, 
                     double userLat, double userLng, double radiusInMeters) {
    double distance = calculateDistance(centerLat, centerLng, userLat, userLng);
    print('📍 Distância até o centro: ${distance.toStringAsFixed(2)} metros');
    return distance <= radiusInMeters;
  }

  // Validar se as coordenadas são razoáveis (dentro do Brasil)
  bool isValidBrazilianCoordinates(double latitude, double longitude) {
    // Brasil: aproximadamente entre -33° e 5° de latitude, -74° e -34° de longitude
    bool validLat = latitude >= -33.0 && latitude <= 5.0;
    bool validLng = longitude >= -74.0 && longitude <= -34.0;
    
    print('📍 Validação de coordenadas brasileiras:');
    print('  - Latitude: $latitude (válida: $validLat)');
    print('  - Longitude: $longitude (válida: $validLng)');
    
    return validLat && validLng;
  }

  // Calcular precisão estimada baseada na acurácia do GPS
  String getAccuracyDescription(double accuracyInMeters) {
    if (accuracyInMeters <= 5) {
      return 'Excelente (≤5m)';
    } else if (accuracyInMeters <= 10) {
      return 'Muito boa (≤10m)';
    } else if (accuracyInMeters <= 20) {
      return 'Boa (≤20m)';
    } else if (accuracyInMeters <= 50) {
      return 'Aceitável (≤50m)';
    } else {
      return 'Baixa (>50m)';
    }
  }

  // Obter localização aproximada (menos precisa, mais rápida)
  Future<Position?> getApproximateLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      return position;
    } catch (e) {
      print('Erro ao obter localização aproximada: $e');
      return null;
    }
  }

  // Monitorar mudanças de localização
  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualizar a cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
