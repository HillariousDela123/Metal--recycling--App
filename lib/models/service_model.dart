/// Represents a verified metal recycling center or scrap drop-off facility.
class ServiceModel {
  final String serviceId;
  final String name;
  final double lat;
  final double lng;
  final List<String> acceptedMetals;
  final String address;
  final String phone;
  final String operatingHours;
  final double rating;
  final Map<String, double> pricePerKg; // Metal category -> price in $/kg
  final bool isVerified;

  const ServiceModel({
    required this.serviceId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.acceptedMetals,
    this.address = '',
    this.phone = '',
    this.operatingHours = 'Mon - Sat: 8:00 AM - 5:00 PM',
    this.rating = 4.8,
    this.pricePerKg = const {},
    this.isVerified = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'acceptedMetals': acceptedMetals,
      'address': address,
      'phone': phone,
      'operatingHours': operatingHours,
      'rating': rating,
      'pricePerKg': pricePerKg,
      'isVerified': isVerified,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final metalsRaw = map['acceptedMetals'];
    List<String> metalsList = [];
    if (metalsRaw is List) {
      metalsList = metalsRaw.map((e) => e.toString()).toList();
    }

    final rawPrices = map['pricePerKg'];
    Map<String, double> pricesMap = {};
    if (rawPrices is Map) {
      rawPrices.forEach((key, value) {
        if (value is num) {
          pricesMap[key.toString()] = value.toDouble();
        }
      });
    }

    return ServiceModel(
      serviceId: documentId ?? map['serviceId'] ?? '',
      name: map['name'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      acceptedMetals: metalsList,
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      operatingHours: map['operatingHours'] ?? 'Mon - Sat: 8:00 AM - 5:00 PM',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      pricePerKg: pricesMap,
      isVerified: map['isVerified'] ?? true,
    );
  }

  ServiceModel copyWith({
    String? serviceId,
    String? name,
    double? lat,
    double? lng,
    List<String>? acceptedMetals,
    String? address,
    String? phone,
    String? operatingHours,
    double? rating,
    Map<String, double>? pricePerKg,
    bool? isVerified,
  }) {
    return ServiceModel(
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      acceptedMetals: acceptedMetals ?? this.acceptedMetals,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      operatingHours: operatingHours ?? this.operatingHours,
      rating: rating ?? this.rating,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
