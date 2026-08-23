/// Model representing EV slot reservations across open UEI grid
class BookingModel {
  final String id;
  final String? bookingRef;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String locationId;
  final String? stationName;
  final String? stationAddress;
  final String connectorId;
  final String? connectorStandard;
  final double? maxPowerKw;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String status; // PENDING, CONFIRMED, ARRIVED, CHARGING, COMPLETED, CANCELLED
  final double totalCost;
  final bool isEmergency;

  BookingModel({
    required this.id,
    this.bookingRef,
    this.userId,
    this.userName,
    this.userEmail,
    required this.locationId,
    this.stationName,
    this.stationAddress,
    required this.connectorId,
    this.connectorStandard,
    this.maxPowerKw,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    this.totalCost = 320.0,
    this.isEmergency = false,
  });

  bool get isActive => status == 'CONFIRMED' || status == 'ARRIVED' || status == 'CHARGING';
  bool get isCompleted => status == 'COMPLETED';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    var userJson = json['user'] as Map<String, dynamic>?;
    var connectorJson = json['connector'] as Map<String, dynamic>?;
    var locationJson = connectorJson?['evse']?['location'] as Map<String, dynamic>? ?? json['location'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id']?.toString() ?? '',
      bookingRef: json['bookingRef']?.toString() ?? json['externalRef']?.toString() ?? 'UEI-BK-${json['id']?.toString().substring(0, 6).toUpperCase()}',
      userId: json['userId']?.toString() ?? userJson?['id']?.toString(),
      userName: json['userName']?.toString() ?? userJson?['name']?.toString() ?? 'EV Driver',
      userEmail: json['userEmail']?.toString() ?? userJson?['email']?.toString(),
      locationId: json['locationId']?.toString() ?? locationJson?['id']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? locationJson?['name']?.toString() ?? 'Charging Station',
      stationAddress: json['stationAddress']?.toString() ?? locationJson?['address']?.toString(),
      connectorId: json['connectorId']?.toString() ?? connectorJson?['id']?.toString() ?? '',
      connectorStandard: json['connectorStandard']?.toString() ?? connectorJson?['standard']?.toString() ?? 'CCS2',
      maxPowerKw: double.tryParse(json['maxPowerKw']?.toString() ?? connectorJson?['maxPowerKw']?.toString() ?? '') ?? 60.0,
      slotStart: DateTime.tryParse(json['slotStart']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      slotEnd: DateTime.tryParse(json['slotEnd']?.toString() ?? '')?.toLocal() ?? DateTime.now().add(const Duration(minutes: 30)),
      status: json['status']?.toString() ?? 'CONFIRMED',
      totalCost: double.tryParse(json['totalCost']?.toString() ?? json['cost']?.toString() ?? '') ?? 320.0,
      isEmergency: json['isEmergency'] == true || json['vehicleType'] == 'EMERGENCY',
    );
  }
}
