/// Complete Data Models for the 13 URJAA CPO Operator Modules
library;

class OperatorKpis {
  final double totalRevenue;
  final int activeSessions;
  final double totalEnergyDeliveredKwh;
  final double fleetUtilizationPercent;
  final int totalStations;
  final int totalChargers;

  OperatorKpis({
    this.totalRevenue = 48250.0,
    this.activeSessions = 4,
    this.totalEnergyDeliveredKwh = 3450.8,
    this.fleetUtilizationPercent = 78.5,
    this.totalStations = 6,
    this.totalChargers = 18,
  });

  factory OperatorKpis.fromJson(Map<String, dynamic> json) {
    return OperatorKpis(
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '') ?? 48250.0,
      activeSessions: int.tryParse(json['activeSessions']?.toString() ?? '') ?? 4,
      totalEnergyDeliveredKwh: double.tryParse(json['totalEnergyDeliveredKwh']?.toString() ?? '') ?? 3450.8,
      fleetUtilizationPercent: double.tryParse(json['fleetUtilizationPercent']?.toString() ?? '') ?? 78.5,
      totalStations: int.tryParse(json['totalStations']?.toString() ?? '') ?? 6,
      totalChargers: int.tryParse(json['totalChargers']?.toString() ?? '') ?? 18,
    );
  }
}

class OperatorProfile {
  final String id;
  final String code;
  final String orgName;
  final String legalName;
  final String contactEmail;
  final String contactPhone;
  final String govtApprovalStatus; // APPROVED, UNDER_REVIEW, PENDING
  final String govtApprovalNumber;
  final String gstin;
  final String address;
  final bool kycVerified;
  final int stationCount;

  OperatorProfile({
    required this.id,
    required this.code,
    required this.orgName,
    this.legalName = 'ChargePoint Infrastructure Pvt Ltd',
    required this.contactEmail,
    this.contactPhone = '+91 98450 12345',
    this.govtApprovalStatus = 'APPROVED',
    this.govtApprovalNumber = 'BEE-CPO-2026-IND01',
    this.gstin = '29AABCC1234F1Z5',
    this.address = 'Bengaluru, Karnataka, India',
    this.kycVerified = true,
    this.stationCount = 4,
  });

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? 'op_cpo',
      orgName: json['orgName']?.toString() ?? json['name']?.toString() ?? 'URJAA Operator Hub',
      legalName: json['legalName']?.toString() ?? 'URJAA Network Partner Ltd',
      contactEmail: json['contactEmail']?.toString() ?? json['email']?.toString() ?? 'operator@chargegrid.in',
      contactPhone: json['contactPhone']?.toString() ?? '+91 98450 12345',
      govtApprovalStatus: json['govtApprovalStatus']?.toString() ?? 'APPROVED',
      govtApprovalNumber: json['govtApprovalNumber']?.toString() ?? 'BEE-CPO-2026-081',
      gstin: json['gstin']?.toString() ?? '29AABCC1234F1Z5',
      address: json['address']?.toString() ?? 'Bengaluru, Karnataka',
      kycVerified: json['kycVerified'] == true,
      stationCount: int.tryParse(json['stationCount']?.toString() ?? '') ?? 4,
    );
  }
}

class QueueEntry {
  final String id;
  final String stationId;
  final String stationName;
  final String driverName;
  final String vehicle;
  final int position;
  final int waitMins;
  final String status; // WAITING, CALLED, CHARGING, EXPIRED, CANCELLED
  final DateTime createdAt;

  QueueEntry({
    required this.id,
    required this.stationId,
    this.stationName = 'Koramangala DC Hub',
    required this.driverName,
    this.vehicle = 'Tata Nexon EV Max',
    required this.position,
    required this.waitMins,
    required this.status,
    required this.createdAt,
  });

  bool get isWaiting => status == 'WAITING';
  bool get isCalled => status == 'CALLED';

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Charging Hub',
      driverName: json['driverName']?.toString() ?? 'EV Driver',
      vehicle: json['vehicle']?.toString() ?? 'Tata Nexon EV',
      position: int.tryParse(json['position']?.toString() ?? '') ?? 1,
      waitMins: int.tryParse(json['waitMins']?.toString() ?? '') ?? 8,
      status: json['status']?.toString() ?? 'WAITING',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class IssueTicket {
  final String id;
  final String stationId;
  final String stationName;
  final String chargerId;
  final String errorCode; // GroundFailure, OverCurrentFailure, ConnectorLockFailure, HighTemperature
  final String severity; // CRITICAL, WARNING, INFO
  final String description;
  final String assignedTechnician;
  final String estimatedTimeToRestore;
  final bool isResolved;
  final DateTime createdAt;

  IssueTicket({
    required this.id,
    required this.stationId,
    this.stationName = 'Koramangala HyperCharge Hub',
    this.chargerId = 'CP-01 (60kW CCS2)',
    required this.errorCode,
    required this.severity,
    required this.description,
    this.assignedTechnician = 'Ramesh Kumar (Tech L2)',
    this.estimatedTimeToRestore = '45 mins',
    this.isResolved = false,
    required this.createdAt,
  });

  factory IssueTicket.fromJson(Map<String, dynamic> json) {
    return IssueTicket(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Charging Station',
      chargerId: json['chargerId']?.toString() ?? 'Charger Pedestal 1',
      errorCode: json['errorCode']?.toString() ?? 'GroundFailure',
      severity: json['severity']?.toString() ?? 'CRITICAL',
      description: json['description']?.toString() ?? 'OCPP hardware isolation impedance check tripped.',
      assignedTechnician: json['assignedTechnician']?.toString() ?? 'Field Engineer Assigned',
      estimatedTimeToRestore: json['estimatedTimeToRestore']?.toString() ?? '30 mins',
      isResolved: json['isResolved'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class ReviewItem {
  final String id;
  final String stationId;
  final String stationName;
  final String userName;
  final int rating; // 1 - 5
  final String comment;
  final String? response;
  final DateTime createdAt;

  ReviewItem({
    required this.id,
    required this.stationId,
    this.stationName = 'Koramangala HyperCharge Hub',
    required this.userName,
    required this.rating,
    required this.comment,
    this.response,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Charging Hub',
      userName: json['userName']?.toString() ?? 'EV Driver',
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 5,
      comment: json['comment']?.toString() ?? 'Smooth QR arrival check-in and fast charging speed.',
      response: json['response']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class PricingRule {
  final String id;
  final String name;
  final double baseRatePerKwh;
  final double peakMultiplier;
  final double offPeakDiscountPercent;
  final String peakHours;
  final bool isActive;

  PricingRule({
    required this.id,
    required this.name,
    this.baseRatePerKwh = 14.5,
    this.peakMultiplier = 1.25,
    this.offPeakDiscountPercent = 15.0,
    this.peakHours = '17:00 - 21:00',
    this.isActive = true,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Standard Dynamic Grid Tariff',
      baseRatePerKwh: double.tryParse(json['baseRatePerKwh']?.toString() ?? '') ?? 14.5,
      peakMultiplier: double.tryParse(json['peakMultiplier']?.toString() ?? '') ?? 1.25,
      offPeakDiscountPercent: double.tryParse(json['offPeakDiscountPercent']?.toString() ?? '') ?? 15.0,
      peakHours: json['peakHours']?.toString() ?? '17:00 - 21:00',
      isActive: json['isActive'] != false,
    );
  }
}

class OperatorNotification {
  final String id;
  final String type; // ARRIVAL, BOOKING, TRIP, PAYMENT, QUEUE
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  OperatorNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory OperatorNotification.fromJson(Map<String, dynamic> json) {
    return OperatorNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ARRIVAL',
      title: json['title']?.toString() ?? 'Station Event Alert',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
