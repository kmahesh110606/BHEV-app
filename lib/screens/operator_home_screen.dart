import 'dart:async';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});
  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService(backendBase);
  late final TabController _tabs;
  Future<_OperatorData>? _future;
  String? _stationId;
  Map<String, dynamic>? _qr;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 10, vsync: this)
      ..addListener(() {
        if (_tabs.indexIsChanging) return;
        setState(() {});
        if (_tabs.index == 5) _loadQr();
      });
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _tabs.index != 5) return;
      setState(() => _countdown = _countdown > 1 ? _countdown - 1 : 30);
      if (_countdown == 30) _loadQr();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    try {
      final data = await _future!;
      if (_stationId == null && data.stations.isNotEmpty && mounted)
        setState(() => _stationId = data.stations.first.id);
    } catch (_) {}
  }

  Future<_OperatorData> _load() async {
    final r = await Future.wait<dynamic>([
      _api.operatorStations(),
      _api.fetchOperatorAnalytics(),
      _api.operatorBookings(),
      _api.operatorQueue(),
      _api.operatorSessions(),
      _api.operatorNotifications(),
    ]);
    return _OperatorData(
      stations:
          (r[0] as List<Map<String, dynamic>>).map(Station.fromJson).toList(),
      analytics: r[1],
      bookings: r[2],
      queue: r[3],
      sessions: r[4],
      notifications: r[5],
    );
  }

  void _notice(Object error) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _loadQr() async {
    if (_stationId == null) return;
    try {
      final qr = await _api.stationDynamicQr(_stationId!);
      if (mounted)
        setState(() {
          _qr = qr;
          _countdown = 30;
        });
    } catch (e) {
      _notice(e);
    }
  }

  Map<String, dynamic> _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : const {};
  double _number(Object? raw) => double.tryParse(raw?.toString() ?? '') ?? 0;
  String _title(String key) =>
      key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();

  Future<void> _delete(String label, Future<void> Function() action) async {
    final okay = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Delete $label?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'))
                ]));
    if (okay != true) return;
    try {
      await action();
      await _reload();
      _notice('$label deleted.');
    } catch (e) {
      _notice(e);
    }
  }

  Future<void> _addStation() async {
    final form = await _stationForm();
    if (form == null) return;
    try {
      await _api.createOperatorStation(form);
      await _reload();
      _notice('Station published to discovery.');
    } catch (e) {
      _notice(e);
    }
  }

  Future<void> _addCharger(Station station) async {
    final power = TextEditingController(text: '60');
    final bay =
        TextEditingController(text: 'Bay #${station.connectors.length + 1}');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add charger to ${station.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: power,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Max power (kW)')),
          const SizedBox(height: 8),
          TextField(
              controller: bay,
              decoration:
                  const InputDecoration(labelText: 'Physical reference')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, {
                    'maxPowerKw': double.tryParse(power.text) ?? 60,
                    'physicalReference': bay.text.trim(),
                    'standard': 'CCS2',
                    'powerType': 'DC',
                    'pricePerKwh': 14.5,
                    'flatFee': 20
                  }),
              child: const Text('Add charger')),
        ],
      ),
    );
    power.dispose();
    bay.dispose();
    if (result == null) return;
    try {
      await _api.addCharger(station.id, result);
      await _reload();
      _notice('Charger added.');
    } catch (e) {
      _notice(e);
    }
  }

  Future<Map<String, dynamic>?> _stationForm() async {
    final fields = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(text: 'Bengaluru'),
      TextEditingController(text: 'Karnataka'),
      TextEditingController(text: '12.9716'),
      TextEditingController(text: '77.5946'),
      TextEditingController(text: '60'),
      TextEditingController(text: '14.5')
    ];
    final labels = [
      'Station name',
      'Address',
      'City',
      'State',
      'Latitude',
      'Longitude',
      'Max power (kW)',
      'Rate (INR/kWh)'
    ];
    final key = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Add charging station'),
                content: SizedBox(
                    width: 420,
                    child: Form(
                        key: key,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                    fields.length,
                                    (i) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: TextFormField(
                                            controller: fields[i],
                                            keyboardType: i >= 4
                                                ? const TextInputType
                                                    .numberWithOptions(
                                                    decimal: true, signed: true)
                                                : null,
                                            decoration: InputDecoration(
                                                labelText: labels[i]),
                                            validator: (v) =>
                                                v == null || v.trim().isEmpty
                                                    ? 'Required'
                                                    : null))))))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (!key.currentState!.validate()) return;
                        Navigator.pop(context, {
                          'name': fields[0].text.trim(),
                          'address': fields[1].text.trim(),
                          'city': fields[2].text.trim(),
                          'state': fields[3].text.trim(),
                          'latitude': double.parse(fields[4].text),
                          'longitude': double.parse(fields[5].text),
                          'maxPowerKw': double.parse(fields[6].text),
                          'pricePerKwh': double.parse(fields[7].text),
                          'connectorStandard': 'CCS2',
                          'powerType': 'DC',
                          'flatFee': 20
                        });
                      },
                      child: const Text('Publish'))
                ]));
    for (final field in fields) {
      field.dispose();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentUser?['role']?.toString();
    if (role != 'operator' && role != 'admin')
      return const _OperatorAccessGate();
    return Scaffold(
        appBar: AppBar(
            title: const Text('Operator console'),
            actions: [
              IconButton(
                  onPressed: _reload,
                  tooltip: 'Refresh console',
                  icon: const Icon(FluentIcons.arrow_sync_24_regular))
            ],
            bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Stations'),
              Tab(text: 'Chargers'),
              Tab(text: 'Bookings'),
              Tab(text: 'Queue'),
              Tab(text: 'QR check-in'),
              Tab(text: 'Sessions'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Analytics'),
              Tab(text: 'Inbox')
            ])),
        floatingActionButton: _tabs.index == 1
            ? FloatingActionButton.extended(
                onPressed: _addStation,
                icon: const Icon(FluentIcons.add_24_regular),
                label: const Text('Add station'))
            : null,
        body: FutureBuilder<_OperatorData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return _LoadFailure(error: snapshot.error!, retry: _reload);
              final data = snapshot.requireData;
              return TabBarView(controller: _tabs, children: [
                _overview(data),
                _stations(data),
                _chargers(data),
                _records(
                    data.bookings,
                    (b) =>
                        '${b['externalRef'] ?? b['id']} • ${b['driverName'] ?? 'Driver'}',
                    (b) =>
                        '${b['stationName'] ?? b['stationId']} • ${b['status'] ?? 'Pending'}'),
                _records(
                    data.queue,
                    (q) =>
                        '#${q['position'] ?? '—'} • ${q['driverName'] ?? 'Driver'}',
                    (q) =>
                        '${q['waitMins'] ?? 0} min • ${q['status'] ?? 'WAITING'}'),
                _qrTab(data),
                _records(
                    data.sessions,
                    (s) =>
                        '${s['driverName'] ?? 'Driver'} • ${s['stationName'] ?? s['stationId']}',
                    (s) =>
                        '${(_number(s['energyWh']) / 1000).toStringAsFixed(1)} kWh • INR ${s['cost'] ?? 0} • ${s['status'] ?? ''}'),
                _chargers(data, maintenance: true),
                _analytics(data),
                _inbox(data)
              ]);
            }));
  }

  Widget _overview(_OperatorData data) {
    final o = _map(data.analytics['overview']);
    return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Network at a glance',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _metric('Stations', o['totalStations']),
            _metric('Chargers', o['totalChargers']),
            _metric('Live sessions', o['activeSessions']),
            _metric('Utilization', o['utilizationRate']),
            _metric('Revenue', o['totalRevenueToday']),
            _metric('Queue', o['queueSize'])
          ]),
          const SizedBox(height: 22),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: _addStation,
                icon: const Icon(FluentIcons.add_24_regular),
                label: const Text('Register station')),
            OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final r = await _api.runNoShowCheck();
                    await _reload();
                    _notice('${r['reclaimed'] ?? 0} no-show slots reclaimed.');
                  } catch (e) {
                    _notice(e);
                  }
                },
                icon: const Icon(FluentIcons.play_24_regular),
                label: const Text('Run no-show check'))
          ])
        ]));
  }

  Widget _metric(String label, Object? value) => SizedBox(
      width: 150,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value?.toString() ?? '0',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20)),
                    Text(label,
                        style: const TextStyle(color: Color(0xFF9BA9BA)))
                  ]))));
  Widget _stations(_OperatorData data) => RefreshIndicator(
        onRefresh: _reload,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (data.stations.isEmpty)
            const _EmptyState(
                text: 'No stations yet. Add your first charging station.'),
          ...data.stations.map((s) => Card(
                  child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(FluentIcons.building_24_regular,
                            color: Color(0xFF10B981)),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            onPressed: () => _delete(
                                'station', () => _api.deleteStation(s.id)),
                            tooltip: 'Delete station',
                            icon: const Icon(FluentIcons.delete_24_regular)),
                      ]),
                      Text('${s.address}, ${s.city}'),
                      const SizedBox(height: 7),
                      Text(
                          '${s.connectors.length} chargers • ${s.availableConnectors} available'),
                      Wrap(spacing: 8, children: [
                        TextButton(
                            onPressed: () {
                              setState(() => _stationId = s.id);
                              _tabs.animateTo(5);
                            },
                            child: const Text('Show check-in QR')),
                        TextButton(
                            onPressed: () => _addCharger(s),
                            child: const Text('Add charger')),
                      ]),
                    ]),
              ))),
        ]),
      );
  List<_ChargerEntry> _entries(_OperatorData data) => [
        for (final s in data.stations)
          for (final c in s.connectors) _ChargerEntry(s, c)
      ];
  Widget _chargers(_OperatorData data, {bool maintenance = false}) {
    final entries = _entries(data)
        .where((e) => !maintenance || e.connector.status == 'MAINTENANCE')
        .toList();
    return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (entries.isEmpty)
            _EmptyState(
                text: maintenance
                    ? 'No chargers are currently in maintenance.'
                    : 'No chargers are configured.'),
          ...entries.map((e) => Card(
                  child: ListTile(
                title: Text('${e.station.name} • ${e.connector.standard}'),
                subtitle: Text(
                    '${e.connector.maxPowerKw.toStringAsFixed(0)} kW • ${e.connector.status}'),
                trailing: Wrap(spacing: 2, children: [
                  TextButton(
                      onPressed: () async {
                        try {
                          await _api.toggleMaintenance(e.connector.id,
                              e.connector.status != 'MAINTENANCE');
                          await _reload();
                        } catch (x) {
                          _notice(x);
                        }
                      },
                      child: Text(e.connector.status == 'MAINTENANCE'
                          ? 'Restore'
                          : 'Maintain')),
                  IconButton(
                      onPressed: () => _delete(
                          'charger', () => _api.deleteCharger(e.connector.id)),
                      tooltip: 'Delete charger',
                      icon: const Icon(FluentIcons.delete_24_regular)),
                ]),
              ))),
        ]));
  }

  Widget _records(
          List<Map<String, dynamic>> list,
          String Function(Map<String, dynamic>) title,
          String Function(Map<String, dynamic>) subtitle) =>
      RefreshIndicator(
          onRefresh: _reload,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (list.isEmpty) const _EmptyState(text: 'Nothing to show yet.'),
            ...list.map((r) => Card(
                child: ListTile(
                    title: Text(title(r)), subtitle: Text(subtitle(r)))))
          ]));
  Widget _qrTab(_OperatorData data) =>
      ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Rotating arrival QR',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
            'The check-in credential is short lived and station scoped.'),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
            initialValue: _stationId,
            decoration: const InputDecoration(labelText: 'Station'),
            items: data.stations
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (id) {
              setState(() => _stationId = id);
              _loadQr();
            }),
        const SizedBox(height: 22),
        if (_qr?['token'] != null)
          Center(
              child: Column(children: [
            Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: QrImageView(data: _qr!['token'].toString(), size: 230)),
            const SizedBox(height: 12),
            Text('Rotates in $_countdown seconds'),
            TextButton.icon(
                onPressed: _loadQr,
                icon: const Icon(FluentIcons.arrow_sync_24_regular),
                label: const Text('Refresh now'))
          ]))
        else
          const _EmptyState(text: 'Choose a station to generate an arrival QR.')
      ]);
  Widget _analytics(_OperatorData data) {
    final score = _map(data.analytics['reliabilityScore']);
    final parts = _map(score['breakdown']);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Reliability ${score['composite'] ?? '—'} / 100',
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 15),
      ...parts.entries.map((e) => Card(
          child: ListTile(
              title: Text(_title(e.key)),
              trailing:
                  Text('${e.value}${e.key == 'userRating' ? ' / 5' : '%'}'))))
    ]);
  }

  Widget _inbox(_OperatorData data) => RefreshIndicator(
      onRefresh: _reload,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (data.notifications.isEmpty)
          const _EmptyState(text: 'No notifications.'),
        ...data.notifications.map((n) => Card(
            child: ListTile(
                title: Text(n['title']?.toString() ?? 'Operator event'),
                subtitle: Text(n['message']?.toString() ?? ''),
                leading: Icon(n['isRead'] == true
                    ? FluentIcons.mail_read_24_regular
                    : FluentIcons.mail_unread_24_regular),
                onTap: () async {
                  if (n['isRead'] == true) return;
                  try {
                    await _api.markNotificationRead(n['id'].toString());
                    await _reload();
                  } catch (e) {
                    _notice(e);
                  }
                })))
      ]));
}

class _OperatorData {
  const _OperatorData(
      {required this.stations,
      required this.analytics,
      required this.bookings,
      required this.queue,
      required this.sessions,
      required this.notifications});
  final List<Station> stations;
  final Map<String, dynamic> analytics;
  final List<Map<String, dynamic>> bookings, queue, sessions, notifications;
}

class _ChargerEntry {
  const _ChargerEntry(this.station, this.connector);
  final Station station;
  final Connector connector;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9BA9BA)))));
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.retry});
  final Object error;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(FluentIcons.shield_error_24_regular, size: 40),
            const SizedBox(height: 12),
            const Text('Unable to load the operator console'),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: const Text('Try again'))
          ])));
}

class _OperatorAccessGate extends StatelessWidget {
  const _OperatorAccessGate();
  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(
          child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(FluentIcons.shield_lock_24_regular, size: 40),
                SizedBox(height: 12),
                Text('Operator access required',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
                SizedBox(height: 8),
                Text(
                    'Sign in with an operator account to manage charging stations.',
                    textAlign: TextAlign.center)
              ]))));
}
