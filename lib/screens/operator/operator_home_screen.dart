import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../services/operator_service.dart';
import '../../models/operator_models.dart';
import '../../models/station_model.dart';
import '../../models/booking_model.dart';
import '../../models/session_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/dynamic_qr_view.dart';
import 'widgets/add_station_sheet.dart';
import 'widgets/add_charger_sheet.dart';

/// Complete URJAA CPO Mobile Operator Console spanning all 13 enterprise modules
class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperatorService>().loadAllOperatorData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddStationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddStationSheet(),
    );
  }

  void _showAddChargerSheet(StationModel station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddChargerSheet(stationId: station.id, stationName: station.name),
    );
  }

  void _showReplyDialog(ReviewItem review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reply to ${review.userName}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Type official CPO response...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<OperatorService>().replyToReview(review.id, controller.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Post Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperatorService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: op.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sky))
          : Column(
              children: [
                // Top Tab Bar for 6 Consolidated Views
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppColors.sky,
                    labelColor: AppColors.sky,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    tabs: const [
                      Tab(text: '📊 Overview'),
                      Tab(text: '🏢 Station Fleet'),
                      Tab(text: '📅 Bookings & Queue'),
                      Tab(text: '⚡ Live Telemetry'),
                      Tab(text: '🔐 Terminal QR'),
                      Tab(text: '🔧 Diagnostics & KYC'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(op),
                      _buildStationFleetTab(op),
                      _buildBookingsAndQueueTab(op),
                      _buildLiveTelemetryTab(op),
                      _buildTerminalQrTab(op),
                      _buildDiagnosticsAndKycTab(op),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 1: OVERVIEW & KPIS DASHBOARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(OperatorService op) {
    final kpis = op.kpis;
    final stations = op.stations;

    return RefreshIndicator(
      onRefresh: () => op.loadAllOperatorData(),
      color: AppColors.sky,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Station Switcher Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('Real-time CPO operations & grid telemetry', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddStationSheet,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky),
                  icon: const Icon(FluentIcons.add_24_filled, size: 16, color: Colors.black),
                  label: const Text('Add Station', style: TextStyle(color: Colors.black, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4 KPI Summary Cards Grid
            Row(
              children: [
                Expanded(child: _kpiCard('Gross Revenue', '₹${kpis.totalRevenue.toInt()}', FluentIcons.money_24_filled, AppColors.emerald)),
                const SizedBox(width: 12),
                Expanded(child: _kpiCard('Active Charging', '${kpis.activeSessions} Bays', FluentIcons.flash_24_filled, AppColors.sky)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _kpiCard('Energy Delivered', '${kpis.totalEnergyDeliveredKwh} kWh', FluentIcons.battery_charge_24_filled, AppColors.amber)),
                const SizedBox(width: 12),
                Expanded(child: _kpiCard('Fleet Utilization', '${kpis.fleetUtilizationPercent}%', FluentIcons.gauge_24_filled, AppColors.saffron)),
              ],
            ),
            const SizedBox(height: 24),

            // Active Multi-Station Selector Card
            const Text('Select Station Context', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            if (stations.isEmpty)
              GlassContainer(
                child: Center(
                  child: Column(
                    children: [
                      const Text('No stations registered yet', style: TextStyle(color: AppColors.textTertiary)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _showAddStationSheet, child: const Text('+ Add Your First Station')),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: stations.map((s) {
                  final isSelected = op.selectedStation?.id == s.id;
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 8),
                    borderColor: isSelected ? AppColors.sky : AppColors.borderSubtle,
                    backgroundColor: isSelected ? AppColors.sky.withOpacity(0.08) : AppColors.surfaceCard,
                    onTap: () => op.setSelectedStation(s),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected ? FluentIcons.radio_button_24_filled : FluentIcons.radio_button_24_regular,
                              color: isSelected ? AppColors.sky : AppColors.textTertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('${s.city} · ${s.availableConnectors}/${s.connectors.length} Free · ₹${s.baseTariffPerKwh}/kWh',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ),
                          ],
                        ),
                        Text('${s.rating.toStringAsFixed(1)} ⭐', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 2: STATION FLEET & CHARGER PEDESTALS
  // ══════════════════════════════════════════════════════════════
  Widget _buildStationFleetTab(OperatorService op) {
    final stations = op.stations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Station Fleet (${stations.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                onPressed: _showAddStationSheet,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                icon: const Icon(FluentIcons.add_24_filled, size: 16, color: Colors.black),
                label: const Text('Add Station', style: TextStyle(fontSize: 12, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            children: stations.map((s) {
              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('${s.address}, ${s.city}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAddChargerSheet(s),
                          icon: const Icon(FluentIcons.plug_connected_24_filled, size: 14),
                          label: const Text('+ Charger', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pedestals in station
                    const Text('Configured Pedestals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),

                    Column(
                      children: s.connectors.map((c) {
                        final isMaint = c.status == 'MAINTENANCE';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(FluentIcons.flash_24_filled, size: 16, color: c.isAvailable ? AppColors.emerald : AppColors.amber),
                                  const SizedBox(width: 8),
                                  Text('${c.standard} · ${c.maxPowerKw.toInt()} kW', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(c.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.isAvailable ? AppColors.emerald : AppColors.amber)),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: !isMaint,
                                    activeColor: AppColors.emerald,
                                    onChanged: (val) => op.toggleChargerMaintenance(c.id, !val),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 3: UNIVERSAL BOOKINGS & FAIR QUEUE
  // ══════════════════════════════════════════════════════════════
  Widget _buildBookingsAndQueueTab(OperatorService op) {
    final bookings = op.bookings;
    final queue = op.queue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Virtual Queue Management
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fair Virtual Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${queue.length} Waiting', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (queue.isEmpty)
            GlassContainer(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No drivers waiting in queue', style: TextStyle(color: AppColors.textTertiary)),
                ),
              ),
            )
          else
            Column(
              children: queue.map((q) {
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.amber.withOpacity(0.2),
                            child: Text('#${q.position}', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q.driverName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${q.vehicle} · Wait: ~${q.waitMins}m', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(FluentIcons.arrow_up_24_filled, color: AppColors.sky, size: 18),
                            onPressed: () => op.bumpQueuePriority(q.id),
                            tooltip: 'Bump Priority',
                          ),
                          ElevatedButton(
                            onPressed: () => op.callNextDriver(q.id),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 30),
                              backgroundColor: AppColors.emerald,
                            ),
                            child: const Text('Call Next', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Universal Bookings Feed
          const Text('Incoming Universal Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          if (bookings.isEmpty)
            GlassContainer(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No advance slot bookings scheduled', style: TextStyle(color: AppColors.textTertiary)),
                ),
              ),
            )
          else
            Column(
              children: bookings.map((b) {
                final isEmerg = b.isEmergency;
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 8),
                  borderColor: isEmerg ? AppColors.crimson : AppColors.borderSubtle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isEmerg ? AppColors.crimson : AppColors.sky).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(isEmerg ? FluentIcons.shield_alert_24_filled : FluentIcons.calendar_24_filled,
                                color: isEmerg ? AppColors.crimson : AppColors.sky, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(b.userName ?? 'EV Driver', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  if (isEmerg) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.crimson.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('EMERGENCY', style: TextStyle(color: AppColors.crimson, fontSize: 9, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ],
                              ),
                              Text('${b.stationName} · ${b.slotStart.hour}:${b.slotStart.minute.toString().padLeft(2, '0')} - ${b.slotEnd.hour}:${b.slotEnd.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),
                      Text(b.status, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.emerald)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 4: LIVE CHARGING TELEMETRY
  // ══════════════════════════════════════════════════════════════
  Widget _buildLiveTelemetryTab(OperatorService op) {
    final sessions = op.sessions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Active Telemetry Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          if (sessions.isEmpty)
            GlassContainer(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No active charging sessions on your pedestals', style: TextStyle(color: AppColors.textTertiary)),
                ),
              ),
            )
          else
            Column(
              children: sessions.map((s) {
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 14),
                  borderColor: AppColors.sky,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.stationName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text('${s.connectorStandard} · ${s.maxPowerKw.toInt()} kW', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.sky.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Text('⚡ LIVE', style: TextStyle(color: AppColors.sky, fontWeight: FontWeight.w800, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dials Strip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _telemetryTile('Power Output', '${s.livePowerKw} kW'),
                          _telemetryTile('Energy', '${s.energyKwh} kWh'),
                          _telemetryTile('SoC %', '${s.socPercent.toInt()}%'),
                          _telemetryTile('Live Bill', '₹${s.liveCost}'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => op.emergencyStopSession(s.id),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.crimson, side: const BorderSide(color: AppColors.crimson)),
                          icon: const Icon(FluentIcons.stop_24_filled, size: 16),
                          label: const Text('Remote Emergency Stop'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _telemetryTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 5: DYNAMIC STATION QR TERMINAL
  // ══════════════════════════════════════════════════════════════
  Widget _buildTerminalQrTab(OperatorService op) {
    final station = op.selectedStation;
    final token = op.dynamicQrToken ?? 'SAMPLE_TOTP_HMAC_TOKEN_STATION_ARRIVAL';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(station?.name ?? 'URJAA Station Terminal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Display this high-contrast dynamic QR for driver arrival check-in.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),

            DynamicQrView(
              qrToken: token,
              isOccupied: station?.availableConnectors == 0,
              stationName: station?.name ?? 'Charging Hub',
              onRefresh: () => op.refreshStationQr(),
              size: 220,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 6: DIAGNOSTICS, REVIEWS & KYC
  // ══════════════════════════════════════════════════════════════
  Widget _buildDiagnosticsAndKycTab(OperatorService op) {
    final issues = op.issues;
    final reviews = op.reviews;
    final profile = op.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hardware Faults & OCPP Errors
          const Text('OCPP Diagnostics & Faults', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          if (issues.isEmpty)
            GlassContainer(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('All pedestals operating with zero hardware trips', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700)),
                ),
              ),
            )
          else
            Column(
              children: issues.map((i) {
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 8),
                  borderColor: i.isResolved ? AppColors.borderSubtle : AppColors.crimson,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(i.isResolved ? FluentIcons.checkmark_circle_24_filled : FluentIcons.warning_24_filled,
                              color: i.isResolved ? AppColors.emerald : AppColors.crimson, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${i.errorCode} · ${i.chargerId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('${i.stationName} · Tech: ${i.assignedTechnician}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),
                      if (!i.isResolved)
                        ElevatedButton(
                          onPressed: () => op.resolveIssue(i.id),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: const Size(0, 28)),
                          child: const Text('Resolve', style: TextStyle(fontSize: 11)),
                        )
                      else
                        const Text('Resolved', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Driver Reviews
          const Text('Driver Reviews & Ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          Column(
            children: reviews.map((r) {
              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${r.rating} ⭐', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.comment, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    if (r.response != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                        child: Text('CPO Response: ${r.response}', style: const TextStyle(fontSize: 11, color: AppColors.sky)),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _showReplyDialog(r),
                        icon: const Icon(FluentIcons.comment_24_regular, size: 14),
                        label: const Text('Reply to Driver', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // CPO Profile & KYC
          const Text('CPO Profile & KYC Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kycRow('Business Entity', profile?.legalName ?? 'URJAA Partner Ltd'),
                _kycRow('BEE Gov Approval', profile?.govtApprovalNumber ?? 'BEE-CPO-2026-081'),
                _kycRow('GSTIN Status', '${profile?.gstin ?? '29AABCC1234F1Z5'} (Verified)'),
                _kycRow('Settlement Payout', 'Automated Daily Direct UPI/NEFT'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kycRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
