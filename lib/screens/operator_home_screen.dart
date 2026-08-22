import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});
  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  final _api = ApiService(backendBase);
  late Future<List<Map<String, dynamic>>> _stations;
  bool _syncing = false;
  @override
  void initState() {
    super.initState();
    _stations = _api.operatorStations();
  }

  Future<void> _reload() async {
    setState(() => _stations = _api.operatorStations());
    await _stations;
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final r = await _api.syncMockStations();
      if (mounted)
        _show(
            'Synced ${r['locations'] ?? 0} stations • ${r['connectors'] ?? 0} connectors');
      await _reload();
    } catch (error) {
      _show('$error');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('CPO operator console'),
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(text: 'Stations'),
              Tab(text: 'Schedules'),
              Tab(text: 'Ratings'),
              Tab(text: 'API')
            ]),
            actions: [
              IconButton(
                  onPressed: _reload,
                  icon: const Icon(FluentIcons.arrow_sync_24_regular))
            ]),
        body: TabBarView(children: [
          _StationsTab(
              stations: _stations,
              onSync: _sync,
              syncing: _syncing,
              onCreate: _show),
          const _SchedulesTab(),
          const _RatingsTab(),
          const _ApiTab()
        ]),
      ));
}

class _StationsTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> stations;
  final VoidCallback onSync;
  final bool syncing;
  final ValueChanged<String> onCreate;
  const _StationsTab(
      {required this.stations,
      required this.onSync,
      required this.syncing,
      required this.onCreate});
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
          future: stations,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF65D7A5)));
            if (snapshot.hasError)
              return _OperatorGate(error: snapshot.error.toString());
            final list = snapshot.data ?? const [];
            return ListView(padding: const EdgeInsets.all(18), children: [
              Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF183B39), Color(0xFF121B29)]),
                      borderRadius: BorderRadius.circular(22)),
                  child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connected CPO network',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 5),
                        Text(
                            'Register stations, refresh mock interoperability data, rotate QR credentials and inspect reservation schedules.',
                            style: TextStyle(
                                color: Color(0xFFB8C9D4),
                                fontSize: 11,
                                height: 1.4))
                      ])),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: syncing ? null : onSync,
                        icon: const Icon(FluentIcons.arrow_sync_24_regular),
                        label: Text(syncing ? 'Syncing…' : 'Sync CPO feed'))),
                const SizedBox(width: 9),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: const Color(0xFF121B29),
                            builder: (_) =>
                                _CreateStationSheet(onCreated: onCreate)),
                        icon: const Icon(FluentIcons.add_24_regular),
                        label: const Text('Add station')))
              ]),
              const SizedBox(height: 18),
              Text('${list.length} managed stations',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              ...list.map((raw) {
                final station = Station.fromJson(raw);
                final tariff = raw['tariff'] is Map
                    ? Map<String, dynamic>.from(raw['tariff'])
                    : const <String, dynamic>{};
                final bookings = raw['bookings'] is List
                    ? raw['bookings'] as List
                    : const [];
                return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OperatorStationCard(
                        station: station,
                        tariff: tariff,
                        bookingCount: bookings.length));
              }),
            ]);
          });
}

class _OperatorStationCard extends StatelessWidget {
  final Station station;
  final Map<String, dynamic> tariff;
  final int bookingCount;
  const _OperatorStationCard(
      {required this.station,
      required this.tariff,
      required this.bookingCount});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF121B29),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withValues(alpha: .07))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF65D7A5).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(FluentIcons.building_24_regular,
                  color: Color(0xFF83EAB3))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(station.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    '${station.city} • ${station.availableConnectors} available',
                    style:
                        const TextStyle(color: Color(0xFF9BA9BA), fontSize: 11))
              ])),
          Text('₹${tariff['pricePerKwh'] ?? '—'}/kWh',
              style: const TextStyle(
                  color: Color(0xFF8DEBBC),
                  fontSize: 11,
                  fontWeight: FontWeight.w800))
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _OperatorFact('${station.connectors.length}', 'connectors'),
          _OperatorFact('$bookingCount', 'active bookings'),
          _OperatorFact(station.rating.toStringAsFixed(1), 'rating'),
          const Spacer(),
          TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/kiosk'),
              icon: const Icon(FluentIcons.qr_code_24_regular, size: 16),
              label: const Text('Kiosk'))
        ])
      ]));
}

class _OperatorFact extends StatelessWidget {
  final String value;
  final String label;
  const _OperatorFact(this.value, this.label);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Color(0xFF8F9EB0), fontSize: 9))
      ]));
}

class _SchedulesTab extends StatelessWidget {
  const _SchedulesTab();
  @override
  Widget build(BuildContext context) => const _StaticConsole(
      icon: FluentIcons.calendar_ltr_24_regular,
      title: 'Conflict-safe reservation schedules',
      body:
          'Each station card in the Stations tab shows its live upcoming booking count. Reservations are checked against connector slots by the server before confirmation.');
}

class _RatingsTab extends StatelessWidget {
  const _RatingsTab();
  @override
  Widget build(BuildContext context) => const _StaticConsole(
      icon: FluentIcons.star_24_filled,
      title: 'Driver trust & reliability',
      body:
          'The consumer reliability smile combines connector availability with the operator rating your CPO sends in each station feed. Keep station status current to protect booking confidence.');
}

class _ApiTab extends StatelessWidget {
  const _ApiTab();
  @override
  Widget build(BuildContext context) => const _StaticConsole(
      icon: FluentIcons.code_24_regular,
      title: 'Unified operator API',
      body:
          'POST /api/v1/operator/stations\nGET /api/v1/operator/stations\nPOST /api/v1/operator/mock-stations/sync\nGET /api/v1/operator/mock-stations/:stationId/dynamic-qr\nPOST /api/v1/kiosk/:stationId/telemetry\nPOST /api/v1/kiosk/:stationId/stop-session');
}

class _StaticConsole extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _StaticConsole(
      {required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: const Color(0xFF121B29),
              borderRadius: BorderRadius.circular(24)),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF9CCEFF), size: 28),
                const SizedBox(height: 13),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body,
                    style: const TextStyle(
                        color: Color(0xFFABB9C9), fontSize: 12, height: 1.5))
              ])));
}

class _OperatorGate extends StatelessWidget {
  final String error;
  const _OperatorGate({required this.error});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(FluentIcons.shield_lock_24_regular,
                size: 34, color: Color(0xFF9CCEFF)),
            const SizedBox(height: 12),
            const Text('Operator access required',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
                'Sign in with an operator or admin account to manage stations.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9AA8BA), fontSize: 11))
          ])));
}

class _CreateStationSheet extends StatefulWidget {
  final ValueChanged<String> onCreated;
  const _CreateStationSheet({required this.onCreated});
  @override
  State<_CreateStationSheet> createState() => _CreateStationSheetState();
}

class _CreateStationSheetState extends State<_CreateStationSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Bengaluru');
  final _state = TextEditingController(text: 'Karnataka');
  final _lat = TextEditingController(text: '12.9716');
  final _lng = TextEditingController(text: '77.5946');
  final _power = TextEditingController(text: '60');
  final _price = TextEditingController(text: '14.5');
  bool _saving = false;
  @override
  void dispose() {
    for (final c in [
      _name,
      _address,
      _city,
      _state,
      _lat,
      _lng,
      _power,
      _price
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final station = await ApiService(backendBase).createOperatorStation({
        'name': _name.text,
        'address': _address.text,
        'city': _city.text,
        'state': _state.text,
        'latitude': double.parse(_lat.text),
        'longitude': double.parse(_lng.text),
        'connectorStandard': 'CCS2',
        'powerType': 'DC',
        'maxPowerKw': double.parse(_power.text),
        'pricePerKwh': double.parse(_price.text),
        'flatFee': 20,
        'rating': 4.8
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated('${station.name} is now available across ChargeGrid.');
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Register a charging station',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    _field(_name, 'Station name'),
                    _field(_address, 'Address'),
                    Row(children: [
                      Expanded(child: _field(_city, 'City')),
                      const SizedBox(width: 8),
                      Expanded(child: _field(_state, 'State'))
                    ]),
                    Row(children: [
                      Expanded(child: _field(_lat, 'Latitude', number: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field(_lng, 'Longitude', number: true))
                    ]),
                    Row(children: [
                      Expanded(child: _field(_power, 'Max kW', number: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field(_price, '₹ / kWh', number: true))
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving
                                ? 'Registering…'
                                : 'Register station'))),
                  ]),
            ),
          ),
        ),
      );
  Widget _field(TextEditingController c, String label, {bool number = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: TextFormField(
              controller: c,
              keyboardType: number
                  ? const TextInputType.numberWithOptions(
                      decimal: true, signed: true)
                  : TextInputType.text,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              decoration: InputDecoration(labelText: label)));
}
