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

  // Obter localização atual
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  // Obter endereço a partir das coordenadas
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Construir endereço
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        
        return addressParts.join(', ');
      }
      
      return null;
    } catch (e) {
      print('Erro ao obter endereço: $e');
      return null;
    }
  }

  // Obter localização completa (posição + endereço)
  Future<Map<String, dynamic>?> getFullLocation() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) {
        return null;
      }

      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
      print('Erro ao obter localização completa: $e');
      return null;
    }
  }

  // Calcular distância entre duas coordenadas
  double calculateDistance(double startLatitude, double startLongitude, 
                          double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude, startLongitude, endLatitude, endLongitude,
    );
  }

  // Verificar se está dentro de uma área específica
  bool isWithinRadius(double centerLat, double centerLng, 
                     double userLat, double userLng, double radiusInMeters) {
    double distance = calculateDistance(centerLat, centerLng, userLat, userLng);
    return distance <= radiusInMeters;
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
