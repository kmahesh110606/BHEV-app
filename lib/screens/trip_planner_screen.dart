import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../widgets/mappls_station_map.dart';
import '../widgets/station_preview_sheet.dart';

final _api = ApiService(backendBase);

class CityPoint {
  final String name;
  final double lat;
  final double lng;
  const CityPoint(this.name, this.lat, this.lng);
}

const List<CityPoint> kIndianHubs = [
  CityPoint('Bengaluru, Karnataka', 12.9716, 77.5946),
  CityPoint('Chennai, Tamil Nadu', 13.0827, 80.2707),
  CityPoint('Hyderabad, Telangana', 17.3850, 78.4867),
  CityPoint('Mumbai, Maharashtra', 19.0760, 72.8777),
  CityPoint('Pune, Maharashtra', 18.5204, 73.8567),
  CityPoint('New Delhi, NCR', 28.6139, 77.2090),
  CityPoint('Jaipur, Rajasthan', 26.9124, 75.7873),
  CityPoint('Ahmedabad, Gujarat', 23.0225, 72.5714),
  CityPoint('Kochi, Kerala', 9.9312, 76.2673),
  CityPoint('Coimbatore, Tamil Nadu', 11.0168, 76.9558),
  CityPoint('Mysuru, Karnataka', 12.2958, 76.6394),
  CityPoint('Goa (Panaji)', 15.4909, 73.8278),
  CityPoint('Kolkata, West Bengal', 22.5726, 88.3639),
];

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  CityPoint _origin = kIndianHubs[0]; // Bengaluru
  CityPoint _destination = kIndianHubs[1]; // Chennai

  List<Station> _allStations = [];
  List<Station> _corridorStations = [];
  List<latlng.LatLng> _routePoints = [];
  bool _isLoading = true;
  double _totalDistanceKm = 0;
  int _estimatedMinutes = 0;
  double _batteryNeededKwh = 0;
  int _currentSoc = 85;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStationsAndPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStationsAndPlan() async {
    setState(() => _isLoading = true);
    try {
      final stations = await _api.fetchStations();
      _allStations = stations;
    } catch (_) {
      // Fallback
    }
    _recalculateRoute();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _recalculateRoute() {
    final start = latlng.LatLng(_origin.lat, _origin.lng);
    final end = latlng.LatLng(_destination.lat, _destination.lng);

    // Generate intermediate waypoint route curve
    final points = <latlng.LatLng>[];
    const steps = 30;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      points.add(latlng.LatLng(lat, lng));
    }
    _routePoints = points;

    final dist = _haversineKm(_origin.lat, _origin.lng, _destination.lat, _destination.lng);
    _totalDistanceKm = dist * 1.18; // road winding factor
    _estimatedMinutes = ((_totalDistanceKm / 65.0) * 60).round();
    _batteryNeededKwh = _totalDistanceKm * 0.16; // avg 160 Wh/km

    // Filter stations along the route corridor (within 25 km of any route point)
    final corridor = <Station>[];
    for (final stn in _allStations) {
      if (stn.lat == 0 || stn.lng == 0) continue;
      final minDistanceToRoute = _minDistanceToPath(stn.lat, stn.lng, _routePoints);
      if (minDistanceToRoute <= 35.0) {
        corridor.add(stn);
      }
    }

    // Sort corridor stations by distance from origin
    corridor.sort((a, b) {
      final distA = _haversineKm(_origin.lat, _origin.lng, a.lat, a.lng);
      final distB = _haversineKm(_origin.lat, _origin.lng, b.lat, b.lng);
      return distA.compareTo(distB);
    });

    _corridorStations = corridor;
  }

  double _minDistanceToPath(double lat, double lng, List<latlng.LatLng> path) {
    var minD = double.infinity;
    for (final pt in path) {
      final d = _haversineKm(lat, lng, pt.latitude, pt.longitude);
      if (d < minD) minD = d;
    }
    return minD;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final p = math.pi / 180.0;
    final dLat = (lat2 - lat1) * p;
    final dLon = (lon2 - lon1) * p;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * p) * math.cos(lat2 * p) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  void _showStationPreview(Station station) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.72,
        child: StationPreviewSheet(station: station),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      appBar: AppBar(
        title: const Text('EV Route & Destination Planner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: const Color(0xFF0F1522),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF65D7A5),
          labelColor: const Color(0xFF65D7A5),
          unselectedLabelColor: const Color(0xFF8B9BB0),
          tabs: const [
            Tab(icon: Icon(FluentIcons.directions_24_regular, size: 18), text: 'Route Stops'),
            Tab(icon: Icon(FluentIcons.map_24_regular, size: 18), text: 'Full Map View'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF65D7A5)))
          : Column(
              children: [
                _buildRouteSelectionCard(),
                _buildTripMetricsBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStopsListView(),
                      _buildFullMapView(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRouteSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF121927),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Column(
                children: [
                  Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 18),
                  SizedBox(height: 14),
                  Icon(Icons.more_vert, color: Color(0xFF475569), size: 14),
                  SizedBox(height: 14),
                  Icon(Icons.location_on, color: Color(0xFFEF4444), size: 20),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildHubDropdown(
                      label: 'Starting Location',
                      value: _origin,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _origin = val;
                            _recalculateRoute();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildHubDropdown(
                      label: 'Destination',
                      value: _destination,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _destination = val;
                            _recalculateRoute();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(FluentIcons.arrow_swap_24_regular, color: Color(0xFF65D7A5)),
                onPressed: () {
                  setState(() {
                    final tmp = _origin;
                    _origin = _destination;
                    _destination = tmp;
                    _recalculateRoute();
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(FluentIcons.battery_charge_24_filled, color: Color(0xFF65D7A5), size: 16),
              const SizedBox(width: 8),
              Text(
                'Starting Battery: $_currentSoc%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE2E8F0)),
              ),
              const Spacer(),
              for (final soc in [40, 65, 85, 100])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () => setState(() => _currentSoc = soc),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _currentSoc == soc ? const Color(0xFF65D7A5) : const Color(0xFF0B0F17),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currentSoc == soc ? const Color(0xFF65D7A5) : const Color(0x33FFFFFF),
                        ),
                      ),
                      child: Text(
                        '$soc%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _currentSoc == soc ? const Color(0xFF0B0F17) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHubDropdown({
    required String label,
    required CityPoint value,
    required ValueChanged<CityPoint?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CityPoint>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF141C2B),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
          items: kIndianHubs.map((hub) {
            return DropdownMenuItem(
              value: hub,
              child: Text(
                hub.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTripMetricsBar() {
    final hours = _estimatedMinutes ~/ 60;
    final mins = _estimatedMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF162132),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(FluentIcons.vehicle_car_24_regular, '${_totalDistanceKm.toStringAsFixed(0)} km', 'Driving Distance'),
          _buildMetricItem(FluentIcons.clock_24_regular, timeStr, 'Est. Travel Time'),
          _buildMetricItem(FluentIcons.flash_24_regular, '${_batteryNeededKwh.toStringAsFixed(1)} kWh', 'Energy Required'),
          _buildMetricItem(FluentIcons.battery_charge_24_regular, '${_corridorStations.length}', 'Corridor Stations'),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF65D7A5)),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF8B9CB2))),
      ],
    );
  }

  Widget _buildStopsListView() {
    if (_corridorStations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.warning_24_regular, size: 48, color: Color(0xFFFBBF24)),
              const SizedBox(height: 12),
              const Text('No direct highway corridor stations found for this segment.',
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              const Text('Explore nearby city stations on the Full Map View tab.',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(FluentIcons.map_24_regular),
                label: const Text('Open Map View'),
              )
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _corridorStations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Text('RECOMMENDED CHARGING STOPS',
                      style: TextStyle(color: Color(0xFF65D7A5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
                const Spacer(),
                Text('${_corridorStations.length} stations along route',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8B9CB2))),
              ],
            ),
          );
        }

        final station = _corridorStations[index - 1];
        final distFromStart = _haversineKm(_origin.lat, _origin.lng, station.lat, station.lng);
        final distToRoute = _minDistanceToPath(station.lat, station.lng, _routePoints);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF121A28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
          child: InkWell(
            onTap: () => _showStationPreview(station),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF65D7A5).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF65D7A5)),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: const TextStyle(color: Color(0xFF65D7A5), fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              station.address.isNotEmpty ? station.address : station.city,
                              style: const TextStyle(color: Color(0xFF8B9CB2), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: station.availableConnectors > 0
                              ? const Color(0x2610B981)
                              : const Color(0x26EF4444),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          station.availableConnectors > 0 ? '${station.availableConnectors} Avail' : 'Busy',
                          style: TextStyle(
                            color: station.availableConnectors > 0 ? const Color(0xFF65D7A5) : const Color(0xFFF87171),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip(FluentIcons.navigation_24_regular, '${distFromStart.toStringAsFixed(0)} km from start'),
                      const SizedBox(width: 8),
                      _buildChip(FluentIcons.arrow_routing_24_regular, '${distToRoute.toStringAsFixed(1)} km off highway'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showStationPreview(station),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF65D7A5),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(FluentIcons.flash_24_filled, size: 14),
                        label: const Text('Charge Here', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F17),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF8B9CB2)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Color(0xFF8B9CB2), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFullMapView() {
    return Stack(
      children: [
        MapplsStationMap(
          mapController: _mapController,
          stations: _allStations,
          onStationTap: _showStationPreview,
          routePoints: _routePoints,
          originPoint: latlng.LatLng(_origin.lat, _origin.lng),
          destinationPoint: latlng.LatLng(_destination.lat, _destination.lng),
        ),
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xEE0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x33FFFFFF)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.map_24_filled, color: Color(0xFF65D7A5), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_origin.name.split(',')[0]} ➔ ${_destination.name.split(',')[0]} Route Corridor',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                Text(
                  '${_corridorStations.length} Stops',
                  style: const TextStyle(color: Color(0xFF65D7A5), fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
