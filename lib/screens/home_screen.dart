import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../data/demo_stations.dart';
import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/reliability_smile.dart';
import '../widgets/station_preview_sheet.dart';
import '../widgets/mappls_station_map.dart';

final apiService = ApiService(backendBase);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Station>> _stations;
  final _searchController = TextEditingController();
  bool _availableOnly = false;
  bool _fastChargeOnly = false;

  @override
  void initState() {
    super.initState();
    _stations = apiService.fetchStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _stations = apiService.fetchStations());
    await _stations;
  }

  List<Station> _filterStations(List<Station> stations) {
    final query = _searchController.text.trim().toLowerCase();
    return stations.where((station) {
      final haystack =
          '${station.name} ${station.address} ${station.city} ${station.operatorName}'
              .toLowerCase();
      final fastCharge =
          station.connectors.any((connector) => connector.maxPowerKw >= 50);
      return (query.isEmpty || haystack.contains(query)) &&
          (!_availableOnly || station.availableConnectors > 0) &&
          (!_fastChargeOnly || fastCharge);
    }).toList();
  }

  void _showPreview(Station station) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
            heightFactor: 0.72, child: StationPreviewSheet(station: station)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: FutureBuilder<List<Station>>(
            future: _stations,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const _DiscoveryLoading();
              final liveStations =
                  snapshot.hasError ? const <Station>[] : snapshot.data ?? const <Station>[];
              final usingDemo = snapshot.hasError || liveStations.isEmpty;
              final stations =
                  _filterStations(usingDemo ? demoStations : liveStations);
              return Stack(
                children: [
                  Positioned.fill(
                    child: Stack(
                      children: [
                        MapplsStationMap(
                          stations: stations,
                          onStationTap: _showPreview,
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF08121E)
                                      .withValues(alpha: 0.32),
                                  const Color(0xFF0B0F17)
                                      .withValues(alpha: 0.98)
                                ],
                                stops: const [0, 0.43],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _DiscoveryHeader(onRefresh: _reload),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _SearchBox(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onClear: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: _DiscoveryFilters(
                          availableOnly: _availableOnly,
                          fastChargeOnly: _fastChargeOnly,
                          onAvailable: (value) =>
                              setState(() => _availableOnly = value),
                          onFast: (value) =>
                              setState(() => _fastChargeOnly = value),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _reload,
                          color: const Color(0xFF65D7A5),
                          backgroundColor: const Color(0xFF17202E),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 84, 16, 24),
                            children: [
                              _ResultsHeading(
                                  count: stations.length, isDemo: usingDemo),
                              const SizedBox(height: 10),
                              if (usingDemo) ...[
                                const _DemoFeedBanner(),
                                const SizedBox(height: 10),
                              ],
                              if (stations.isEmpty)
                                _EmptyState(onClear: () {
                                  _searchController.clear();
                                  setState(() {
                                    _availableOnly = false;
                                    _fastChargeOnly = false;
                                  });
                                })
                              else
                                ...stations.map((station) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _StationSearchCard(
                                          station: station,
                                          onTap: () => _showPreview(station)),
                                    )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _DiscoveryHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DiscoveryHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFF65D7A5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: const Color(0xFF65D7A5).withValues(alpha: 0.27))),
            child: const Icon(FluentIcons.flash_24_regular,
                color: Color(0xFF83EAB3), size: 21),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CHARGEGRID',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              Text('DISCOVER • LIVE OPERATOR FEEDS',
                  style: TextStyle(
                      color: Color(0xFF91A0B4),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7)),
            ]),
          ),
          GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: 13,
            child: IconButton(
                onPressed: onRefresh,
                icon: const Icon(FluentIcons.arrow_sync_24_regular,
                    color: Color(0xFF9AECC1), size: 20),
                tooltip: 'Refresh station status'),
          ),
        ],
      );
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBox(
      {required this.controller,
      required this.onChanged,
      required this.onClear});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search city, station or operator',
          prefixIcon: const Icon(FluentIcons.search_24_regular,
              color: Color(0xFF8DF0BD)),
          suffixIcon: controller.text.isEmpty
              ? const Icon(FluentIcons.location_24_regular,
                  color: Color(0xFF9CA9BB))
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(FluentIcons.dismiss_24_regular,
                      color: Color(0xFFB5C0D0))),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      );
}

class _DiscoveryFilters extends StatelessWidget {
  final bool availableOnly;
  final bool fastChargeOnly;
  final ValueChanged<bool> onAvailable;
  final ValueChanged<bool> onFast;
  const _DiscoveryFilters(
      {required this.availableOnly,
      required this.fastChargeOnly,
      required this.onAvailable,
      required this.onFast});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _FilterPill(
              label: 'Available now',
              icon: FluentIcons.checkmark_circle_16_filled,
              selected: availableOnly,
              onSelected: onAvailable),
          const SizedBox(width: 8),
          _FilterPill(
              label: 'Fast charge',
              icon: FluentIcons.flash_16_filled,
              selected: fastChargeOnly,
              onSelected: onFast),
          const SizedBox(width: 8),
          const _LivePill(),
        ]),
      );
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterPill(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) => FilterChip(
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        avatar: Icon(icon,
            size: 15,
            color:
                selected ? const Color(0xFF072218) : const Color(0xFF9AA9BC)),
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFF072218)
                    : const Color(0xFFD6DEE9),
                fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF121B29).withValues(alpha: 0.85),
        selectedColor: const Color(0xFF65D7A5),
        side: BorderSide(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.10)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}

class _LivePill extends StatelessWidget {
  const _LivePill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
            color: const Color(0xFF101923).withValues(alpha: 0.83),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          _PulseDot(),
          SizedBox(width: 6),
          Text('LIVE',
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF91EFC0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6)),
        ]),
      );
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) => Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
          color: Color(0xFF69D89F), shape: BoxShape.circle));
}

class _ResultsHeading extends StatelessWidget {
  final int count;
  final bool isDemo;
  const _ResultsHeading({required this.count, required this.isDemo});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(
                isDemo
                    ? '$count sample charging points'
                    : '$count charging point${count == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800))),
        const Text('Tap a card for booking confidence',
            style: TextStyle(fontSize: 10, color: Color(0xFF9CA9BA))),
      ]);
}

class _DemoFeedBanner extends StatelessWidget {
  const _DemoFeedBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF75B9FF).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: const Color(0xFF75B9FF).withValues(alpha: 0.22)),
        ),
        child: const Row(children: [
          Icon(FluentIcons.info_16_regular, color: Color(0xFF9DCEFF), size: 16),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  'Preview data is shown while the live operator feed is empty.',
                  style: TextStyle(color: Color(0xFFC5E3FF), fontSize: 11))),
        ]),
      );
}

class _StationSearchCard extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;
  const _StationSearchCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final reliability = StationReliability.fromStation(station);
    final power = station.connectors.fold<double>(
        0,
        (best, connector) =>
            connector.maxPowerKw > best ? connector.maxPowerKw : best);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF121B29).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(23),
            border:
                Border.all(color: reliability.color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: const Color(0xFF65D7A5).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(FluentIcons.flash_24_regular,
                      color: Color(0xFF83EAB3))),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(station.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${station.address}, ${station.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9DA9B9))),
                  ])),
              const Icon(FluentIcons.chevron_right_24_regular,
                  color: Color(0xFF9EACBD), size: 19),
            ]),
            const SizedBox(height: 12),
            ReliabilitySmile(station: station, compact: true),
            const SizedBox(height: 9),
            _ChargerStatusBand(station: station),
            const SizedBox(height: 11),
            Row(children: [
              _DetailChip(
                  icon: FluentIcons.plug_connected_20_regular,
                  label: '${station.availableConnectors} open',
                  color: reliability.color),
              const SizedBox(width: 8),
              _DetailChip(
                  icon: FluentIcons.flash_20_regular,
                  label: power > 0
                      ? '${power.toStringAsFixed(0)} kW max'
                      : 'Power pending',
                  color: const Color(0xFF9DD5FF)),
              const Spacer(),
              Flexible(
                  child: Text(
                      station.isMock ? 'CPO preview' : station.operatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8C99AB)))),
            ]),
          ]),
        ),
      ),
      );
  }
}

class _ChargerStatusBand extends StatelessWidget {
  final Station station;
  const _ChargerStatusBand({required this.station});

  @override
  Widget build(BuildContext context) {
    final state = station.chargerStatus == 'UNKNOWN'
        ? (station.availableConnectors > 0 ? 'FREE' : 'BUSY')
        : station.chargerStatus;
    final color = switch (state.toUpperCase()) {
      'FREE' || 'AVAILABLE' => const Color(0xFF65D7A5),
      'BOOKED' || 'QUEUED' => const Color(0xFF88C9FF),
      'EMERGENCY' => const Color(0xFFFF8F8A),
      'CHARGING' => const Color(0xFFFFB15C),
      _ => const Color(0xFF94A0B1),
    };
    final free = station.chargerSummary['available'] ??
        station.availableConnectors;
    final booked = station.chargerSummary['booked'] ?? 0;
    final charging = station.chargerSummary['charging'] ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .18))),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text('$state • $free free • $booked booked • $charging charging',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w800))),
        Text(
            station.nextAvailableMins == 0
                ? 'now'
                : '${station.nextAvailableMins}m',
            style: const TextStyle(color: Color(0xFF9AA8BA), fontSize: 10))
      ]),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DetailChip(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700))
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: const Color(0xFF121B29).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          const Icon(FluentIcons.search_info_24_regular,
              size: 34, color: Color(0xFF94A4B9)),
          const SizedBox(height: 10),
          const Text('No stations match those filters',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Try a different city or widen your availability filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9AA8BA), fontSize: 12)),
          const SizedBox(height: 12),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ]),
      );
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();
  @override
  Widget build(BuildContext context) => const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Color(0xFF65D7A5)),
        SizedBox(height: 16),
        Text('Loading live charging points...',
            style: TextStyle(color: Color(0xFFB7C1CE)))
      ]));
}

