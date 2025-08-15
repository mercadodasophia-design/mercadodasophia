class UserLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime? timestamp;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.timestamp,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  // Criar a partir de um Map
  factory UserLocation.fromMap(Map<String, dynamic> map) {
    try {
      return UserLocation(
        latitude: _parseDouble(map['latitude']) ?? 0.0,
        longitude: _parseDouble(map['longitude']) ?? 0.0,
        accuracy: _parseDouble(map['accuracy']),
        altitude: _parseDouble(map['altitude']),
        speed: _parseDouble(map['speed']),
        heading: _parseDouble(map['heading']),
        timestamp: map['timestamp'] != null 
            ? DateTime.parse(map['timestamp'].toString()) 
            : null,
        address: map['address']?.toString(),
        city: map['city']?.toString(),
        state: map['state']?.toString(),
        country: map['country']?.toString(),
        postalCode: map['postalCode']?.toString(),
      );
    } catch (e) {
      print('Erro ao criar UserLocation.fromMap: $e');
      // Retornar uma localização padrão em caso de erro
      return UserLocation(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Localização não disponível',
      );
    }
  }

  // Converter para Map
  Map<String, dynamic> toMap() {
    try {
      return {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': timestamp?.toIso8601String(),
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
      };
    } catch (e) {
      print('Erro ao converter UserLocation para Map: $e');
      return {
        'latitude': latitude,
        'longitude': longitude,
        'address': address ?? 'Localização não disponível',
      };
    }
  }

  // Criar a partir de dados do Geolocator
  factory UserLocation.fromPosition(Map<String, dynamic> positionData) {
    try {
      return UserLocation(
        latitude: _parseDouble(positionData['latitude']) ?? 0.0,
        longitude: _parseDouble(positionData['longitude']) ?? 0.0,
        accuracy: _parseDouble(positionData['accuracy']),
        altitude: _parseDouble(positionData['altitude']),
        speed: _parseDouble(positionData['speed']),
        heading: _parseDouble(positionData['heading']),
        timestamp: positionData['timestamp'] != null 
            ? DateTime.parse(positionData['timestamp'].toString()) 
            : null,
        address: positionData['address']?.toString(),
      );
    } catch (e) {
      print('Erro ao criar UserLocation.fromPosition: $e');
      // Retornar uma localização padrão em caso de erro
      return UserLocation(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Localização não disponível',
      );
    }
  }

  // Copiar com modificações
  UserLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) {
    try {
      return UserLocation(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracy: accuracy ?? this.accuracy,
        altitude: altitude ?? this.altitude,
        speed: speed ?? this.speed,
        heading: heading ?? this.heading,
        timestamp: timestamp ?? this.timestamp,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        country: country ?? this.country,
        postalCode: postalCode ?? this.postalCode,
      );
    } catch (e) {
      print('Erro ao copiar UserLocation: $e');
      return UserLocation(
        latitude: this.latitude,
        longitude: this.longitude,
        address: this.address ?? 'Localização não disponível',
      );
    }
  }

  // Verificar se a localização é válida
  bool get isValid {
    try {
      return latitude != 0.0 && longitude != 0.0;
    } catch (e) {
      print('Erro ao verificar validade da localização: $e');
      return false;
    }
  }

  // Obter coordenadas como string
  String get coordinatesString {
    try {
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      print('Erro ao formatar coordenadas: $e');
      return '0.000000, 0.000000';
    }
  }

  // Obter endereço formatado
  String get formattedAddress {
    try {
      List<String> parts = [];
      
      if (address != null && address!.isNotEmpty) {
        parts.add(address!);
      }
      
      if (city != null && city!.isNotEmpty) {
        parts.add(city!);
      }
      
      if (state != null && state!.isNotEmpty) {
        parts.add(state!);
      }
      
      if (postalCode != null && postalCode!.isNotEmpty) {
        parts.add(postalCode!);
      }
      
      return parts.join(', ');
    } catch (e) {
      print('Erro ao formatar endereço: $e');
      return 'Localização não disponível';
    }
  }

  @override
  String toString() {
    try {
      return 'UserLocation(latitude: $latitude, longitude: $longitude, address: $address)';
    } catch (e) {
      return 'UserLocation(erro: $e)';
    }
  }

  @override
  bool operator ==(Object other) {
    try {
      if (identical(this, other)) return true;
      return other is UserLocation &&
          other.latitude == latitude &&
          other.longitude == longitude;
    } catch (e) {
      return false;
    }
  }

  @override
  int get hashCode {
    try {
      return latitude.hashCode ^ longitude.hashCode;
    } catch (e) {
      return 0;
    }
  }

  // Método auxiliar para parsing seguro de double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanValue = value.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      if (cleanValue.isEmpty) return null;
      return double.tryParse(cleanValue);
    }
    return null;
  }
}
