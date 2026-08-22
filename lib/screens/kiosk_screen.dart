import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../main.dart';
import '../models/station.dart';
import '../services/api_service.dart';

class KioskScreen extends StatefulWidget {
  final Station? initialStation;
  const KioskScreen({super.key, this.initialStation});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final _api = ApiService(backendBase);
  List<Station> _stations = const [];
  Station? _station;
  Map<String, dynamic>? _state;
  Timer? _poller;
  Timer? _telemetryTimer;
  bool _loading = true;
  bool _streaming = false;
  double _power = 60;
  double _soc = 38;
  double _temperature = 32.4;
  double _energyWh = 0;

  @override
  void initState() {
    super.initState();
    _station = widget.initialStation;
    _loadStations();
    _poller = Timer.periodic(
        const Duration(seconds: 5), (_) => _loadState(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _api.fetchStations();
      if (!mounted) return;
      setState(() {
        _stations = stations;
        if (_station == null || _station!.isDemo) {
          _station = stations.isEmpty ? null : stations.first;
        }
      });
      await _loadState();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadState({bool silent = false}) async {
    final station = _station;
    if (station == null || station.isDemo) {
      if (mounted && !silent) setState(() => _loading = false);
      return;
    }
    try {
      final state = await _api.kioskState(station.id);
      if (mounted) setState(() => _state = state);
    } catch (_) {
      // A kiosk is still usable locally when the authenticated CPO feed is absent.
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    final station = _station;
    if (station == null) return;
    try {
      final connector = _state?['connector'] is Map
          ? _state!['connector']['id']?.toString()
          : null;
      await _api.startKioskSession(station.id, connector);
      if (!mounted) return;
      setState(() {
        _streaming = true;
        _energyWh = 0;
      });
      _startTelemetry();
      await _loadState();
    } catch (error) {
      _show('$error');
    }
  }

  void _startTelemetry() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_streaming || _station == null) return;
      final nextEnergy = _energyWh + (_power * 1000 / 1800);
      final nextSoc = (_soc + .18).clamp(0, 100).toDouble();
      setState(() {
        _energyWh = nextEnergy;
        _soc = nextSoc;
        _temperature = (_temperature + .03).clamp(20, 48).toDouble();
      });
      try {
        await _api.sendTelemetry(_station!.id,
            energyWh: _energyWh,
            powerKw: _power,
            socPercent: _soc,
            batteryTempC: _temperature);
      } catch (_) {}
    });
  }

  Future<void> _stop() async {
    final station = _station;
    if (station == null) return;
    try {
      final result = await _api.stopKioskSession(station.id, _energyWh);
      if (!mounted) return;
      setState(() => _streaming = false);
      _telemetryTimer?.cancel();
      await _loadState();
      final invoice = result['invoice'] is Map
          ? Map<String, dynamic>.from(result['invoice'])
          : result;
      _showInvoice(invoice);
    } catch (error) {
      _show('$error');
    }
  }

  void _show(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));
  void _showInvoice(Map<String, dynamic> invoice) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121B29),
      builder: (_) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(FluentIcons.checkmark_circle_24_filled,
                    color: Color(0xFF65D7A5), size: 42),
                const SizedBox(height: 10),
                const Text('Charging session completed',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _InvoiceRow('Energy delivered',
                    '${invoice['energyDeliveredKwh'] ?? (_energyWh / 1000).toStringAsFixed(2)} kWh'),
                _InvoiceRow(
                    'Connection fee', '₹${invoice['flatConnectionFee'] ?? 20}'),
                _InvoiceRow('GST', '₹${invoice['gst18'] ?? '—'}'),
                const Divider(),
                _InvoiceRow('Total due', '₹${invoice['totalAmount'] ?? '—'}',
                    bold: true),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Pay from My Sessions'))),
              ]))));

  @override
  Widget build(BuildContext context) {
    final station = _station;
    final state = _state;
    final active = state?['activeSession'] != null || _streaming;
    final qr = state?['qr'] is Map ? state!['qr']['token']?.toString() : null;
    final visualState = state?['visualState']?.toString() ??
        (active ? 'CHARGING' : 'FREE');
    final toneColor = _toneColor(visualState);
    final connector = state?['connector'] is Map
        ? Map<String, dynamic>.from(state!['connector'])
        : const <String, dynamic>{};
    final tariff = state?['tariff'] is Map
        ? Map<String, dynamic>.from(state!['tariff'])
        : const <String, dynamic>{};
    final liveCost = ((_energyWh / 1000) *
                (double.tryParse('${tariff['pricePerKwh'] ?? 12.5}') ?? 12.5) +
            (double.tryParse('${tariff['flatFee'] ?? 20}') ?? 20)) *
        1.18;
    return Scaffold(
        appBar: AppBar(title: const Text('Station kiosk')),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF65D7A5)))
            : ListView(padding: const EdgeInsets.all(18), children: [
                if (_stations.isNotEmpty)
                  DropdownButtonFormField<Station>(
                      initialValue: station,
                      isExpanded: true,
                      items: _stations
                          .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text('${item.name} • ${item.city}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _station = value;
                          _state = null;
                          _energyWh = 0;
                        });
                        _loadState();
                      },
                      decoration:
                          const InputDecoration(labelText: 'Charging station')),
                const SizedBox(height: 16),
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF183D3A), Color(0xFF121B29)]),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: toneColor.withValues(alpha: .35))),
                    child: Column(children: [
                      Row(children: [
                        const Icon(FluentIcons.flash_24_regular,
                            color: Color(0xFF86EAB6)),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text(
                                station?.name ??
                                    'No available connected station',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16))),
                        _StatePill(active: active, visualState: visualState)
                      ]),
                      const SizedBox(height: 5),
                      Text(
                          '${connector['standard'] ?? 'CCS2'} • ${connector['maxPowerKw'] ?? station?.connectors.firstOrNull?.maxPowerKw ?? '—'} kW',
                          style: const TextStyle(
                              color: Color(0xFFAAB8C9), fontSize: 12)),
                      const SizedBox(height: 19),
                      if (!active && qr != null) ...[
                        Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.white,
                            child: QrImageView(data: qr, size: 170)),
                        const SizedBox(height: 10),
                        const Text('Rotating, HMAC-signed arrival QR',
                            style: TextStyle(
                                color: Color(0xFF9BEBC0),
                                fontSize: 11,
                                fontWeight: FontWeight.w700))
                      ] else if (active) ...[
                        Text('${_soc.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8DEBBC))),
                        const Text('battery state of charge',
                            style: TextStyle(
                                color: Color(0xFFA9B7C7), fontSize: 11)),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(
                            value: _soc / 100,
                            minHeight: 9,
                            color: toneColor,
                            backgroundColor: Colors.white12,
                            borderRadius: BorderRadius.circular(99)),
                        const SizedBox(height: 17),
                        Row(children: [
                          _TelemetryMetric(
                              value: '${_power.toStringAsFixed(0)} kW',
                              label: 'output'),
                          _TelemetryMetric(
                              value:
                                  '${(_energyWh / 1000).toStringAsFixed(2)} kWh',
                              label: 'delivered'),
                          _TelemetryMetric(
                              value: '₹${liveCost.toStringAsFixed(2)}',
                              label: 'live bill')
                        ]),
                      ] else
                        const Text(
                            'Choose a real station from the live CPO feed to receive a secure QR and charger controls.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFAAB8C9), fontSize: 12)),
                    ])),
                const SizedBox(height: 16),
                if (active)
                  _HardwareControls(
                      power: _power,
                      temperature: _temperature,
                      onPower: (value) => setState(() => _power = value),
                      onTemperature: (value) =>
                          setState(() => _temperature = value))
                else
                  _DiagnosticCard(diagnostics: state?['hardwareDiagnostics']),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        onPressed: station == null
                            ? null
                            : active
                                ? _stop
                                : _start,
                        icon: Icon(active
                            ? FluentIcons.stop_24_regular
                            : FluentIcons.play_24_regular),
                        label: Text(active
                            ? 'Stop charge & issue invoice'
                            : 'Plug & authorise session'))),
              ]));
  }
}

Color _toneColor(String visualState) {
  switch (visualState.toUpperCase()) {
    case 'FREE':
    case 'AVAILABLE':
      return const Color(0xFF65D7A5);
    case 'BOOKED':
    case 'QUEUED':
      return const Color(0xFF88C9FF);
    case 'EMERGENCY':
      return const Color(0xFFFF8F8A);
    case 'CHARGING':
      return const Color(0xFFFFB15C);
    default:
      return const Color(0xFF94A0B1);
  }
}

class _StatePill extends StatelessWidget {
  final bool active;
  final String visualState;
  const _StatePill({required this.active, required this.visualState});
  @override
  Widget build(BuildContext context) {
    final color = _toneColor(visualState);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(99)),
      child: Text(active ? '● CHARGING' : '● ${visualState.toUpperCase()}',
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800)));
  }
}

class _TelemetryMetric extends StatelessWidget {
  final String value;
  final String label;
  const _TelemetryMetric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Color(0xFF9DAABC), fontSize: 9))
      ]));
}

class _HardwareControls extends StatelessWidget {
  final double power;
  final double temperature;
  final ValueChanged<double> onPower;
  final ValueChanged<double> onTemperature;
  const _HardwareControls(
      {required this.power,
      required this.temperature,
      required this.onPower,
      required this.onTemperature});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF121B29),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Hardware & CPO controls',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Power output • ${power.toStringAsFixed(0)} kW',
            style: const TextStyle(color: Color(0xFFAAB8C9), fontSize: 12)),
        Slider(
            value: power, min: 10, max: 150, divisions: 28, onChanged: onPower),
        Text('Battery pack temperature • ${temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(color: Color(0xFFAAB8C9), fontSize: 12)),
        Slider(
            value: temperature,
            min: 20,
            max: 55,
            divisions: 35,
            onChanged: onTemperature)
      ]));
}

class _DiagnosticCard extends StatelessWidget {
  final dynamic diagnostics;
  const _DiagnosticCard({this.diagnostics});
  @override
  Widget build(BuildContext context) {
    final data = diagnostics is Map
        ? Map<String, dynamic>.from(diagnostics)
        : const <String, dynamic>{};
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF121B29),
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kiosk hardware diagnostics',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
              'Grid ${data['gridFrequencyHz'] ?? '50.02'} Hz • PF ${data['powerFactor'] ?? '0.99'}\nCable ${data['cableLockStatus'] ?? 'UNLOCKED'} • Firmware ${data['firmwareVersion'] ?? 'secure channel pending'}',
              style: const TextStyle(
                  color: Color(0xFFAAB8C9), fontSize: 11, height: 1.45))
        ]));
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InvoiceRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                color: bold ? Colors.white : const Color(0xFFAAB8C9),
                fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: bold ? const Color(0xFF8DEBBC) : Colors.white,
                fontWeight: bold ? FontWeight.w800 : FontWeight.normal))
      ]));
}
