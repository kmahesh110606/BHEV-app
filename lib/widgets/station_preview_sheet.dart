import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../models/station.dart';
import '../screens/station_details.dart';
import 'reliability_smile.dart';

class StationPreviewSheet extends StatelessWidget {
  final Station station;
  const StationPreviewSheet({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final reliability = StationReliability.fromStation(station);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: const Color(0xFF65D7A5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(FluentIcons.flash_24_regular,
                        color: Color(0xFF85EAB7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.12)),
                        const SizedBox(height: 5),
                        Text('${station.address}, ${station.city}',
                            style: const TextStyle(
                                color: Color(0xFF9BA8BA), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ReliabilitySmile(station: station, showSignals: true),
              const SizedBox(height: 14),
              _QuickFacts(station: station),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StationDetailsScreen(
                                stationId: station.id,
                                initialStation: station)));
                  },
                  icon: Icon(reliability.canBook
                      ? FluentIcons.calendar_ltr_24_regular
                      : FluentIcons.info_24_regular),
                  label: Text(station.isDemo
                      ? 'See connectors & booking flow'
                      : reliability.canBook
                          ? 'See connectors & book'
                          : 'See station details'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text(
                      'Confidence is based on live connector status and operator signals.',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.45)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickFacts extends StatelessWidget {
  final Station station;
  const _QuickFacts({required this.station});

  @override
  Widget build(BuildContext context) {
    final connectorTypes = station.connectors
        .map((item) => item.standard)
        .where((item) => item.isNotEmpty)
        .toSet()
        .join(' · ');
    return Row(
      children: [
        Expanded(
            child: _Fact(
                icon: FluentIcons.plug_connected_24_regular,
                value: '${station.availableConnectors}',
                label: 'available')),
        const SizedBox(width: 9),
        Expanded(
            child: _Fact(
                icon: FluentIcons.star_24_filled,
                value: station.rating > 0
                    ? station.rating.toStringAsFixed(1)
                    : 'New',
                label: 'driver rating')),
        const SizedBox(width: 9),
        Expanded(
            child: _Fact(
                icon: FluentIcons.flash_24_regular,
                value: connectorTypes.isEmpty
                    ? 'EVSE'
                    : connectorTypes.split(' · ').first,
                label: 'connector')),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Fact({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: const Color(0xFF8ADDB8)),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF8794A8))),
        ]),
      );
}
