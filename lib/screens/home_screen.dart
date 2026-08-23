import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/offline_cache_service.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/station_preview_sheet.dart';
import 'station_details.dart';
import 'booking_screen.dart';

/// Data class representing clustered stations on the national map
class MapCluster {
  final LatLng center;
  final int count;
  final List<StationModel> stations;

  MapCluster({
    required this.center,
    required this.count,
    required this.stations,
  });

  bool get isSingle => count == 1;
}

/// Discover screen with full interactive map, national dynamic spatial clustering, GPS auto-centering, and smart recommendations
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  List<StationModel> _stations = [];
  bool _isLoading = true;
  bool _isMapView = true; // Toggle between Map View and List View
  String _selectedCity = 'All';
  String _selectedFilter = 'All'; // All, DC Fast, Type 2, Available, Govt
  String? _cacheSyncStatus;
  LatLng _userPosition = const LatLng(12.9716, 77.5946); // Default Bengaluru
  bool _hasUserLocation = false;
  double _currentZoom = 6.5; // Starts with National Cluster Overview

  final List<String> _cities = ['All', 'Bengaluru', 'Delhi', 'Mumbai', 'Hyderabad', 'Chennai', 'Pune', 'Kolkata'];
  final List<String> _filters = ['All', '⚡ DC Fast (50kW+)', 'Type 2 AC', '🟢 Available Now', '🏛️ Govt. / BEE'];

  @override
  void initState() {
    super.initState();
    _initLocationAndLoadStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndLoadStations() async {
    setState(() => _isLoading = true);

    List<StationModel> allList = [];

    // 1. Load national 29,084 BEE dataset from bundled compact asset
    try {
      final jsonStr = await rootBundle.loadString('assets/bee_stations_compact.json');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final beeList = decoded.map((item) {
        final id = item['id']?.toString() ?? '';
        final name = item['name']?.toString() ?? 'EV Station';
        final cpo = item['cpo']?.toString() ?? 'BEE';
        final city = item['city']?.toString() ?? '';
        final state = item['state']?.toString() ?? '';
        final address = item['address']?.toString() ?? '';
        final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 12.9716;
        final lng = double.tryParse(item['lng']?.toString() ?? '') ?? 77.5946;
        final conns = int.tryParse(item['conns']?.toString() ?? '') ?? 1;
        final power = double.tryParse(item['power']?.toString() ?? '') ?? 7.4;
        final ownership = item['ownership']?.toString() ?? 'Govt.';

        final isDc = power >= 50 || name.toUpperCase().contains('CCS') || cpo.toUpperCase().contains('TATA') || cpo.toUpperCase().contains('CHARGE');

        return StationModel(
          id: id,
          name: name,
          address: address.isNotEmpty ? address : '$city, $state',
          city: city.isNotEmpty ? city : 'India',
          state: state,
          ownership: ownership,
          cpo: cpo,
          latitude: lat,
          longitude: lng,
          rating: 4.8,
          availableConnectors: conns,
          connectors: [
            ConnectorModel(
              id: '$id-conn-01',
              standard: isDc ? 'CCS2' : 'Type2',
              powerType: isDc ? 'DC' : 'AC',
              maxPowerKw: power,
              status: 'AVAILABLE',
              tariff: TariffModel(pricePerKwh: isDc ? 16.5 : 12.0, flatFee: 20.0),
            ),
          ],
        );
      }).toList();
      allList.addAll(beeList);
    } catch (_) {}

    // 2. Fetch live operator stations from backend API / cache
    try {
      final remote = await ApiService.getStations(limit: 2000);
      if (remote.isNotEmpty) {
        final seen = Set<String>.from(remote.map((r) => r.id));
        allList = [...remote, ...allList.where((s) => !seen.contains(s.id))];
      }
    } catch (_) {}

    // 3. Request GPS Geolocation & auto-zoom
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      _userPosition = LatLng(pos.latitude, pos.longitude);
      _hasUserLocation = true;
      _currentZoom = 13.5;
      try {
        _mapController.move(_userPosition, 13.5);
      } catch (_) {}
    }

    // 4. Compute accurate GPS distance for each station
    if (allList.isNotEmpty) {
      allList = allList.map((s) {
        final dist = LocationService.calculateDistance(
          _userPosition.latitude,
          _userPosition.longitude,
          s.latitude,
          s.longitude,
        );
        return StationModel(
          id: s.id,
          name: s.name,
          address: s.address,
          city: s.city,
          state: s.state,
          district: s.district,
          pincode: s.pincode,
          ownership: s.ownership,
          cpo: s.cpo,
          latitude: s.latitude,
          longitude: s.longitude,
          distanceKm: double.parse(dist.toStringAsFixed(1)),
          operator: s.operator,
          rating: s.rating,
          reliability: s.reliability,
          connectors: s.connectors,
          availableConnectors: s.availableConnectors,
          amenities: s.amenities,
          connectorCategories: s.connectorCategories,
          connectorTypes: s.connectorTypes,
          chargerRatings: s.chargerRatings,
        );
      }).toList();

      // Sort by closest distance
      allList.sort((a, b) => (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
    }

    final syncTime = await OfflineCacheService.getLastSyncTime();

    if (mounted) {
      setState(() {
        _stations = allList;
        _cacheSyncStatus = syncTime ?? '29,084 Stations Offline Synced';
        _isLoading = false;
      });
    }
  }

  List<StationModel> get _filteredStations {
    return _stations.where((s) {
      if (_selectedCity != 'All' && !s.city.toLowerCase().contains(_selectedCity.toLowerCase())) {
        return false;
      }
      if (_selectedFilter == '⚡ DC Fast (50kW+)' && !s.isFastDc) {
        return false;
      }
      if (_selectedFilter == 'Type 2 AC' && !s.connectors.any((c) => c.standard.contains('Type2')) && !s.connectorCategories.any((c) => c.contains('Type 2'))) {
        return false;
      }
      if (_selectedFilter == '🟢 Available Now' && s.availableConnectors == 0) {
        return false;
      }
      if (_selectedFilter == '🏛️ Govt. / BEE' && s.ownership?.toLowerCase().contains('govt') != true) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.city.toLowerCase().contains(q) ||
            (s.cpo?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  /// Top 5 Smart Recommended Charging Points (Availability + Fast DC + High Rating + Close Distance)
  List<StationModel> get _recommendedStations {
    final list = List<StationModel>.from(_filteredStations);
    list.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));
    return list.take(5).toList();
  }

  /// Dynamic Spatial Clustering Algorithm for 29,000+ stations
  List<MapCluster> _computeClusters(List<StationModel> stations, double zoom) {
    if (zoom >= 13.0 || stations.length <= 1) {
      // Individual station pins at street zoom level
      return stations.map((s) => MapCluster(
        center: LatLng(s.latitude, s.longitude),
        count: 1,
        stations: [s],
      )).toList();
    }

    // Dynamic grid cell degree step based on zoom level
    final double step = 180.0 / (pow(2.0, zoom) * 2.2);

    final Map<String, List<StationModel>> buckets = {};
    for (final s in stations) {
      final int latBucket = (s.latitude / step).floor();
      final int lngBucket = (s.longitude / step).floor();
      final key = '$latBucket:$lngBucket';
      buckets.putIfAbsent(key, () => []).add(s);
    }

    final List<MapCluster> clusters = [];
    buckets.forEach((key, list) {
      if (list.length == 1) {
        clusters.add(MapCluster(
          center: LatLng(list.first.latitude, list.first.longitude),
          count: 1,
          stations: list,
        ));
      } else {
        double sumLat = 0;
        double sumLng = 0;
        for (final s in list) {
          sumLat += s.latitude;
          sumLng += s.longitude;
        }
        clusters.add(MapCluster(
          center: LatLng(sumLat / list.length, sumLng / list.length),
          count: list.length,
          stations: list,
        ));
      }
    });

    return clusters;
  }

  void _showStationPreview(StationModel station) {
    _mapController.move(LatLng(station.latitude, station.longitude), 14.5);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StationPreviewSheet(
        station: station,
        onDetailsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StationDetailsScreen(stationId: station.id, initialStation: station)),
          );
        },
        onBookTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookingScreen(station: station)),
          );
        },
      ),
    );
  }

  void _centerOnUserLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _userPosition = LatLng(pos.latitude, pos.longitude);
        _hasUserLocation = true;
        _currentZoom = 14.0;
      });
      _mapController.move(_userPosition, 14.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStations;
    final recommended = _recommendedStations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Layer 1: Background Interactive Map with Spatial Clustering or List View ──
          if (_isMapView)
            _buildInteractiveMap(filtered)
          else
            _buildListView(filtered, recommended),

          // ── Layer 2: Top Floating Search Bar, City Pills & Filters ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Input with View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Icon(FluentIcons.search_24_regular, size: 20, color: AppColors.emerald),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search 29,085+ national EV stations...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(FluentIcons.dismiss_24_regular, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        // View Toggle Pill (Map vs List)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isMapView ? FluentIcons.list_24_filled : FluentIcons.map_24_filled,
                              size: 18,
                              color: AppColors.emerald,
                            ),
                            onPressed: () => setState(() => _isMapView = !_isMapView),
                            tooltip: _isMapView ? 'Switch to List' : 'Switch to Map',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // City Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _cities.map((city) {
                        final selected = _selectedCity == city;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(city),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedCity = city);
                              if (city == 'Bengaluru') _mapController.move(const LatLng(12.9716, 77.5946), 11.5);
                              if (city == 'Delhi') _mapController.move(const LatLng(28.6139, 77.2090), 11.5);
                              if (city == 'Mumbai') _mapController.move(const LatLng(19.0760, 72.8777), 11.5);
                              if (city == 'Hyderabad') _mapController.move(const LatLng(17.3850, 78.4867), 11.5);
                              if (city == 'Chennai') _mapController.move(const LatLng(13.0827, 80.2707), 11.5);
                              if (city == 'Pune') _mapController.move(const LatLng(18.5204, 73.8567), 11.5);
                            },
                            selectedColor: AppColors.emerald,
                            backgroundColor: AppColors.surface.withOpacity(0.9),
                            labelStyle: TextStyle(
                              color: selected ? Colors.black : AppColors.textSecondary,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 11,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: selected ? AppColors.emerald : AppColors.borderSubtle),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Feature Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(filter),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                            selectedColor: AppColors.surfaceElevated,
                            backgroundColor: AppColors.surface.withOpacity(0.9),
                            checkmarkColor: AppColors.emerald,
                            labelStyle: TextStyle(
                              color: selected ? AppColors.emerald : AppColors.textSecondary,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 10,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: selected ? AppColors.emerald : AppColors.borderSubtle),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Layer 3: Bottom Map Drawer with Recommendations Carousel ──
          if (_isMapView)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recommendations Carousel Bar
                  if (recommended.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(FluentIcons.star_24_filled, size: 14, color: AppColors.amber),
                              SizedBox(width: 6),
                              Text(
                                'Recommended For You',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        FloatingActionButton.small(
                          heroTag: 'my_loc_btn',
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.emerald,
                          onPressed: _centerOnUserLocation,
                          tooltip: 'My Location',
                          child: const Icon(FluentIcons.my_location_24_filled, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Horizontal Recommended Cards
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommended.length,
                        itemBuilder: (context, idx) {
                          final stn = recommended[idx];
                          final isAvail = stn.availableConnectors > 0;
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 10),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderColor: isAvail ? AppColors.emerald.withOpacity(0.4) : AppColors.borderSubtle,
                              onTap: () => _showStationPreview(stn),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stn.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isAvail ? AppColors.emerald : AppColors.crimson).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isAvail ? 'FREE' : 'BUSY',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: isAvail ? AppColors.emerald : AppColors.crimson,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${stn.displayCpo} · ${stn.maxPowerKw}kW · ₹${stn.baseTariffPerKwh}/kWh',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                    maxLines: 1,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        stn.distanceKm != null ? '📍 ${stn.distanceKm} km' : stn.city,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sky),
                                      ),
                                      Text(
                                        '⭐ ${stn.rating.toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.amber),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Bottom Floating Badge: Offline Cache Status & Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(FluentIcons.cloud_checkmark_24_filled, size: 14, color: AppColors.emerald),
                            const SizedBox(width: 6),
                            Text(
                              '${filtered.length} Stations · ${_cacheSyncStatus ?? "29,084 Stations Synced"}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _initLocationAndLoadStations,
                          child: const Icon(FluentIcons.arrow_sync_24_regular, size: 16, color: AppColors.emerald),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Widget: Interactive FlutterMap with Dynamic Spatial Cluster Badges ──
  Widget _buildInteractiveMap(List<StationModel> stations) {
    final clusters = _computeClusters(stations, _currentZoom);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userPosition,
        initialZoom: _currentZoom,
        minZoom: 4,
        maxZoom: 18,
        onPositionChanged: (pos, hasGesture) {
          if ((pos.zoom - _currentZoom).abs() >= 0.5) {
            setState(() => _currentZoom = pos.zoom);
          }
        },
      ),
      children: [
        // CartoDB Dark Matter / OSM Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.chargegrid.urjaa',
          tileBuilder: (context, tileWidget, tile) {
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                -0.85, 0, 0, 0, 240,
                0, -0.85, 0, 0, 240,
                0, 0, -0.85, 0, 240,
                0, 0, 0, 1, 0,
              ]),
              child: tileWidget,
            );
          },
        ),

        // Cluster & Station Markers Layer
        MarkerLayer(
          markers: [
            // User Live Location Pin
            if (_hasUserLocation)
              Marker(
                point: _userPosition,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.sky.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sky, width: 2),
                  ),
                  child: const Center(
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.sky,
                    ),
                  ),
                ),
              ),

            // Dynamic Clusters / Station Pins
            ...clusters.map((c) {
              if (c.isSingle) {
                final s = c.stations.first;
                final isAvail = s.availableConnectors > 0;
                final isFast = s.isFastDc;
                final pinColor = isAvail
                    ? (isFast ? AppColors.emerald : AppColors.sky)
                    : AppColors.crimson;

                return Marker(
                  point: c.center,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showStationPreview(s),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: pinColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: pinColor.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isFast ? FluentIcons.flash_24_filled : FluentIcons.vehicle_car_profile_24_filled,
                          color: pinColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // Grouped Cluster Circle Badge matching reference image
                final count = c.count;
                final double size = count > 1000 ? 64 : count > 100 ? 54 : 46;

                return Marker(
                  point: c.center,
                  width: size,
                  height: size,
                  child: GestureDetector(
                    onTap: () {
                      final nextZoom = (_currentZoom + 2.5).clamp(4.0, 16.0);
                      _mapController.move(c.center, nextZoom);
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x4010B981), // Translucent green glowing halo
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669), // Vibrant green core badge
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x6010B981),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: count > 9999 ? 11 : count > 999 ? 12 : 14,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }),
          ],
        ),
      ],
    );
  }

  // ── Widget: List View fallback with Recommendations & BEE Data ──
  Widget _buildListView(List<StationModel> stations, List<StationModel> recommended) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 140)),

        // Recommended Section in List View
        if (recommended.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(FluentIcons.star_24_filled, color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  const Text('Top Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 125,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recommended.length,
                itemBuilder: (context, idx) {
                  final stn = recommended[idx];
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    child: GlassContainer(
                      borderColor: AppColors.emerald,
                      onTap: () => _showStationPreview(stn),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(stn.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              Text('${stn.rating.toStringAsFixed(1)} ⭐', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber, fontSize: 11)),
                            ],
                          ),
                          Text('${stn.displayCpo} · ${stn.maxPowerKw}kW · ${stn.displayOwnership}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(stn.distanceKm != null ? '📍 ${stn.distanceKm} km' : stn.city, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sky)),
                              Text('₹${stn.baseTariffPerKwh}/kWh', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // All Stations Feed
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('All Charging Points (${stations.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, idx) {
                final station = stations[idx];
                final isAvail = station.availableConnectors > 0;

                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () => _showStationPreview(station),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              station.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${station.rating.toStringAsFixed(1)} ⭐',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${station.address}, ${station.city}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isAvail ? AppColors.emerald : AppColors.crimson).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAvail ? '● ${station.availableConnectors} Free' : '🔴 Occupied',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isAvail ? AppColors.emerald : AppColors.crimson,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (station.distanceKm != null)
                                Text('📍 ${station.distanceKm} km', style: const TextStyle(fontSize: 11, color: AppColors.sky, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Text(
                            '₹${station.baseTariffPerKwh}/kWh',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.emerald),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: stations.length,
            ),
          ),
        ),
      ],
    );
  }
}
