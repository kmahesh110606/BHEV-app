import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../widgets/reliability_smile.dart';
import 'sessions_screen.dart';

final api = ApiService(backendBase);

class StationDetailsScreen extends StatelessWidget {
  final String stationId;
  final Station? initialStation;
  const StationDetailsScreen(
      {super.key, required this.stationId, this.initialStation});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<Station>(
          future: initialStation == null
              ? api.fetchStationDetails(stationId)
              : Future<Station>.value(initialStation),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF65D7A5)));
            if (snapshot.hasError)
              return _DetailsError(error: snapshot.error.toString());
            return _StationDetailBody(station: snapshot.data!);
          },
        ),
      );
}

class _StationDetailBody extends StatelessWidget {
  final Station station;
  const _StationDetailBody({required this.station});

  @override
  Widget build(BuildContext context) {
    final reliability = StationReliability.fromStation(station);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 210,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(FluentIcons.arrow_left_24_regular)),
          actions: [
            IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Saved stations will be available in your account soon.'))),
                icon: const Icon(FluentIcons.bookmark_24_regular)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _StationHero(station: station),
            titlePadding: const EdgeInsets.fromLTRB(64, 0, 56, 15),
            title: Text(station.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)])),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(station.operatorName.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF7EE5AD),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7)),
              const SizedBox(height: 5),
              Text('${station.address}, ${station.city}',
                  style:
                      const TextStyle(color: Color(0xFFA7B3C4), fontSize: 13)),
              const SizedBox(height: 18),
              ReliabilitySmile(station: station, showSignals: true),
              const SizedBox(height: 16),
              _StationSnapshot(station: station),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openGoogleNavigation(context, station),
                  icon: const Icon(FluentIcons.navigation_24_regular),
                  label: const Text('Route with Google Maps'),
                ),
              ),
              const SizedBox(height: 24),
              const _MockEvStatusCard(),
              const SizedBox(height: 18),
              const _SectionLabel(
                  title: 'Choose a connector',
                  subtitle: 'Live status is checked before reservation'),
              const SizedBox(height: 12),
              if (station.connectors.isEmpty)
                const _NoConnectors()
              else
                ...station.connectors.map((connector) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ConnectorCard(
                          station: station, connector: connector),
                    )),
              const SizedBox(height: 16),
              _ReliabilityNote(reliability: reliability),
            ]),
          ),
        ),
      ],
    );
  }
}

Future<void> _openGoogleNavigation(
    BuildContext context, Station station) async {
  final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.lat},${station.lng}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Google Maps route could not be opened.')));
  }
}

class _MockEvStatusCard extends StatefulWidget {
  const _MockEvStatusCard();

  @override
  State<_MockEvStatusCard> createState() => _MockEvStatusCardState();
}

class _MockEvStatusCardState extends State<_MockEvStatusCard> {
  Map<String, dynamic>? _status;
  bool _connecting = false;

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final status = await api.connectMockEv();
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF121B29),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .07))),
        child: Row(children: [
          const Icon(FluentIcons.vehicle_car_24_regular,
              color: Color(0xFF9CCEFF)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_status?['vehicleName']?.toString() ?? 'Mock EV Bluetooth',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    _status == null
                        ? 'Connect your EV profile to show SoC, range and battery temperature.'
                        : '${_status!['socPercent']}% SoC • ${_status!['rangeKm']} km range • ${_status!['batteryTempC']}°C',
                    style: const TextStyle(
                        color: Color(0xFF9AA8BA), fontSize: 11))
              ])),
          TextButton(
              onPressed: _connecting ? null : _connect,
              child: Text(_connecting
                  ? 'Connecting...'
                  : _status == null
                      ? 'Connect'
                      : 'Refresh'))
        ]),
      );
}

class _StationHero extends StatelessWidget {
  final Station station;
  const _StationHero({required this.station});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF102E33),
                Color(0xFF111A2B),
                Color(0xFF0B0F17)
              ]),
        ),
        child: Stack(children: [
          Positioned(right: -36, top: 25, child: _boltOrb()),
          Positioned(
              left: 28,
              bottom: 52,
              child: Container(
                  width: 230,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.13))),
          Positioned(
              left: 27,
              top: 95,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(FluentIcons.location_16_filled,
                        size: 14, color: Color(0xFF8EEAB9)),
                    SizedBox(width: 5),
                    Text('LIVE STATION PREVIEW',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5))
                  ]))),
        ]),
      );

  Widget _boltOrb() => Container(
      width: 195,
      height: 195,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF65D7A5).withValues(alpha: 0.10),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF65D7A5).withValues(alpha: 0.14),
                blurRadius: 80,
                spreadRadius: 26)
          ]),
      child: const Icon(FluentIcons.flash_24_regular,
          color: Color(0xFF83E8B3), size: 60));
}

class _StationSnapshot extends StatelessWidget {
  final Station station;
  const _StationSnapshot({required this.station});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _Metric(
                icon: FluentIcons.plug_connected_24_regular,
                value: '${station.availableConnectors}',
                label: 'available now',
                color: const Color(0xFF79E3A9))),
        const SizedBox(width: 10),
        Expanded(
            child: _Metric(
                icon: FluentIcons.star_24_filled,
                value: station.rating > 0
                    ? station.rating.toStringAsFixed(1)
                    : 'New',
                label: 'station rating',
                color: const Color(0xFFFFC56C))),
        const SizedBox(width: 10),
        Expanded(
            child: _Metric(
                icon: FluentIcons.building_24_regular,
                value: station.isMock ? 'CPO' : 'Live',
                label: 'operator feed',
                color: const Color(0xFF9BCFFC))),
      ]);
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Metric(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: const Color(0xFF121B29),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8E9CB0), fontSize: 9)),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9AA8BA))),
      ]);
}

class _ConnectorCard extends StatelessWidget {
  final Station station;
  final Connector connector;
  const _ConnectorCard({required this.station, required this.connector});

  bool get _bookable => !station.isDemo && connector.id.isNotEmpty;

  Color get _statusColor {
    final state = connector.visualState.toUpperCase();
    if (state == 'FREE' || connector.status.toUpperCase() == 'AVAILABLE') {
      return const Color(0xFF65D7A5);
    }
    if (state == 'BOOKED' || state == 'QUEUED') return const Color(0xFF88C9FF);
    if (state == 'EMERGENCY') return const Color(0xFFFF8F8A);
    if (state == 'CHARGING') return const Color(0xFFFFB15C);
    return const Color(0xFF94A0B1);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF121B29),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _statusColor.withValues(alpha: .24))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(FluentIcons.plug_connected_24_regular,
                    color: _statusColor)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      '${connector.standard} · ${connector.maxPowerKw.toStringAsFixed(0)} kW',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                      connector.powerType.isEmpty
                          ? 'Connector details pending'
                          : connector.powerType,
                      style: const TextStyle(
                          color: Color(0xFF9AA8BA), fontSize: 11)),
                ])),
            _StatusTag(connector: connector, color: _statusColor),
          ]),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _bookable ? () => _startSession(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65D7A5),
                foregroundColor: const Color(0xFF0B0F17),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(FluentIcons.flash_24_filled, size: 18),
              label: const Text('Start Charging Session', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
              onPressed: _bookable ? () => _book(context, 'STANDARD') : null,
              icon: const Icon(FluentIcons.calendar_ltr_24_regular, size: 16),
              label: const Text('Reserve'),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
              onPressed: _bookable ? () => _book(context, 'QUEUE') : null,
              icon: const Icon(FluentIcons.people_queue_24_regular, size: 16),
              label: const Text('Queue'),
            )),
          ]),
          const SizedBox(height: 8),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _bookable ? () => _book(context, 'EMERGENCY') : null,
                icon: const Icon(FluentIcons.alert_urgent_24_regular, size: 16),
                label: const Text('Emergency priority booking'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFA29C)),
              )),
        ]),
      );

  Future<void> _startSession(BuildContext context) async {
    try {
      await api.startSession(
        stationId: station.id,
        connectorId: connector.id,
        initialSoc: 25,
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SessionsScreen()),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _book(BuildContext context, String bookingType) async {
    final start = DateTime.now().add(const Duration(minutes: 5));
    try {
      final booking = await api.createBooking(
          connectorId: connector.id,
          locationId: station.id,
          slotStart: start,
          slotEnd: start.add(const Duration(hours: 1)),
          bookingType: bookingType,
          emergency: bookingType == 'EMERGENCY');
      if (!context.mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BookingResultScreen(booking: booking)));
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _StatusTag extends StatelessWidget {
  final Connector connector;
  final Color color;
  const _StatusTag({required this.connector, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99)),
        child: Text(
            connector.visualState == 'UNKNOWN'
                ? connector.status
                : connector.visualState,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color)),
      );
}

class _NoConnectors extends StatelessWidget {
  const _NoConnectors();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF121B29),
          borderRadius: BorderRadius.circular(18)),
      child: const Text(
          'This operator has not provided connector-level data yet.',
          style: TextStyle(color: Color(0xFF9AA8BA))));
}

class _ReliabilityNote extends StatelessWidget {
  final StationReliability reliability;
  const _ReliabilityNote({required this.reliability});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: reliability.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: reliability.color.withValues(alpha: 0.17))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(FluentIcons.shield_24_regular, color: reliability.color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Your booking is conflict-checked before confirmation. The confidence indicator helps you decide whether to reserve now, but connector availability can still change quickly.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 11,
                      height: 1.4))),
        ]),
      );
}

class _DetailsError extends StatelessWidget {
  final String error;
  const _DetailsError({required this.error});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load station details.\n$error',
                  textAlign: TextAlign.center))));
}

class BookingResultScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingResultScreen({super.key, required this.booking});

  @override
  State<BookingResultScreen> createState() => _BookingResultScreenState();
}

class _BookingResultScreenState extends State<BookingResultScreen> {
  bool _starting = false;
  Map<String, dynamic>? _session;

  Future<void> _startCharging() async {
    setState(() => _starting = true);
    try {
      final session =
          await api.startBookingSession('${widget.booking['id']}');
      if (mounted) setState(() => _session = session);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reservation confirmed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF121B29),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: const Color(0xFF65D7A5).withValues(alpha: 0.25))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF65D7A5).withValues(alpha: 0.13)),
                    child: const Icon(FluentIcons.checkmark_24_regular,
                        color: Color(0xFF82EAB4), size: 32)),
                const SizedBox(height: 16),
                const Text('Your connector is reserved',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Reference: ${widget.booking['externalRef'] ?? widget.booking['bookingRef'] ?? widget.booking['id']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB7C3D4))),
                const SizedBox(height: 8),
                Text(
                    '${widget.booking['bookingType'] ?? 'STANDARD'} • ${widget.booking['visualState'] ?? 'BOOKED'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF9BA9BC), fontSize: 12)),
                if (widget.booking['position'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                      'Queue position ${widget.booking['position']} • ${widget.booking['estimatedWaitMins']} min wait',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF9CCEFF), fontSize: 12)),
                ],
                const SizedBox(height: 18),
                const Text(
                    'At the station, scan the short-lived QR displayed by the authorized operator. CHARGEGRID verifies it before charging starts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFFCFD7E3), fontSize: 12, height: 1.45)),
                if (_session != null) ...[
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        const Text('Mock charging started',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(
                            '${_session!['carName'] ?? _session!['vehicleName']} • ${_session!['socPercent']}% SoC • ₹${_session!['liveCost']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFB7C3D4), fontSize: 12)),
                      ])),
                ],
                const SizedBox(height: 18),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        onPressed:
                            _session == null && !_starting ? _startCharging : null,
                        icon: const Icon(FluentIcons.flash_24_regular),
                        label: Text(_starting
                            ? 'Starting...'
                            : _session == null
                                ? 'Start mock charging'
                                : 'Charging active'))),
                const SizedBox(height: 8),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/scan-kiosk'),
                        icon: const Icon(FluentIcons.qr_code_24_regular),
                        label: const Text('Scan kiosk QR with camera'))),
                const SizedBox(height: 8),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SessionsScreen())),
                        child: const Text('Open sessions & payment'))),
              ]),
            ),
          ),
        ),
      );
}
