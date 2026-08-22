import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../models/station.dart';

/// Native Mappls GL surface shared by Discover. Station annotations are added
/// after the provider style is ready, as required by the Mappls Flutter SDK.
class MapplsStationMap extends StatefulWidget {
  final List<Station> stations;
  final ValueChanged<Station> onStationTap;
  const MapplsStationMap(
      {super.key, required this.stations, required this.onStationTap});

  @override
  State<MapplsStationMap> createState() => _MapplsStationMapState();
}

class _MapplsStationMapState extends State<MapplsStationMap> {
  MapplsMapController? _controller;
  final Map<String, Station> _stationBySymbol = {};
  bool _styleReady = false;

  @override
  void didUpdateWidget(covariant MapplsStationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleReady && oldWidget.stations != widget.stations) _drawStations();
  }

  Future<void> _drawStations() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    await controller.clearSymbols();
    _stationBySymbol.clear();
    for (final station in widget.stations
        .where((item) => item.lat != 0 && item.lng != 0)
        .take(250)) {
      final symbol = await controller.addSymbol(SymbolOptions(
        geometry: LatLng(station.lat, station.lng),
        textField: station.availableConnectors > 0 ? '⚡' : '•',
        textSize: 20,
        textColor: station.availableConnectors > 0 ? '#65D7A5' : '#F6C66C',
        textHaloColor: '#071018',
        textHaloWidth: 1.5,
        textAnchor: 'center',
      ));
      _stationBySymbol[symbol.id] = station;
    }
  }

  @override
  Widget build(BuildContext context) => MapplsMap(
        initialCameraPosition:
            const CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 4),
        onMapCreated: (controller) {
          _controller = controller;
          controller.onSymbolTapped.add((symbol) {
            final station = _stationBySymbol[symbol.id];
            if (station != null) widget.onStationTap(station);
          });
        },
        onStyleLoadedCallback: () {
          _styleReady = true;
          _drawStations();
        },
      );
}
