class Station {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int waitTimeMin;
  final Map<String, dynamic>? tariff;
  final double rating;
  final String status;
  final Map<String, dynamic>? raw;

  Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.waitTimeMin = 0,
    this.tariff,
    this.rating = 0,
    this.status = 'unknown',
    this.raw,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        id: json['id'] ?? json['ID'] ?? '',
        name: json['name'] ?? '',
        lat: double.parse(json['lat']?.toString() ?? '0'),
        lng: double.parse(json['lng']?.toString() ?? '0'),
        waitTimeMin: (json['waitTimeMin'] is int)
            ? json['waitTimeMin']
            : int.tryParse((json['waitTimeMin'] ?? '0').toString()) ?? 0,
        tariff: json['tariff'] is Map
            ? Map<String, dynamic>.from(json['tariff'])
            : null,
        rating: (json['rating'] != null)
            ? double.tryParse(json['rating'].toString()) ?? 0.0
            : 0.0,
        status: json['status'] ?? 'unknown',
        raw: json,
      );

  Map<String, dynamic> toJson() =>
      raw ?? {'id': id, 'name': name, 'lat': lat, 'lng': lng};
}
