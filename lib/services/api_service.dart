import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthService.currentToken != null)
          'Authorization': 'Bearer ${AuthService.currentToken}'
      };

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated && AuthService.currentToken != null)
        'Authorization': 'Bearer ${AuthService.currentToken}',
    };
    final response = switch (method) {
      'POST' =>
        await http.post(uri, headers: headers, body: json.encode(body ?? {})),
      'PATCH' =>
        await http.patch(uri, headers: headers, body: json.encode(body ?? {})),
      _ => await http.get(uri, headers: headers),
    };
    dynamic rawDecoded;
    try {
      rawDecoded =
          response.body.isEmpty ? <String, dynamic>{} : json.decode(response.body);
    } catch (_) {
      rawDecoded = {'message': response.body};
    }
    final decoded = rawDecoded is Map
        ? Map<String, dynamic>.from(rawDecoded)
        : <String, dynamic>{'message': response.body};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] ?? decoded['message'] ?? response.body);
    }
    return decoded;
  }

  Future<List<Station>> fetchStations(
      {String? query, String? connector}) async {
    final params = <String, String>{
      if (query?.isNotEmpty == true) 'q': query!,
      if (connector?.isNotEmpty == true) 'connector': connector!,
      'limit': '700',
    };
    var res = await http.get(Uri.parse('$baseUrl/api/v1/stations')
        .replace(queryParameters: params));
    if (res.statusCode != 200) {
      res = await http.get(Uri.parse('$baseUrl/api/v1/stations/national')
          .replace(queryParameters: params));
    }
    if (res.statusCode != 200) {
      throw Exception('Station discovery failed: ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['data'] as List)
        .map((item) => Station.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Station> fetchStationDetails(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/stations/$id'));
    if (res.statusCode != 200) {
      throw Exception('Station details failed: ${res.body}');
    }
    return Station.fromJson(
        Map<String, dynamic>.from((json.decode(res.body) as Map)['data']));
  }

  Future<Map<String, dynamic>> fetchCharger(String chargerId) async {
    final json = await _request('/api/v1/chargers/$chargerId');
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  // ── Direct Session Start ────────────────────────────────────────────────
  Future<Map<String, dynamic>> startSession({
    required String stationId,
    required String connectorId,
    double initialSoc = 25,
    String vehicleName = 'Tata Nexon EV Max',
  }) async {
    final json = await _request(
      '/api/v1/sessions/start',
      method: 'POST',
      authenticated: true,
      body: {
        'stationId': stationId,
        'connectorId': connectorId,
        'initialSoc': initialSoc,
        'vehicleName': vehicleName,
      },
    );
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> createBooking(
      {required String connectorId,
      required String locationId,
      required DateTime slotStart,
      required DateTime slotEnd,
      String bookingType = 'STANDARD',
      bool emergency = false,
      String driverName = 'Mobile EV Driver',
      String driverEmail = 'mobile.driver@chargegrid.local',
      String vehicleName = 'Tata Nexon EV Max'}) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/bookings'),
        headers: _headers,
        body: json.encode({
          'connectorId': connectorId,
          'locationId': locationId,
          'idempotencyKey':
              '${locationId}_${connectorId}_${bookingType}_${slotStart.millisecondsSinceEpoch}',
          'slotStart': slotStart.toUtc().toIso8601String(),
          'slotEnd': slotEnd.toUtc().toIso8601String(),
          'bookingType': bookingType,
          'emergency': emergency,
          'driverName': driverName,
          'driverEmail': driverEmail,
          'vehicleName': vehicleName
        }));
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Booking failed: ${res.body}');
    }
    return Map<String, dynamic>.from((json.decode(res.body) as Map)['data']);
  }

  Future<List<Map<String, dynamic>>> myBookings({String? driverEmail}) async {
    final path = driverEmail == null
        ? '/api/v1/bookings/me'
        : '/api/v1/bookings/me?driverEmail=${Uri.encodeQueryComponent(driverEmail)}';
    final json = await _request(path, authenticated: true);
    final data = json['data'] as List? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> startBookingSession(String bookingId,
      {double initialSoc = 32}) async {
    final json = await _request('/api/v1/bookings/$bookingId/start-charging',
        method: 'POST', authenticated: true, body: {'initialSoc': initialSoc});
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> verifyArrival(String token,
      {String? bookingId}) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/arrivals/verify'),
        headers: _headers,
        body: json.encode({
          if (bookingId?.isNotEmpty == true) 'bookingId': bookingId,
          'token': token
        }));
    if (res.statusCode != 200) {
      throw Exception('Arrival verification failed: ${res.body}');
    }
    return Map<String, dynamic>.from((json.decode(res.body) as Map)['data']);
  }

  // ── Driver sessions and payment ────────────────────────────────────────
  Future<Map<String, dynamic>?> activeSession() async {
    final json = await _request('/api/v1/sessions/active',
        authenticated: AuthService.currentToken != null);
    final data = json['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<List<Map<String, dynamic>>> mySessions() async {
    final json = await _request('/api/v1/sessions/me',
        authenticated: AuthService.currentToken != null);
    final data = json['data'] as List? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> stopSession(String sessionId) async {
    final json = await _request('/api/v1/sessions/$sessionId/stop',
        method: 'POST', authenticated: true);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> paySession(
      String sessionId, String paymentMethod) async {
    final json = await _request('/api/v1/sessions/$sessionId/pay',
        method: 'POST',
        authenticated: true,
        body: {'paymentMethod': paymentMethod});
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  // ── Mock Bluetooth/IOT EV profile ─────────────────────────────────────
  Future<Map<String, dynamic>> connectMockEv(
      {String vehicleName = 'Tata Nexon EV Max', String? sessionId}) async {
    final json = await _request('/api/v1/iot/mock-ev/connect',
        method: 'POST',
        body: {
          'vehicleName': vehicleName,
          'bluetoothId': 'BHEV-APP-BLE-01',
          if (sessionId != null) 'sessionId': sessionId,
        });
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> mockEvStatus({String? sessionId}) async {
    final path = sessionId == null
        ? '/api/v1/iot/mock-ev/status'
        : '/api/v1/iot/mock-ev/status?sessionId=${Uri.encodeQueryComponent(sessionId)}';
    final json = await _request(path);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  // ── Kiosk, secure rotating QR and telemetry ───────────────────────────
  Future<Map<String, dynamic>> kioskState(String stationId) async {
    final json = await _request('/api/v1/kiosk/$stationId/state',
        authenticated: AuthService.currentToken != null);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> startKioskSession(
      String stationId, String? connectorId) async {
    final json = await _request('/api/v1/kiosk/$stationId/start-session',
        method: 'POST',
        authenticated: AuthService.currentToken != null,
        body: connectorId == null ? {} : {'connectorId': connectorId});
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> stopKioskSession(
      String stationId, double finalEnergyWh) async {
    final json = await _request('/api/v1/kiosk/$stationId/stop-session',
        method: 'POST',
        authenticated: AuthService.currentToken != null,
        body: {'finalEnergyWh': finalEnergyWh});
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<void> sendTelemetry(
    String stationId, {
    required double energyWh,
    required double powerKw,
    required double socPercent,
    required double batteryTempC,
  }) async {
    await _request('/api/v1/kiosk/$stationId/telemetry',
        method: 'POST',
        authenticated: AuthService.currentToken != null,
        body: {
          'energyWh': energyWh,
          'powerKw': powerKw,
          'voltage': 400,
          'current': 125,
          'frequencyHz': 50.02,
          'powerFactor': 0.99,
          'socPercent': socPercent,
          'batteryTempC': batteryTempC,
          'chargerTempC': 38.5,
          'chargingPhase': socPercent > 80 ? 'CV' : 'CC',
          'pilotSignalState': 'C',
          'cableLockStatus': 'LOCKED',
        });
  }

  Future<Map<String, dynamic>> dynamicQr(String stationId) async {
    final json = await _request(
        '/api/v1/qr/$stationId',
        authenticated: true);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  // ── CPO operator console ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> operatorStations() async {
    final json =
        await _request('/api/v1/operator/stations', authenticated: true);
    final data = json['data'] as List? ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> addCharger(
      String stationId, Map<String, dynamic> data) async {
    final json = await _request(
      '/api/v1/operator/stations/$stationId/chargers',
      method: 'POST',
      authenticated: true,
      body: data,
    );
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> toggleMaintenance(
      String chargerId, bool enable) async {
    final path = enable
        ? '/api/v1/operator/chargers/$chargerId/maintenance'
        : '/api/v1/operator/chargers/$chargerId/maintenance/end';
    final json = await _request(path, method: 'POST', authenticated: true);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> fetchOperatorAnalytics() async {
    final json =
        await _request('/api/v1/operator/analytics', authenticated: true);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Station> createOperatorStation(Map<String, dynamic> input) async {
    final json = await _request('/api/v1/operator/stations',
        method: 'POST', authenticated: true, body: input);
    return Station.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }
}
