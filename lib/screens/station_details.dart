import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../services/navigation_launcher.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/reliability_smile.dart';
import 'booking_screen.dart';

/// Full Station Profile & Connector Pedestals details screen
class StationDetailsScreen extends StatefulWidget {
  final String stationId;
  final StationModel? initialStation;

  const StationDetailsScreen({
    super.key,
    required this.stationId,
    this.initialStation,
  });

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  StationModel? _station;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _station = widget.initialStation;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_station == null) setState(() => _isLoading = true);
    final data = await ApiService.getStationDetails(widget.stationId);
    if (data != null && mounted) {
      setState(() {
        _station = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _station;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          s?.name ?? 'Station Details',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (s != null)
            IconButton(
              icon: const Icon(FluentIcons.navigation_24_filled, color: AppColors.emerald),
              onPressed: () => NavigationLauncher.openMapDirections(
                s.latitude,
                s.longitude,
                s.name,
              ),
              tooltip: 'Directions',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading || s == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station Header Card
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s.operator?.name ?? 'URJAA Partner',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(FluentIcons.star_24_filled, color: AppColors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  s.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.02),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(FluentIcons.location_24_regular, size: 16, color: AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${s.address}, ${s.city} (${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)})',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reliability Smile Index
                  if (s.reliability != null) ReliabilitySmile(reliability: s.reliability!, rating: s.rating),
                  const SizedBox(height: 20),

                  // Commercial Tariff Breakdown
                  const Text('Tariff & Pricing Specs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Energy Rate', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              const SizedBox(height: 4),
                              Text('₹${s.baseTariffPerKwh}/kWh',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Connection Fee', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              const SizedBox(height: 4),
                              Text('₹${s.connectionFlatFee.toInt()}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pedestals / Chargers List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Charger Pedestals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('${s.availableConnectors}/${s.connectors.length} Free',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Column(
                    children: s.connectors.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final c = entry.value;
                      final isAvail = c.isAvailable;
                      final statusColor = isAvail
                          ? AppColors.emerald
                          : c.isCharging
                              ? AppColors.sky
                              : AppColors.crimson;

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(FluentIcons.flash_24_filled, color: statusColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bay ${idx + 1} · ${c.standard}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c.powerType} Fast Charger · Up to ${c.maxPowerKw.toInt()} kW',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                c.status,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Amenities
                  const Text('On-Site Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: s.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(a, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Bottom Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookingScreen(station: s)),
                      ),
                      child: const Text('Reserve Charging Slot'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
