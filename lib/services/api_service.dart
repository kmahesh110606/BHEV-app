import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);
  Map<String, String> get _headers => {'Content-Type': 'application/json', if (AuthService.currentToken != null) 'Authorization': 'Bearer ${AuthService.currentToken}'};

  Future<List<Station>> fetchStations({String? query, String? connector}) async {
    final params = <String, String>{if (query?.isNotEmpty == true) 'q': query!, if (connector?.isNotEmpty == true) 'connector': connector!};
    final res = await http.get(Uri.parse('$baseUrl/api/v1/stations').replace(queryParameters: params));
    if (res.statusCode != 200) throw Exception('Station discovery failed: ${res.body}');
    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['data'] as List).map((item) => Station.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<Station> fetchStationDetails(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/stations/$id'));
    if (res.statusCode != 200) throw Exception('Station details failed: ${res.body}');
    return Station.fromJson(Map<String, dynamic>.from((json.decode(res.body) as Map)['data']));
  }

  Future<Map<String, dynamic>> createBooking({required String connectorId, required String locationId, required DateTime slotStart, required DateTime slotEnd}) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/bookings'), headers: _headers, body: json.encode({'connectorId': connectorId, 'locationId': locationId, 'idempotencyKey': '${locationId}_${connectorId}_${slotStart.millisecondsSinceEpoch}', 'slotStart': slotStart.toUtc().toIso8601String(), 'slotEnd': slotEnd.toUtc().toIso8601String()}));
    if (res.statusCode != 201 && res.statusCode != 200) throw Exception('Booking failed: ${res.body}');
    return Map<String, dynamic>.from((json.decode(res.body) as Map)['data']);
  }

  Future<Map<String, dynamic>> verifyArrival(String bookingId, String token) async {
    final res = await http.post(Uri.parse('$baseUrl/api/v1/arrivals/verify'), headers: _headers, body: json.encode({'bookingId': bookingId, 'token': token}));
    if (res.statusCode != 200) throw Exception('Arrival verification failed: ${res.body}');
    return Map<String, dynamic>.from((json.decode(res.body) as Map)['data']);
  }
}
