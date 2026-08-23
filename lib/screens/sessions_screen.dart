import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../models/session_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';

/// Live Active Charging Sessions Monitor & Payment Checkout Screen
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  SessionModel? _activeSession;
  List<SessionModel> _history = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchActiveSessionSilently());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    final active = await ApiService.getActiveSession();
    final history = await ApiService.getSessionHistory();
    if (mounted) {
      setState(() {
        _activeSession = active;
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchActiveSessionSilently() async {
    final active = await ApiService.getActiveSession();
    if (mounted && active != _activeSession) {
      setState(() => _activeSession = active);
    }
  }

  Future<void> _handleStopSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stop Charging Session?'),
        content: const Text('This will terminate DC fast power delivery and calculate the final itemized bill for checkout.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            child: const Text('Stop Charging'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.stopSession(sessionId);
      await _fetchSessions();
    }
  }

  void _showPaymentModal(SessionModel session) {
    String selectedMethod = 'UPI';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Text('Pay Charging Invoice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Session ID: ${session.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 20),

                // Itemized Bill Card
                GlassContainer(
                  child: Column(
                    children: [
                      _invoiceRow('Delivered Energy', '${session.energyKwh} kWh'),
                      _invoiceRow('Base Energy Charge', '₹${session.baseEnergyCost}'),
                      _invoiceRow('Connection Flat Fee', '₹${session.flatConnectionFee}'),
                      _invoiceRow('GST (18%)', '₹${session.gst18}'),
                      const Divider(height: 20),
                      _invoiceRow('Total Amount Due', '₹${session.liveCost} INR', isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Select Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                // Payment Options (UPI, Card, Wallet)
                Row(
                  children: [
                    _paymentMethodChip('UPI (GPay/PhonePe)', 'UPI', selectedMethod, () => setModalState(() => selectedMethod = 'UPI')),
                    const SizedBox(width: 8),
                    _paymentMethodChip('Card', 'CARD', selectedMethod, () => setModalState(() => selectedMethod = 'CARD')),
                    const SizedBox(width: 8),
                    _paymentMethodChip('Wallet', 'WALLET', selectedMethod, () => setModalState(() => selectedMethod = 'WALLET')),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setModalState(() => isProcessing = true);
                            final res = await ApiService.paySession(
                              sessionId: session.id,
                              paymentMethod: selectedMethod,
                            );
                            setModalState(() => isProcessing = false);

                            if (res['success'] == true && mounted) {
                              Navigator.pop(ctx);
                              _fetchSessions();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Payment verified! Thank you for charging with URJAA.')),
                              );
                            }
                          },
                    child: isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text('Pay ₹${session.liveCost} via $selectedMethod'),
                  ),
                ),
              ],
            ),
          );
        },
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

  Widget _paymentMethodChip(String label, String value, String selected, VoidCallback onTap) {
    final isSel = selected == value;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? AppColors.emerald.withOpacity(0.15) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? AppColors.emerald : AppColors.borderSubtle),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? AppColors.emerald : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _activeSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : RefreshIndicator(
              onRefresh: _fetchSessions,
              color: AppColors.emerald,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Session Section
                    if (session != null) ...[
                      const Row(
                        children: [
                          Icon(FluentIcons.flash_24_filled, color: AppColors.emerald, size: 20),
                          SizedBox(width: 8),
                          Text('Active Charging Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Live Charging Card
                      GlassContainer(
                        borderColor: AppColors.emerald,
                        backgroundColor: AppColors.emerald.withOpacity(0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(session.stationName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('${session.connectorStandard} · Up to ${session.maxPowerKw.toInt()} kW',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.sky.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(FluentIcons.record_stop_24_filled, color: AppColors.sky, size: 12),
                                      SizedBox(width: 4),
                                      Text('⚡ CHARGING', style: TextStyle(color: AppColors.sky, fontWeight: FontWeight.w800, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Battery SoC Progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Battery SoC', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text('${session.socPercent.toInt()}% · Pack ${session.batteryTempC}°C',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sky, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: session.socPercent / 100,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceElevated,
                                color: AppColors.sky,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 3-Metric Dial Strip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _telemetryDial('Power Rate', '${session.livePowerKw} kW'),
                                _telemetryDial('Delivered', '${session.energyKwh} kWh'),
                                _telemetryDial('Elapsed', '${session.durationMinutes}m'),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Live Cost Meter
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Live Running Cost', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                      Text('incl. 18% GST', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    ],
                                  ),
                                  Text(
                                    '₹${session.liveCost.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.emerald),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Stop Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleStopSession(session.id),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                                icon: const Icon(FluentIcons.stop_24_filled, size: 18, color: Colors.white),
                                label: const Text('Stop Charging & Pay', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      GlassContainer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(FluentIcons.flash_off_24_regular, size: 40, color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                const Text('No Active Charging Session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 4),
                                const Text('Reserve a slot or scan kiosk dynamic QR to start.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Session Ledger & Invoices
                    const Text('Session Invoices & History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No past charging sessions recorded', style: TextStyle(color: AppColors.textTertiary))),
                      )
                    else
                      Column(
                        children: _history.map((s) {
                          final isPaid = s.isPaid;
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPaid ? AppColors.emerald.withOpacity(0.15) : AppColors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isPaid ? FluentIcons.receipt_24_filled : FluentIcons.money_24_filled,
                                    color: isPaid ? AppColors.emerald : AppColors.amber,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.stationName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('${s.energyKwh} kWh · ${s.durationMinutes} mins · ${s.startTime.day}/${s.startTime.month}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${s.liveCost}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    if (!isPaid)
                                      ElevatedButton(
                                        onPressed: () => _showPaymentModal(s),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: const Size(0, 26),
                                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                        child: const Text('Pay Now'),
                                      )
                                    else
                                      const Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _telemetryDial(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }
}
