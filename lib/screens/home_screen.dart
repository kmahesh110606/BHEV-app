import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/station_preview_sheet.dart';
import 'station_details.dart';
import 'booking_screen.dart';

/// Discover screen with city filter pills, connector search, and interactive station cards
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StationModel> _stations = [];
  bool _isLoading = true;
  String _selectedCity = 'All';
  String _selectedFilter = 'All'; // All, DC Fast, Type 2, Available

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
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    final pos = await LocationService.getCurrentPosition();
    List<StationModel> list;

    if (pos != null) {
      list = await ApiService.getNearbyStations(latitude: pos.latitude, longitude: pos.longitude);
    } else {
      list = await ApiService.getStations(
        city: _selectedCity == 'All' ? null : _selectedCity,
        search: _searchController.text.trim(),
      );
    }

    setState(() {
      _stations = list;
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
      body: RefreshIndicator(
        onRefresh: _loadStations,
        color: AppColors.emerald,
        child: CustomScrollView(
          slivers: [
            // Search Bar & Filters Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Input
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search stations, cities, or highways...',
                        prefixIcon: const Icon(FluentIcons.search_24_regular, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(FluentIcons.dismiss_24_regular, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // City Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _cities.map((city) {
                          final selected = _selectedCity == city;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(city),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _selectedCity = city);
                                _loadStations();
                              },
                              selectedColor: AppColors.emerald,
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                color: selected ? Colors.black : AppColors.textSecondary,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(color: selected ? AppColors.emerald : AppColors.borderSubtle),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Feature Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final selected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedFilter = filter),
                              selectedColor: AppColors.surfaceElevated,
                              backgroundColor: AppColors.surface,
                              checkmarkColor: AppColors.emerald,
                              labelStyle: TextStyle(
                                color: selected ? AppColors.emerald : AppColors.textSecondary,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 11,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

            // Station Cards List
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.emerald),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.vehicle_car_profile_24_regular, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text(
                        'No stations found matching filters',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCity = 'All';
                            _selectedFilter = 'All';
                            _searchController.clear();
                          });
                          _loadStations();
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final station = filtered[idx];
                      final isAvail = station.availableConnectors > 0;

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 14),
                        onTap: () => _showStationPreview(station),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Top: Name & Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        station.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.02,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${station.city} · ${station.operator?.name ?? 'CPO Network'}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(FluentIcons.star_24_filled, color: AppColors.amber, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        station.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Connectors Strip
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAvail ? AppColors.emerald.withOpacity(0.15) : AppColors.crimson.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isAvail ? AppColors.emerald.withOpacity(0.3) : AppColors.crimson.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    isAvail ? '● ${station.availableConnectors}/${station.connectors.length} Available' : '🔴 All Bays Occupied',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isAvail ? AppColors.emerald : AppColors.crimson,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '⚡ Up to ${station.maxPowerKw} kW',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sky),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Bottom Strip: Pricing & Reserve Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${station.baseTariffPerKwh}/kWh',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emerald,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BookingScreen(station: station)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: const Text('Book Slot', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
