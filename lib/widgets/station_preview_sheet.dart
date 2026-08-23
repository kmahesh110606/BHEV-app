import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';
import '../services/navigation_launcher.dart';

/// Modal sheet showing station preview with connector statuses and quick navigation
class StationPreviewSheet extends StatelessWidget {
  final StationModel station;
  final VoidCallback onDetailsTap;
  final VoidCallback onBookTap;

  const StationPreviewSheet({
    super.key,
    required this.station,
    required this.onDetailsTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
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
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.02,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${station.address}, ${station.city}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.star_24_filled, color: AppColors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      station.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Connector Specs Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: station.connectors.map((c) {
              final isAvail = c.isAvailable;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isAvail ? AppColors.emerald.withOpacity(0.4) : AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.flash_24_filled,
                      size: 14,
                      color: isAvail ? AppColors.emerald : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${c.standard} · ${c.maxPowerKw.toInt()}kW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAvail ? AppColors.textPrimary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Pricing Strip
          Row(
            children: [
              Text(
                '₹${station.baseTariffPerKwh}/kWh',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+ ₹${station.connectionFlatFee.toInt()} flat fee',
                style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(FluentIcons.navigation_24_filled),
                onPressed: () => NavigationLauncher.openMapDirections(
                  station.latitude,
                  station.longitude,
                  station.name,
                ),
                tooltip: 'Get Directions',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetailsTap,
                  child: const Text('View Station Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onBookTap,
                  child: const Text('Reserve Slot'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
