/// Station, Connector, Tariff and Reliability models for Discovery & Details
class StationModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String? pincode;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final OperatorInfo? operator;
  final double rating;
  final ReliabilityInfo? reliability;
  final List<ConnectorModel> connectors;
  final int availableConnectors;
  final List<String> amenities;

  StationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    this.pincode,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.operator,
    this.rating = 4.8,
    this.reliability,
    this.connectors = const [],
    this.availableConnectors = 0,
    this.amenities = const ['Cafe', 'Restroom', 'WiFi', '24/7 Security'],
  });

  bool get isFastDc => connectors.any((c) => c.isDc && c.maxPowerKw >= 50);
  int get maxPowerKw => connectors.fold(0, (max, c) => c.maxPowerKw > max ? c.maxPowerKw.toInt() : max);
  double get baseTariffPerKwh => connectors.isNotEmpty ? (connectors.first.tariff?.pricePerKwh ?? 14.5) : 14.5;
  double get connectionFlatFee => connectors.isNotEmpty ? (connectors.first.tariff?.flatFee ?? 20.0) : 20.0;

  factory StationModel.fromJson(Map<String, dynamic> json) {
    var rawConnectors = json['connectors'] as List<dynamic>? ?? [];
    List<ConnectorModel> conns = rawConnectors.map((c) => ConnectorModel.fromJson(c as Map<String, dynamic>)).toList();

    return StationModel(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString() ?? 'EV Charging Hub').replaceAll(RegExp(r'^⚠️\s*\[MOCK\]\s*'), ''),
      address: json['address']?.toString() ?? 'Main Road',
      city: json['city']?.toString() ?? 'Bengaluru',
      state: json['state']?.toString() ?? 'Karnataka',
      pincode: json['pincode']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 12.9716,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 77.5946,
      distanceKm: json['distanceKm'] != null ? double.tryParse(json['distanceKm'].toString()) : null,
      operator: json['operator'] != null ? OperatorInfo.fromJson(json['operator'] as Map<String, dynamic>) : null,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 4.8,
      reliability: json['reliability'] != null ? ReliabilityInfo.fromJson(json['reliability'] as Map<String, dynamic>) : null,
      connectors: conns,
      availableConnectors: json['availableConnectors'] != null
          ? int.tryParse(json['availableConnectors'].toString()) ?? conns.where((c) => c.status == 'AVAILABLE').length
          : conns.where((c) => c.status == 'AVAILABLE').length,
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : ['Cafe', 'Restroom', 'WiFi', '24/7 Security'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'operator': operator?.toJson(),
      'rating': rating,
      'reliability': reliability?.toJson(),
      'connectors': connectors.map((c) => c.toJson()).toList(),
      'availableConnectors': availableConnectors,
      'amenities': amenities,
    };
  }
}

class OperatorInfo {
  final String? id;
  final String? code;
  final String name;
  final bool isMock;

  OperatorInfo({this.id, this.code, required this.name, this.isMock = false});

  factory OperatorInfo.fromJson(Map<String, dynamic> json) {
    return OperatorInfo(
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? 'CPO Network',
      isMock: json['isMock'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'isMock': isMock,
    };
  }
}

class ConnectorModel {
  final String id;
  final String? evseId;
  final String standard; // CCS2, Type2, CHAdeMO, GBT_DC, GBT_AC
  final String powerType; // DC, AC_3_PHASE, AC_1_PHASE
  final double maxPowerKw;
  final String status; // AVAILABLE, CHARGING, RESERVED, MAINTENANCE, OFFLINE
  final TariffModel? tariff;

  ConnectorModel({
    required this.id,
    this.evseId,
    required this.standard,
    required this.powerType,
    required this.maxPowerKw,
    required this.status,
    this.tariff,
  });

  bool get isDc => powerType.toUpperCase().contains('DC') || standard.toUpperCase().contains('CCS') || standard.toUpperCase().contains('GB');
  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';
  bool get isCharging => status.toUpperCase() == 'CHARGING';
  bool get isReserved => status.toUpperCase() == 'RESERVED';

  factory ConnectorModel.fromJson(Map<String, dynamic> json) {
    return ConnectorModel(
      id: json['id']?.toString() ?? '',
      evseId: json['evseId']?.toString(),
      standard: json['standard']?.toString() ?? 'CCS2',
      powerType: json['powerType']?.toString() ?? 'DC',
      maxPowerKw: double.tryParse(json['maxPowerKw']?.toString() ?? '') ?? 60.0,
      status: json['status']?.toString() ?? 'AVAILABLE',
      tariff: json['tariff'] != null ? TariffModel.fromJson(json['tariff'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evseId': evseId,
      'standard': standard,
      'powerType': powerType,
      'maxPowerKw': maxPowerKw,
      'status': status,
      'tariff': tariff?.toJson(),
    };
  }
}

class TariffModel {
  final String? id;
  final double pricePerKwh;
  final double flatFee;
  final double pricePerMin;
  final String currency;

  TariffModel({
    this.id,
    this.pricePerKwh = 14.5,
    this.flatFee = 20.0,
    this.pricePerMin = 0.0,
    this.currency = 'INR',
  });

  factory TariffModel.fromJson(Map<String, dynamic> json) {
    return TariffModel(
      id: json['id']?.toString(),
      pricePerKwh: double.tryParse(json['pricePerKwh']?.toString() ?? '') ?? 14.5,
      flatFee: double.tryParse(json['flatFee']?.toString() ?? '') ?? 20.0,
      pricePerMin: double.tryParse(json['pricePerMin']?.toString() ?? '') ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pricePerKwh': pricePerKwh,
      'flatFee': flatFee,
      'pricePerMin': pricePerMin,
      'currency': currency,
    };
  }
}

class ReliabilityInfo {
  final int score; // 0 - 100
  final bool live;
  final String uptime;
  final String completionRate;
  final List<String> factors;

  ReliabilityInfo({
    this.score = 96,
    this.live = true,
    this.uptime = '99.4%',
    this.completionRate = '98.8%',
    this.factors = const ['Uptime 35%', 'Completion Rate 25%', 'Low Cancellations 15%', 'Telemetry 15%', 'User Feedback 10%'],
  });

  factory ReliabilityInfo.fromJson(Map<String, dynamic> json) {
    return ReliabilityInfo(
      score: int.tryParse(json['score']?.toString() ?? '') ?? 96,
      live: json['live'] == true,
      uptime: json['uptime']?.toString() ?? '99.4%',
      completionRate: json['completionRate']?.toString() ?? '98.8%',
      factors: json['factors'] != null ? List<String>.from(json['factors']) : const ['Uptime 35%', 'Completion Rate 25%'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'live': live,
      'uptime': uptime,
      'completionRate': completionRate,
      'factors': factors,
    };
  }
}
