import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/station.dart';

/// Leaflet-style station map for mobile discovery.
///
/// The website uses a web map/tile approach for Discover; this Flutter version
/// mirrors that behavior so the emulator always shows a real map even when the
/// native Mappls GL surface is unavailable.
class MapplsStationMap extends StatelessWidget {
  final List<Station> stations;
  final ValueChanged<Station> onStationTap;

  const MapplsStationMap({
    super.key,
    required this.stations,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    final validStations = stations
        .where((station) => station.lat != 0 && station.lng != 0)
        .take(350)
        .toList();
    final center = validStations.isNotEmpty
        ? latlng.LatLng(validStations.first.lat, validStations.first.lng)
        : const latlng.LatLng(20.5937, 78.9629);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: validStations.isNotEmpty ? 11.5 : 4.3,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.uei_app',
          retinaMode: MediaQuery.devicePixelRatioOf(context) > 1,
        ),
        MarkerLayer(
          markers: [
            for (final station in validStations)
              Marker(
                point: latlng.LatLng(station.lat, station.lng),
                width: 54,
                height: 54,
                child: _StationMarker(
                  station: station,
                  onTap: () => onStationTap(station),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StationMarker extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const _StationMarker({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(station.chargerStatus, station.availableConnectors);
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F17),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .35),
                blurRadius: 14,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(
            station.chargerStatus.toUpperCase() == 'CHARGING'
                ? Icons.electric_bolt
                : Icons.ev_station,
            color: color,
            size: 19,
          ),
        ),
      ),
    );
  }
}

Color _stateColor(String state, int availableConnectors) {
  switch (state.toUpperCase()) {
    case 'FREE':
    case 'AVAILABLE':
      return const Color(0xFF16A34A);
    case 'BOOKED':
    case 'QUEUED':
      return const Color(0xFF2563EB);
    case 'EMERGENCY':
      return const Color(0xFFEF4444);
    case 'CHARGING':
      return const Color(0xFFF97316);
    default:
      return availableConnectors > 0
          ? const Color(0xFF16A34A)
          : const Color(0xFF64748B);
  }
}
