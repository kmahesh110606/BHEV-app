import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/operator_service.dart';
import '../config/api_config.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/dynamic_qr_view.dart';

/// Full interactive EVSE Touchscreen Kiosk Simulator replicating physical charger hardware & 3-phase grid telemetry
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

    List<StationModel> list = [];

    // 1. Check OperatorService stations in memory
    try {
      final opService = context.read<OperatorService?>();
      if (opService != null && opService.stations.isNotEmpty) {
        list = List.from(opService.stations);
      }
    } catch (_) {}

    // 2. Fetch stations from ApiService / offline cache
    if (list.isEmpty) {
      try {
        final fetched = await ApiService.getStations(limit: 100);
        if (fetched.isNotEmpty) list.addAll(fetched);
      } catch (_) {}
    }

    // 3. Fallback default operator hubs ensuring dropdown is NEVER empty
    if (list.isEmpty) {
      list = [
        StationModel(
          id: 'stn-a53c1077',
          name: 'Indiranagar 100ft HyperGrid Station',
          address: '100 Feet Road, HAL 2nd Stage, Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          latitude: 12.9716,
          longitude: 77.6412,
          cpo: 'Tata Power EZ Charge',
          availableConnectors: 1,
          connectors: [
            ConnectorModel(
              id: 'CHG-9713C707',
              standard: 'CCS2',
              powerType: 'DC',
              maxPowerKw: 120,
              status: 'AVAILABLE',
              tariff: TariffModel(pricePerKwh: 15.5, flatFee: 25.0),
            ),
          ],
        ),
        StationModel(
          id: 'stn-fd05ddf3',
          name: 'Tata Power MG Road Supercharger Hub',
          address: '1 MG Road, Central Business District',
          city: 'Bengaluru',
          state: 'Karnataka',
          latitude: 12.9716,
          longitude: 77.5946,
          cpo: 'Tata Power EZ Charge',
          availableConnectors: 1,
          connectors: [
            ConnectorModel(
              id: 'CHG-8D9FA737',
              standard: 'CCS2',
              powerType: 'DC',
              maxPowerKw: 60,
              status: 'AVAILABLE',
              tariff: TariffModel(pricePerKwh: 16.5, flatFee: 25.0),
            ),
          ],
        ),
        StationModel(
          id: 'stn-01',
          name: 'Koramangala DC Fast Port',
          address: '80 Feet Road, 4th Block, Koramangala',
          city: 'Bengaluru',
          state: 'Karnataka',
          latitude: 12.9352,
          longitude: 77.6245,
          cpo: 'URJAA HyperCharge',
          availableConnectors: 2,
          connectors: [
            ConnectorModel(
              id: 'conn-01',
              standard: 'CCS2',
              powerType: 'DC',
              maxPowerKw: 60,
              status: 'AVAILABLE',
              tariff: TariffModel(pricePerKwh: 14.5, flatFee: 20.0),
            ),
          ],
        ),
        StationModel(
          id: 'stn-03',
          name: 'Electronic City Supercharge Hub',
          address: 'Phase 1, Hosur Road',
          city: 'Bengaluru',
          state: 'Karnataka',
          latitude: 12.8452,
          longitude: 77.6602,
          cpo: 'Tata Power EZ Charge',
          availableConnectors: 4,
          connectors: [
            ConnectorModel(
              id: 'conn-03',
              standard: 'CCS2',
              powerType: 'DC',
              maxPowerKw: 120,
              status: 'AVAILABLE',
              tariff: TariffModel(pricePerKwh: 15.0, flatFee: 25.0),
            ),
          ],
        ),
      ];
    }

    // Deduplicate by ID
    final seen = <String>{};
    final uniqueStations = <StationModel>[];
    for (final s in list) {
      if (s.id.isNotEmpty && !seen.contains(s.id)) {
        seen.add(s.id);
        uniqueStations.add(s);
      }
    }

    if (mounted) {
      setState(() {
        _stations = uniqueStations;
        _selectedStation = widget.stationId != null
            ? uniqueStations.firstWhere((s) => s.id == widget.stationId, orElse: () => uniqueStations.first)
            : uniqueStations.first;
        _isLoading = false;
      });
      await _fetchKioskState();
    }
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
      final connId = _selectedStation!.connectors.isNotEmpty
          ? _selectedStation!.connectors.first.id
          : '${_selectedStation!.id}-conn-01';

      final res = await http.post(
        Uri.parse(ApiConfig.kioskStart(_selectedStation!.id)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'connectorId': connId,
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

    // Fallback simulation if offline
    setState(() {
      _isCablePlugged = true;
      _isStreaming = true;
      _invoice = null;
    });
    _startTelemetryStream();
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
          'finalEnergyWh': _cumulativeEnergyWh > 0 ? _cumulativeEnergyWh : 24500,
          'driverName': 'EV Driver',
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _invoice = json['data'];
          _isCablePlugged = false;
        });
        await _fetchKioskState();
        return;
      }
    } catch (_) {}

    // Local invoice calculation fallback
    final kwh = (_cumulativeEnergyWh > 0 ? _cumulativeEnergyWh : 24500) / 1000;
    final baseCost = kwh * (_selectedStation?.baseTariffPerKwh ?? 14.5) + (_selectedStation?.connectionFlatFee ?? 20.0);
    final gst = baseCost * 0.18;
    setState(() {
      _invoice = {
        'invoiceId': 'INV-KIOSK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'energyDeliveredKwh': kwh.toStringAsFixed(2),
        'baseAmount': baseCost.toStringAsFixed(2),
        'gst18': gst.toStringAsFixed(2),
        'totalPaid': (baseCost + gst).toStringAsFixed(2),
      };
      _isCablePlugged = false;
      _isStreaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.sky)),
      );
    }

    final activeSess = _kioskState?['activeSession'];
    final isCharging = _isStreaming || activeSess != null;
    final isReserved = _kioskState?['activeBooking'] != null;

    final qrToken = _kioskState?['dynamicQr']?['token'] ??
        'URJAA_TOTP_HMAC_${_selectedStation?.id ?? "DEMO"}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kiosk Header Bar
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderColor: isCharging ? AppColors.sky : isReserved ? AppColors.amber : AppColors.emerald,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCharging ? AppColors.sky : AppColors.emerald).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCharging ? FluentIcons.flash_24_filled : FluentIcons.gauge_24_filled,
                          color: isCharging ? AppColors.sky : AppColors.emerald,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStation?.name ?? 'EVSE Touchscreen Kiosk',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedStation?.city ?? "Bengaluru"} · Max ${_selectedStation?.maxPowerKw ?? 60} kW DC',
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCharging ? AppColors.sky : isReserved ? AppColors.amber : AppColors.emerald).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
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
                    _invoiceRow('Base Cost', '₹${_invoice!['baseAmount']}'),
                    _invoiceRow('GST (18%)', '₹${_invoice!['gst18']}'),
                    const Divider(height: 20),
                    _invoiceRow('Total Paid', '₹${_invoice!['totalPaid']}', isTotal: true),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _invoice = null),
                        icon: const Icon(FluentIcons.arrow_clockwise_24_filled, size: 16),
                        label: const Text('Reset Kiosk Terminal'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!isCharging) ...[
              // Idle Dynamic QR Terminal
              Center(
                child: Column(
                  children: [
                    DynamicQrView(
                      qrToken: qrToken,
                      isOccupied: false,
                      stationName: _selectedStation?.name ?? 'EV Station',
                      onRefresh: _fetchKioskState,
                      size: 210,
                    ),
                    const SizedBox(height: 14),
                    const Text('Scan dynamic QR from driver app to initiate charge',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ] else ...[
              // Live Active Charging Screen
              GlassContainer(
                borderColor: AppColors.sky,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Battery State of Charge (SoC)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('${_liveSoc.toStringAsFixed(1)}% · Pack $_batteryTemp°C',
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
                        _dialTile('Power Output', '$_livePowerKw kW'),
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
                        label: const Text('Remote Hardware Stop & Generate Invoice', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Hardware Controls Panel
            const Text('Hardware Simulator Controls', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station Dropdown Switcher
                  if (_stations.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _stations.any((s) => s.id == _selectedStation?.id)
                          ? _selectedStation?.id
                          : _stations.first.id,
                      decoration: const InputDecoration(labelText: 'Select Station to Simulate'),
                      isExpanded: true,
                      items: _stations.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(
                            '${s.name} (${s.city})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStation = _stations.firstWhere((s) => s.id == val);
                            _invoice = null;
                          });
                          _fetchKioskState();
                        }
                      },
                    ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cable Lock: ${_isCablePlugged ? "ENGAGED" : "UNLOCKED"}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Text('Telemetry: ${_isStreaming ? "STREAMING" : "STANDBY"}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),

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

  Widget _dialTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.sky)),
      ],
    );
  }

  Widget _invoiceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, fontSize: isTotal ? 14 : 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: isTotal ? 16 : 13, color: isTotal ? AppColors.emerald : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
