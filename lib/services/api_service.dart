import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/station_model.dart';
import '../models/booking_model.dart';
import '../models/session_model.dart';
import 'auth_service.dart';

/// REST API Client connecting mobile app to URJAA backend and website infrastructure
class ApiService {
  static Map<String, String> get _headers {
    final token = AuthService.currentToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Stations Discovery ──
  static Future<List<StationModel>> getStations({String? city, String? search}) async {
    try {
      final uri = Uri.parse(ApiConfig.stations).replace(
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (search != null && search.isNotEmpty) 'q': search,
        },
      );

      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        return list.map((item) => StationModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<StationModel>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 25.0,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.nearbyStations).replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'radius': radiusKm.toString(),
        },
      );

      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        return list.map((item) => StationModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<StationModel?> getStationDetails(String stationId) async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.stationDetails(stationId)), headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['data'] != null) {
          return StationModel.fromJson(json['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Bookings & Reservations ──
  static Future<BookingModel?> createBooking({
    required String locationId,
    required String connectorId,
    required DateTime slotStart,
    required DateTime slotEnd,
    String? vehicleType,
  }) async {
    try {
      final idempotencyKey = 'idemp_${DateTime.now().millisecondsSinceEpoch}_${locationId.substring(0, 6)}';
      final res = await http.post(
        Uri.parse(ApiConfig.createBooking),
        headers: _headers,
        body: jsonEncode({
          'locationId': locationId,
          'connectorId': connectorId,
          'slotStart': slotStart.toUtc().toIso8601String(),
          'slotEnd': slotEnd.toUtc().toIso8601String(),
          'idempotencyKey': idempotencyKey,
          'vehicleType': vehicleType ?? 'EV',
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['data'] != null) {
          return BookingModel.fromJson(json['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BookingModel>> getMyBookings() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.myBookings), headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        return list.map((item) => BookingModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Arrival QR Verification ──
  static Future<Map<String, dynamic>> verifyArrivalQr({
    required String qrToken,
    String? bookingId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.verifyArrivalQr),
        headers: _headers,
        body: jsonEncode({
          'token': qrToken.trim(),
          if (bookingId != null) 'bookingId': bookingId,
        }),
      );

      final json = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 || res.statusCode == 201,
        'message': json['message']?.toString() ?? (res.statusCode == 200 ? 'Verified successfully' : 'Verification failed'),
        'data': json['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Charging Sessions & Payments ──
  static Future<SessionModel?> getActiveSession() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.activeSession), headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['data'] != null) {
          return SessionModel.fromJson(json['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SessionModel>> getSessionHistory() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.sessionHistory), headers: _headers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        return list.map((item) => SessionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> stopSession(String sessionId) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.stopSession(sessionId)), headers: _headers);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> paySession({
    required String sessionId,
    String paymentMethod = 'UPI',
    String? transactionRef,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.paySession(sessionId)),
        headers: _headers,
        body: jsonEncode({
          'paymentMethod': paymentMethod,
          'transactionRef': transactionRef ?? 'UPI-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      final json = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': json['message']?.toString() ?? 'Payment processed',
        'data': json['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Payment error: $e'};
    }
  }
}
