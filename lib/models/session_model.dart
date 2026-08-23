/// Model representing active charging sessions, live telemetry, and itemized invoice breakdown
class SessionModel {
  final String id;
  final String? bookingId;
  final String stationName;
  final String? address;
  final String connectorStandard;
  final double maxPowerKw;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final double energyKwh;
  final double livePowerKw;
  final double voltage;
  final double current;
  final double socPercent;
  final double batteryTempC;
  final double baseEnergyCost;
  final double flatConnectionFee;
  final double gst18;
  final double liveCost;
  final String currency;
  final String status; // ACTIVE, COMPLETED, PAID

  SessionModel({
    required this.id,
    this.bookingId,
    required this.stationName,
    this.address,
    required this.connectorStandard,
    required this.maxPowerKw,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.energyKwh,
    this.livePowerKw = 58.4,
    this.voltage = 400.0,
    this.current = 146.0,
    this.socPercent = 54.0,
    this.batteryTempC = 33.2,
    this.baseEnergyCost = 266.8,
    this.flatConnectionFee = 20.0,
    this.gst18 = 51.62,
    required this.liveCost,
    this.currency = 'INR',
    required this.status,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPaid => status == 'PAID';
  bool get isPendingPayment => status == 'COMPLETED';

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    var rawWh = double.tryParse(json['energyWh']?.toString() ?? '') ?? 0.0;
    var rawKwh = json['energyKwh'] != null
        ? (double.tryParse(json['energyKwh'].toString()) ?? (rawWh / 1000))
        : (rawWh / 1000);

    var connectorJson = json['connector'] as Map<String, dynamic>?;
    var locationJson = connectorJson?['evse']?['location'] as Map<String, dynamic>?;
    var breakdown = json['costBreakdown'] as Map<String, dynamic>?;

    var start = DateTime.tryParse(json['startTime']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    var duration = json['durationMinutes'] != null
        ? int.tryParse(json['durationMinutes'].toString()) ?? 15
        : DateTime.now().difference(start).inMinutes;

    double cost = double.tryParse(json['liveCost']?.toString() ?? json['cost']?.toString() ?? '') ?? 0.0;
    double baseCost = breakdown?['baseEnergyCost'] != null ? double.tryParse(breakdown!['baseEnergyCost'].toString()) ?? (cost * 0.8) : (cost * 0.8);
    double flat = breakdown?['flatFee'] != null ? double.tryParse(breakdown!['flatFee'].toString()) ?? 20.0 : 20.0;
    double gst = breakdown?['gst18'] != null ? double.tryParse(breakdown!['gst18'].toString()) ?? (cost * 0.18) : (cost * 0.18);

    return SessionModel(
      id: json['id']?.toString() ?? json['sessionId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
      stationName: json['stationName']?.toString() ?? locationJson?['name']?.toString() ?? 'URJAA Fast Hub',
      address: json['address']?.toString() ?? locationJson?['address']?.toString(),
      connectorStandard: json['connectorStandard']?.toString() ?? connectorJson?['standard']?.toString() ?? 'CCS2',
      maxPowerKw: double.tryParse(json['maxPowerKw']?.toString() ?? connectorJson?['maxPowerKw']?.toString() ?? '') ?? 60.0,
      startTime: start,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString())?.toLocal() : null,
      durationMinutes: duration > 0 ? duration : 1,
      energyKwh: double.parse(rawKwh.toStringAsFixed(2)),
      livePowerKw: double.tryParse(json['powerKw']?.toString() ?? '') ?? 58.4,
      voltage: double.tryParse(json['voltage']?.toString() ?? '') ?? 400.0,
      current: double.tryParse(json['current']?.toString() ?? '') ?? 146.0,
      socPercent: double.tryParse(json['socPercent']?.toString() ?? '') ?? 54.0,
      batteryTempC: double.tryParse(json['batteryTempC']?.toString() ?? '') ?? 33.2,
      baseEnergyCost: double.parse(baseCost.toStringAsFixed(2)),
      flatConnectionFee: double.parse(flat.toStringAsFixed(2)),
      gst18: double.parse(gst.toStringAsFixed(2)),
      liveCost: double.parse(cost.toStringAsFixed(2)),
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}
