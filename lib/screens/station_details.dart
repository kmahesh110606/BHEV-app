import 'package:flutter/material.dart';
import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';

final api = ApiService(backendBase);

class StationDetailsScreen extends StatelessWidget {
  final String stationId;
  const StationDetailsScreen({super.key, required this.stationId});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Station details')),
    body: FutureBuilder<Station>(future: api.fetchStationDetails(stationId), builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
      final station = snapshot.data!;
      return ListView(padding: const EdgeInsets.all(16), children: [
        Text(station.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8), Text('${station.operatorName}${station.isMock ? ' · Prototype CPO feed' : ''}'), Text('${station.address}, ${station.city}'),
        const SizedBox(height: 20), Text('Reliability ${station.reliabilityScore}/100 · ${station.availableConnectors} currently available'),
        const SizedBox(height: 20), const Text('Choose a connector', style: TextStyle(fontWeight: FontWeight.bold)),
        ...station.connectors.map((connector) => Card(child: ListTile(
          title: Text('${connector.standard} · ${connector.maxPowerKw.toStringAsFixed(0)} kW'), subtitle: Text('${connector.powerType} · ${connector.status}'),
          trailing: connector.status == 'AVAILABLE' ? ElevatedButton(onPressed: () async {
            final start = DateTime.now().add(const Duration(minutes: 5));
            try {
              final booking = await api.createBooking(connectorId: connector.id, locationId: station.id, slotStart: start, slotEnd: start.add(const Duration(hours: 1)));
              if (!context.mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => BookingResultScreen(booking: booking)));
            } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
          }, child: const Text('Book')) : const Text('Unavailable'),
        ))),
      ]);
    }),
  );
}

class BookingResultScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const BookingResultScreen({super.key, required this.booking});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking confirmed')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reference: ${booking['externalRef'] ?? booking['id']}', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
      Text('Slot: ${booking['slotStart']}'), const SizedBox(height: 12),
      const Text('At the station, scan the short-lived QR displayed by the authorized operator. CHARGEGRID verifies it before the provider starts charging.'),
    ])),
  );
}
