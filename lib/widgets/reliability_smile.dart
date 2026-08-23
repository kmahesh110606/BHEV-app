import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';

/// Reliability Smile index widget displaying live uptime and completion scores
class ReliabilitySmile extends StatelessWidget {
  final ReliabilityInfo reliability;
  final double rating;

  const ReliabilitySmile({
    super.key,
    required this.reliability,
    this.rating = 4.8,
  });

  @override
  Widget build(BuildContext context) {
    final score = reliability.score;
    final color = score >= 90
        ? AppColors.emerald
        : score >= 75
            ? AppColors.amber
            : AppColors.crimson;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(FluentIcons.shield_checkmark_24_filled, color: color, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Reliability Smile Index',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              color: color,
            ),
          ),
          const SizedBox(height: 12),

          // Sub-metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricChip('Hardware Uptime', reliability.uptime),
              _metricChip('Success Rate', reliability.completionRate),
              _metricChip('Driver Rating', '${rating.toStringAsFixed(1)} ⭐'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
