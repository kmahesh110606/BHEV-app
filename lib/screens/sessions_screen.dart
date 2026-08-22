import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _api = ApiService(backendBase);
  Timer? _poller;
  Map<String, dynamic>? _active;
  List<Map<String, dynamic>> _history = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _poller =
        Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final result =
          await Future.wait([_api.activeSession(), _api.mySessions()]);
      if (mounted) {
        setState(() {
          _active = result[0] as Map<String, dynamic>?;
          _history = result[1] as List<Map<String, dynamic>>;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _stop() async {
    final active = _active;
    if (active == null) return;
    try {
      final completed = await _api.stopSession('${active['id']}');
      if (!mounted) return;
      await _load();
      _openPayment(completed);
    } catch (error) {
      if (mounted) _notice('$error');
    }
  }

  void _openPayment(Map<String, dynamic> session) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF121B29),
        builder: (context) => _PaymentSheet(
          session: session,
          onPay: (method) async {
            final receipt = await _api.paySession('${session['id']}', method);
            if (!mounted) return;
            Navigator.pop(context);
            await _load();
            _notice('Payment confirmed • ${receipt['transactionId'] ?? 'SUCCESS'}');
          },
        ),
      );

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: const Color(0xFF65D7A5),
          child: ListView(padding: const EdgeInsets.all(18), children: [
            Row(children: [
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('My charging sessions',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Live energy telemetry, digital invoices & UPI settlement',
                        style:
                            TextStyle(color: Color(0xFF9BA8BA), fontSize: 12)),
                  ])),
              IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(FluentIcons.arrow_sync_24_regular)),
            ]),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(34),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF65D7A5))))
            else if (_error != null)
              _InfoCard(
                  icon: FluentIcons.lock_closed_24_regular,
                  title: AuthService.currentToken == null
                      ? 'Sign in to see your sessions'
                      : 'Session connection error',
                  body: AuthService.currentToken == null
                      ? 'Session tracking and instant payments require your ChargeGrid account.\n${_error.toString()}'
                      : 'Unable to sync live sessions with server.\n${_error.toString()}',
                  action: AuthService.currentToken == null ? 'Sign in' : 'Retry',
                  onAction: AuthService.currentToken == null
                      ? () => Navigator.pushNamed(context, '/sign-in')
                      : _load)
            else if (_active != null)
              _ActiveSessionCard(session: _active!, onStop: _stop)
            else
              _InfoCard(
                  icon: FluentIcons.flash_24_regular,
                  title: 'No active charging session',
                  body:
                      'Find a station on the map, scan the QR code or tap Start Charging on any available pedestal.',
                  action: 'Find chargers',
                  onAction: () => Navigator.pushNamed(context, '/customer')),
            const SizedBox(height: 24),
            const Text('Charging history',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (!_loading && _error == null && _history.isEmpty)
              const Text('No completed sessions recorded yet.',
                  style: TextStyle(color: Color(0xFF9BA8BA), fontSize: 12))
            else
              ..._history.map((session) => _HistoryCard(
                    session: session,
                    onPay: '${session['status']}'.toUpperCase() == 'COMPLETED'
                        ? () => _openPayment(session)
                        : null,
                  )),
          ]),
        ),
      );
}

class _ActiveSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onStop;
  const _ActiveSessionCard({required this.session, required this.onStop});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF153B39), Color(0xFF121B29)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF65D7A5).withValues(alpha: 0.28))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            _LiveDot(),
            SizedBox(width: 8),
            Text('ACTIVE CHARGING',
                style: TextStyle(
                    color: Color(0xFF8DEBBC),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6)),
          ]),
          const SizedBox(height: 11),
          Text('${session['stationName'] ?? 'Charging station'}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(
              '${session['connectorStandard'] ?? 'EV connector'} • ${session['maxPowerKw'] ?? '60'} kW',
              style: const TextStyle(color: Color(0xFFB5C3D2), fontSize: 12)),
          const SizedBox(height: 18),
          Row(children: [
            _SessionMetric(
                value: '${session['energyKwh'] ?? 0}', label: 'kWh delivered'),
            _SessionMetric(
                value: '${session['durationMinutes'] ?? 0}', label: 'minutes'),
            _SessionMetric(
                value: '₹${session['liveCost'] ?? 0}', label: 'live cost'),
          ]),
          const SizedBox(height: 18),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(FluentIcons.stop_24_regular),
                label: const Text('Stop charge & settle bill'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB5AD)),
              )),
        ]),
      );
}

class _SessionMetric extends StatelessWidget {
  final String value;
  final String label;
  const _SessionMetric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Color(0xFF9EADBF), fontSize: 9)),
      ]));
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback? onPay;
  const _HistoryCard({required this.session, this.onPay});
  @override
  Widget build(BuildContext context) {
    final connector = session['connector'] is Map
        ? Map<String, dynamic>.from(session['connector'])
        : const <String, dynamic>{};
    final evse = connector['evse'] is Map
        ? Map<String, dynamic>.from(connector['evse'])
        : const <String, dynamic>{};
    final location = evse['location'] is Map
        ? Map<String, dynamic>.from(evse['location'])
        : const <String, dynamic>{};
    final energy = session['energyKwh'] ?? (double.tryParse('${session['energyWh'] ?? 0}') ?? 0) / 1000;
    final cost = session['cost'] ?? session['liveCost'] ?? 0;
    final stationName = session['stationName'] ?? location['name'] ?? 'Charging Station';

    return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFF121B29),
              borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            const Icon(FluentIcons.receipt_24_regular,
                color: Color(0xFF9CCEFF)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$stationName',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${energy.toStringAsFixed(1)} kWh • ${session['durationMinutes'] ?? 0} mins • ₹$cost',
                    style: const TextStyle(color: Color(0xFF9BA8BA), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (onPay != null && session['payment'] == null)
              ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: const Color(0xFF65D7A5),
                  foregroundColor: const Color(0xFF0B0F17),
                ),
                child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              )
            else
              const Text('PAID', style: TextStyle(color: Color(0xFF65D7A5), fontWeight: FontWeight.w800, fontSize: 11)),
          ]),
        ));
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();
  @override
  Widget build(BuildContext context) => Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
          color: Color(0xFF65D7A5), shape: BoxShape.circle));
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  const _InfoCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.action,
      required this.onAction});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF121B29),
            borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF9CCEFF), size: 28),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFF9CA9BA), fontSize: 12, height: 1.4)),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onAction, child: Text(action)),
        ]),
      );
}

class _PaymentSheet extends StatefulWidget {
  final Map<String, dynamic> session;
  final Future<void> Function(String method) onPay;
  const _PaymentSheet({required this.session, required this.onPay});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _method = 'UPI';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final cost = widget.session['cost'] ?? widget.session['liveCost'] ?? 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digital invoice checkout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Station: ${widget.session['stationName'] ?? 'EV Charging Station'}',
              style: const TextStyle(color: Color(0xFFB0BFD0), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF172437),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('Total payable (GST included)', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('₹$cost', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF65D7A5))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select payment gateway', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['UPI', 'Debit Card', 'Credit Card', 'Net Banking'].map((m) {
                final selected = _method == m;
                return ChoiceChip(
                  label: Text(m),
                  selected: selected,
                  onSelected: (val) => setState(() => _method = m),
                  selectedColor: const Color(0xFF65D7A5),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF0B0F17) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await widget.onPay(_method);
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: Text(_busy ? 'Processing payment…' : 'Pay ₹$cost with $_method'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
