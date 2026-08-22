class Connector {
  final String id;
  final String standard;
  final String powerType;
  final double maxPowerKw;
  final String status;

  const Connector({required this.id, required this.standard, required this.powerType, required this.maxPowerKw, required this.status});
  factory Connector.fromJson(Map<String, dynamic> json) => Connector(
    id: json['id']?.toString() ?? '', standard: json['standard']?.toString() ?? 'Unknown',
    powerType: json['powerType']?.toString() ?? '', maxPowerKw: double.tryParse(json['maxPowerKw'].toString()) ?? 0,
    status: json['status']?.toString() ?? 'UNKNOWN',
  );
}

class Station {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String city;
  final String operatorName;
  final bool isMock;
  final double rating;
  final int reliabilityScore;
  final int availableConnectors;
  final List<Connector> connectors;
  final Map<String, dynamic>? raw;

  const Station({required this.id, required this.name, required this.lat, required this.lng, required this.address, required this.city, required this.operatorName, required this.isMock, required this.rating, required this.reliabilityScore, required this.availableConnectors, required this.connectors, this.raw});
  factory Station.fromJson(Map<String, dynamic> json) {
    final operator = json['operator'] is Map ? Map<String, dynamic>.from(json['operator']) : <String, dynamic>{};
    final reliability = json['reliability'] is Map ? Map<String, dynamic>.from(json['reliability']) : <String, dynamic>{};
    final connectorData = json['connectors'] is List ? json['connectors'] as List : const [];
    return Station(
      id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '',
      lat: double.tryParse(json['latitude'].toString()) ?? 0, lng: double.tryParse(json['longitude'].toString()) ?? 0,
      address: json['address']?.toString() ?? '', city: json['city']?.toString() ?? '', operatorName: operator['name']?.toString() ?? 'Unknown operator',
      isMock: operator['isMock'] == true, rating: double.tryParse(json['rating'].toString()) ?? 0,
      reliabilityScore: int.tryParse(reliability['score'].toString()) ?? 0, availableConnectors: int.tryParse(json['availableConnectors'].toString()) ?? 0,
      connectors: connectorData.whereType<Map>().map((item) => Connector.fromJson(Map<String, dynamic>.from(item))).toList(), raw: json,
    );
  }
}
