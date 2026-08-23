import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../config/api_config.dart';
import '../models/station_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/dynamic_qr_view.dart';

/// Full Touchscreen Kiosk EVSE Hardware Simulator
class KioskScreen extends StatefulWidget {
  final String? stationId;

  const KioskScreen({super.key, this.stationId});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  List<StationModel> _stations = [];
  StationModel? _selectedStation;
  bool _isLoading = true;

  // Kiosk hardware state
  Map<String, dynamic>? _kioskState;
  bool _isCablePlugged = false;
  bool _isStreaming = false;
  double _livePowerKw = 58.4;
  double _liveSoc = 42.0;
  double _batteryTemp = 32.4;
  int _cumulativeEnergyWh = 0;
  Timer? _telemetryTimer;
  Map<String, dynamic>? _invoice;

  @override
  void initState() {
    super.initState();
    _loadKiosk();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadKiosk() async {
    setState(() => _isLoading = true);
    final stations = await ApiService.getStations();
    if (mounted && stations.isNotEmpty) {
      _stations = stations;
      _selectedStation = widget.stationId != null
          ? stations.firstWhere((s) => s.id == widget.stationId, orElse: () => stations.first)
          : stations.first;
      await _fetchKioskState();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchKioskState() async {
    if (_selectedStation == null) return;
    try {
      final token = AuthService.currentToken;
      final res = await http.get(
        Uri.parse(ApiConfig.kioskState(_selectedStation!.id)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _kioskState = json['data'];
            if (_kioskState?['activeSession'] != null) {
              _cumulativeEnergyWh = int.tryParse(_kioskState!['activeSession']['energyWh']?.toString() ?? '') ?? 0;
              _isCablePlugged = true;
            }
          });
        }
      }
    } catch (_) {}
  }

  void _startTelemetryStream() {
    _telemetryTimer?.cancel();
    _isStreaming = true;
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_selectedStation == null || _kioskState?['activeSession'] == null) return;

      final deltaWh = ((_livePowerKw * 1000) / 3600 * 2).round();
      final nextWh = _cumulativeEnergyWh + deltaWh;
      final nextSoc = (_liveSoc + 0.2).clamp(0.0, 100.0);

      setState(() {
        _cumulativeEnergyWh = nextWh;
        _liveSoc = nextSoc;
      });

      final token = AuthService.currentToken;
      try {
        await http.post(
          Uri.parse(ApiConfig.kioskTelemetry(_selectedStation!.id)),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'energyWh': nextWh,
            'powerKw': _livePowerKw,
            'voltage': 400.0,
            'current': 146.0,
            'socPercent': nextSoc,
            'batteryTempC': _batteryTemp,
            'chargerTempC': 38.2,
          }),
        );
      } catch (_) {}
    });
  }

  Future<void> _handleHardwareStart() async {
    if (_selectedStation == null) return;
    final token = AuthService.currentToken;

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.kioskStart(_selectedStation!.id)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'connectorId': _selectedStation!.connectors.first.id,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _isCablePlugged = true;
          _invoice = null;
        });
        await _fetchKioskState();
        _startTelemetryStream();
      }
    } catch (_) {}
  }

  Future<void> _handleHardwareStop() async {
    if (_selectedStation == null) return;
    _telemetryTimer?.cancel();
    _isStreaming = false;

    final token = AuthService.currentToken;
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.kioskStop(_selectedStation!.id)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'finalEnergyWh': _cumulativeEnergyWh,
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _invoice = json['data']?['invoice'];
        });
        await _fetchKioskState();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.emerald)),
      );
    }

    final isCharging = _kioskState?['activeSession'] != null;
    final isReserved = _kioskState?['activeBooking'] != null && !isCharging;
    final dynamicQr = _kioskState?['qr']?['token']?.toString() ?? 'SAMPLE_URJAA_TOTP_TOKEN';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Kiosk EVSE Header
            GlassContainer(
              borderColor: isCharging ? AppColors.sky : (isReserved ? AppColors.amber : AppColors.emerald),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(FluentIcons.gauge_24_filled, color: AppColors.emerald, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedStation?.name ?? 'EV Charger Kiosk',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('${_selectedStation?.city} · 60kW CCS2 DC Fast',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCharging ? AppColors.sky : isReserved ? AppColors.amber : AppColors.emerald).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isCharging ? '⚡ CHARGING' : isReserved ? '🕒 RESERVED' : '● AVAILABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isCharging ? AppColors.sky : isReserved ? AppColors.amber : AppColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kiosk Display Screen Body
            if (_invoice != null) ...[
              // Invoice Screen
              GlassContainer(
                borderColor: AppColors.emerald,
                child: Column(
                  children: [
                    const Icon(FluentIcons.checkmark_circle_24_filled, color: AppColors.emerald, size: 48),
                    const SizedBox(height: 12),
                    const Text('Charging Completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Text('Tax invoice generated. Ready for payment in user app.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),

                    _invoiceRow('Energy Delivered', '${_invoice!['energyDeliveredKwh']} kWh'),
                    _invoiceRow('Duration', '${_invoice!['durationMinutes']} mins'),
                    _invoiceRow('Base Energy Cost', '₹${_invoice!['baseEnergyCost']}'),
                    _invoiceRow('Connection Fee', '₹${_invoice!['flatConnectionFee']}'),
                    _invoiceRow('GST (18%)', '₹${_invoice!['gst18']}'),
                    const Divider(height: 20),
                    _invoiceRow('Total Due', '₹${_invoice!['totalAmount']} INR', isTotal: true),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () => setState(() => _invoice = null),
                      child: const Text('Back to Kiosk Screen'),
                    ),
                  ],
                ),
              ),
            ] else if (isCharging) ...[
              // Active Telemetry Dials
              GlassContainer(
                borderColor: AppColors.sky,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Battery State of Charge (SoC)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('${_liveSoc.toStringAsFixed(1)}% · Pack ${_batteryTemp}°C',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sky)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _liveSoc / 100,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceElevated,
                        color: AppColors.sky,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _dialTile('Power Output', '${_livePowerKw} kW'),
                        _dialTile('Energy Delivered', '${(_cumulativeEnergyWh / 1000).toStringAsFixed(2)} kWh'),
                        _dialTile('Bus Voltage', '400 V (146A)'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Remote Hardware Stop
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleHardwareStop,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                        icon: const Icon(FluentIcons.stop_24_filled, size: 18, color: Colors.white),
                        label: const Text('Stop Charging (Kiosk)', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Dynamic QR Box
              Center(
                child: DynamicQrView(
                  qrToken: dynamicQr,
                  isOccupied: isReserved,
                  stationName: _selectedStation?.name ?? 'Charging Hub',
                  onRefresh: _fetchKioskState,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Hardware Controls Panel
            const Text('Hardware Simulator Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station Dropdown Switcher
                  DropdownButtonFormField<String>(
                    value: _selectedStation?.id,
                    decoration: const InputDecoration(labelText: 'Select Station to Simulate'),
                    items: _stations.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.city})'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStation = _stations.firstWhere((s) => s.id == val);
                        });
                        _fetchKioskState();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (!isCharging)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleHardwareStart,
                        icon: const Icon(FluentIcons.plug_connected_24_filled, size: 18),
                        label: const Text('Simulate Plug-in & Hardware Start'),
                      ),
                    )
                  else ...[
                    Text('Power Delivery Rate: ${_livePowerKw.toInt()} kW', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Slider(
                      value: _livePowerKw,
                      min: 10,
                      max: 150,
                      divisions: 14,
                      activeColor: AppColors.emerald,
                      onChanged: (val) => setState(() => _livePowerKw = val),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, color: isTotal ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: isTotal ? 17 : 13, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, color: isTotal ? AppColors.emerald : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _dialTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }
}
