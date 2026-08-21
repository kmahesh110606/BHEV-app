import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

final api = ApiService(backendBase);

class StationDetailsScreen extends StatelessWidget {
  final String stationId;
  const StationDetailsScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station Details')),
      body: FutureBuilder(
        future: api.fetchStationDetails(stationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data as Map<String, dynamic>;
          final station = data['station'];
          final slots = data['availableSlots'] as List<dynamic>;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Text(station['name'] ?? 'Station',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Operator: ${station['operator'] ?? ''}'),
              const SizedBox(height: 12),
              const Text('Available Slots:'),
              Expanded(
                child: ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (ctx, i) {
                    final s = slots[i];
                    final start = DateTime.parse(s['slotStart']);
                    return ListTile(
                      title: Text('${start.toLocal()}'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            final booking = await api.createBooking(
                                stationId, s['slotStart'], s['slotEnd']);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        BookingResultScreen(booking: booking)));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        },
                        child: const Text('Book'),
                      ),
                    );
                  },
                ),
              )
            ]),
          );
        },
      ),
    );
  }
}

class BookingResultScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingResultScreen({super.key, required this.booking});

  @override
  State<BookingResultScreen> createState() => _BookingResultScreenState();
}

class _BookingResultScreenState extends State<BookingResultScreen> {
  final qrCtrl = TextEditingController();
  Map<String, dynamic>? session;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: ${b['id']}'),
            const SizedBox(height: 8),
            Text('Station: ${b['stationId']}'),
            const SizedBox(height: 8),
            Text('Slot: ${b['slotStart']}'),
            const SizedBox(height: 12),
            const Text(
                'When operator shows QR, enter token below to start session (simulate scanning):'),
            TextField(
                controller: qrCtrl,
                decoration: const InputDecoration(labelText: 'QR token')),
            ElevatedButton(
                onPressed: () async {
                  try {
                    final s = await api.startSession(b['id'], qrCtrl.text);
                    setState(() => session = s);
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Start Session')),
            if (session != null) ...[
              const SizedBox(height: 12),
              Text('Session started: ${session!['id']}')
            ]
          ],
        ),
      ),
    );
  }
}
