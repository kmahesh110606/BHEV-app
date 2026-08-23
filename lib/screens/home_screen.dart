import 'package:flutter/material.dart';
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

/// Discover screen with full interactive map, offline caching badge, and search filter pills
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
  String _selectedFilter = 'All'; // All, DC Fast, Type 2, Available
  String? _cacheSyncStatus;
  LatLng _mapCenter = const LatLng(12.9716, 77.5946); // Bengaluru default
  double _mapZoom = 11.5;

  final List<String> _cities = ['All', 'Bengaluru', 'Delhi', 'Mumbai', 'Hyderabad', 'Chennai'];
  final List<String> _filters = ['All', '⚡ DC Fast (50kW+)', 'Type 2 AC', '🟢 Available Now'];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    final pos = await LocationService.getCurrentPosition();
    List<StationModel> list;

    if (pos != null) {
      _mapCenter = LatLng(pos.latitude, pos.longitude);
      list = await ApiService.getNearbyStations(latitude: pos.latitude, longitude: pos.longitude);
    } else {
      list = await ApiService.getStations(
        city: _selectedCity == 'All' ? null : _selectedCity,
        search: _searchController.text.trim(),
      );
    }

    if (list.isNotEmpty && pos == null) {
      _mapCenter = LatLng(list.first.latitude, list.first.longitude);
    }

    final syncTime = await OfflineCacheService.getLastSyncTime();

    setState(() {
      _stations = list;
      _cacheSyncStatus = syncTime;
      _isLoading = false;
    });
  }

  List<StationModel> get _filteredStations {
    return _stations.where((s) {
      if (_selectedCity != 'All' && !s.city.toLowerCase().contains(_selectedCity.toLowerCase())) {
        return false;
      }
      if (_selectedFilter == '⚡ DC Fast (50kW+)' && !s.isFastDc) {
        return false;
      }
      if (_selectedFilter == 'Type 2 AC' && !s.connectors.any((c) => c.standard.contains('Type2'))) {
        return false;
      }
      if (_selectedFilter == '🟢 Available Now' && s.availableConnectors == 0) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        return s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q) || s.city.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _showStationPreview(StationModel station) {
    _mapController.move(LatLng(station.latitude, station.longitude), 14.0);
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background: Interactive Map View or List View ──
          if (_isMapView)
            _buildInteractiveMap(filtered)
          else
            _buildListView(filtered),

          // ── Top Floating Overlay: Search, Filters & Cache Badge ──
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
                              hintText: 'Search 10,000+ national EV stations...',
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
                              _loadStations();
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

          // ── Bottom Floating Badge: Offline Cache Status & Count ──
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(FluentIcons.cloud_checkmark_24_filled, size: 14, color: AppColors.emerald),
                      const SizedBox(width: 6),
                      Text(
                        '${filtered.length} Stations · ${_cacheSyncStatus ?? "Offline Cached"}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.emerald,
                  onPressed: _loadStations,
                  child: const Icon(FluentIcons.arrow_sync_24_regular, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget: Interactive FlutterMap with Dark Tiles & Custom Pins ──
  Widget _buildInteractiveMap(List<StationModel> stations) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _mapCenter,
        initialZoom: _mapZoom,
        minZoom: 4,
        maxZoom: 18,
      ),
      children: [
        // CartoDB Dark Matter / OSM Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.chargegrid.urjaa',
          tileBuilder: (context, tileWidget, tile) {
            // Apply Obsidian dark invert matrix filter for seamless theme match
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

        // Station Markers Layer
        MarkerLayer(
          markers: stations.map((s) {
            final isAvail = s.availableConnectors > 0;
            final isFast = s.isFastDc;
            final pinColor = isAvail
                ? (isFast ? AppColors.emerald : AppColors.sky)
                : AppColors.crimson;

            return Marker(
              point: LatLng(s.latitude, s.longitude),
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
          }).toList(),
        ),
      ],
    );
  }

  // ── Widget: List View fallback ──
  Widget _buildListView(List<StationModel> stations) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
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
                          Text(
                            isAvail ? '● ${station.availableConnectors}/${station.connectors.length} Free' : '🔴 Occupied',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvail ? AppColors.emerald : AppColors.crimson,
                            ),
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
