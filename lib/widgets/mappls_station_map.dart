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
  final List<latlng.LatLng>? routePoints;
  final latlng.LatLng? originPoint;
  final latlng.LatLng? destinationPoint;
  final MapController? mapController;

  const MapplsStationMap({
    super.key,
    required this.stations,
    required this.onStationTap,
    this.routePoints,
    this.originPoint,
    this.destinationPoint,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final validStations = stations
        .where((station) => station.lat != 0 && station.lng != 0)
        .take(350)
        .toList();
    final center = originPoint ??
        (validStations.isNotEmpty
            ? latlng.LatLng(validStations.first.lat, validStations.first.lng)
            : const latlng.LatLng(20.5937, 78.9629));

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: originPoint != null && destinationPoint != null ? 8.5 : (validStations.isNotEmpty ? 11.5 : 4.3),
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
        if (routePoints != null && routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints!,
                color: const Color(0xFF65D7A5).withValues(alpha: 0.35),
                strokeWidth: 9.0,
              ),
              Polyline(
                points: routePoints!,
                color: const Color(0xFF2563EB),
                strokeWidth: 4.5,
              ),
            ],
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
            if (originPoint != null)
              Marker(
                point: originPoint!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x6610B981), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white, size: 22),
                ),
              ),
            if (destinationPoint != null)
              Marker(
                point: destinationPoint!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x66EF4444), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 24),
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
