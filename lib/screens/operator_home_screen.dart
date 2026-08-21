import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/bluetooth_service.dart';
import '../main.dart';

final apiService = ApiService(backendBase);

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  List stations = [];
  List bookings = [];
  final nameCtrl = TextEditingController();
  Timer? _simTimer;

  String? activeSessionId;

  @override
  void initState() {
    super.initState();
    loadStations();
    // load operator bookings when available
    bluetoothService.startSimulation();
  }

  Future<void> loadStations() async {
    try {
      final res = await apiService.fetchStations();
      setState(() => stations = res);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadOperatorBookings() async {
    try {
      final res = await apiService.fetchOperatorBookings();
      setState(() {
        stations = (res['stations'] as List).map((s) => s).toList();
        bookings = (res['bookings'] as List).map((b) => b).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> addStation() async {
    final body = jsonEncode({
      'name': nameCtrl.text,
      'lat': 0.0,
      'lng': 0.0,
      'connectors': [],
      'tariff': {}
    });
    final token = AuthService.currentToken ?? '';
    try {
      final r = await http.post(Uri.parse('$backendBase/stations'),
          body: body,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          });
      if (r.statusCode == 200) {
        await loadStations();
      } else {
        throw Exception('Add failed: ${r.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> startSessionAsOperator(String bookingId, String qrToken) async {
    try {
      final s = await apiService.startSession(bookingId, qrToken);
      setState(() => activeSessionId = s['id']);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Session started ${s['id']}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void startSimulatedReadings(String sessionId) {
    _simTimer?.cancel();
    double energy = 0.0;
    _simTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      energy += 0.05; // 50 Wh increments
      try {
        await apiService.postReading(sessionId, energy);
      } catch (_) {}
    });
  }

  void stopSimulatedReadings() {
    _simTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator - Your Stations')),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'New Station Name'))),
          ElevatedButton(
              onPressed: addStation, child: const Text('Add Station')),
          Row(children: [
            ElevatedButton(
                onPressed: loadOperatorBookings,
                child: const Text('Load My Bookings')),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () {
                  bluetoothService.startSimulation();
                },
                child: const Text('Start BLE Sim')),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () {
                  stopSimulatedReadings();
                  bluetoothService.stopSimulation();
                },
                child: const Text('Stop Sim')),
          ]),
          const SizedBox(height: 8),
          const Text('Bookings'),
          Expanded(
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (ctx, i) {
                final b = bookings[i];
                final qr = b['qrToken'] ?? '';
                return Card(
                  child: ListTile(
                    title: Text('Booking ${b['id']} - ${b['status']}'),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Slot: ${b['slotStart']}'),
                          const SizedBox(height: 6),
                          Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: Center(
                                child: Text(qr ?? '',
                                    overflow: TextOverflow.ellipsis)),
                          ),
                        ]),
                    trailing: Column(children: [
                      ElevatedButton(
                          onPressed: () => startSessionAsOperator(b['id'], qr),
                          child: const Text('Start Session')),
                      const SizedBox(height: 6),
                      ElevatedButton(
                          onPressed: () =>
                              startSimulatedReadings(activeSessionId ?? ''),
                          child: const Text('Simulate Charging')),
                    ]),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
