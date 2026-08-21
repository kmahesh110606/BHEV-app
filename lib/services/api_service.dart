import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  Future<List<Station>> fetchStations() async {
    final res = await http.get(Uri.parse('$baseUrl/stations'));
    if (res.statusCode != 200) throw Exception('Failed');
    final data = json.decode(res.body) as List;
    return data.map((e) => Station.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> fetchStationDetails(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/stations/$id'));
    if (res.statusCode != 200) throw Exception('Failed retrieving details');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBooking(
      String stationId, String slotStart, String slotEnd) async {
    final token = AuthService.currentToken;
    final res = await http.post(Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'stationId': stationId,
          'slotStart': slotStart,
          'slotEnd': slotEnd
        }));
    if (res.statusCode != 200) throw Exception('Booking failed: ${res.body}');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startSession(
      String bookingId, String qrToken) async {
    final token = AuthService.currentToken;
    final res = await http.post(Uri.parse('$baseUrl/sessions'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
        body: json.encode({'bookingId': bookingId, 'qrToken': qrToken}));
    if (res.statusCode != 200) {
      throw Exception('Start session failed: ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postReading(
      String sessionId, double energyKwh) async {
    final token = AuthService.currentToken;
    final res =
        await http.post(Uri.parse('$baseUrl/sessions/$sessionId/reading'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token'
            },
            body: json.encode({'energy': energyKwh}));
    if (res.statusCode != 200) throw Exception('Reading failed: ${res.body}');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchOperatorBookings() async {
    final token = AuthService.currentToken;
    final res = await http.get(Uri.parse('$baseUrl/operator/bookings'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed');
    return json.decode(res.body) as Map<String, dynamic>;
  }
}
