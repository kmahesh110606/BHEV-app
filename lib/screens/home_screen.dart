import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:mappls_gl/mappls_gl.dart';
import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';
import 'station_details.dart';

final apiService = ApiService(backendBase);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Station>> _stations = apiService.fetchStations();
  Station? selected;
  void _reload() => setState(() => _stations = apiService.fetchStations());

  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: FutureBuilder<List<Station>>(
      future: _stations,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load CHARGEGRID stations.\n${snapshot.error}', textAlign: TextAlign.center)));
        final stations = snapshot.data ?? const <Station>[];
        final active = selected ?? (stations.isNotEmpty ? stations.first : null);
        return Stack(children: [
          Positioned.fill(child: MapplsMap(initialCameraPosition: CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 4.0))),
          Positioned(top: 16, left: 16, right: 16, child: GlassContainer(child: Row(children: [const Icon(FluentIcons.search_24_regular, color: Colors.white54), const SizedBox(width: 8), const Expanded(child: Text('CHARGEGRID · Mappls station discovery', style: TextStyle(color: Colors.white70))), IconButton(onPressed: _reload, icon: const Icon(FluentIcons.arrow_sync_24_regular, color: Color(0xFF7DF7CF)))]))),
          Positioned(left: 0, right: 0, bottom: 16, child: SizedBox(height: 245, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: stations.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, index) { final station = stations[index]; return SizedBox(width: 285, child: InkWell(onTap: () => setState(() => selected = station), child: GlassContainer(color: active?.id == station.id ? const Color(0x1A39FF96) : null, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(station.isMock ? 'PROTOTYPE CPO FEED' : station.operatorName, style: const TextStyle(color: Color(0xFF7DF7CF), fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(station.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${station.address}, ${station.city}', style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 2), const Spacer(), Text('${station.availableConnectors} available · reliability ${station.reliabilityScore}/100', style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StationDetailsScreen(stationId: station.id))), child: const Text('VIEW & BOOK')))])))); })))]);
      },
    )),
  );
}
