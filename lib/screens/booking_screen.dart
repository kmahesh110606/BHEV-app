import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _api = ApiService(backendBase);
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.myBookings(driverEmail: AuthService.currentUser?['email']);
      if (mounted) setState(() => _bookings = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My EV Bookings'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(FluentIcons.qr_code_24_regular),
            onPressed: () => Navigator.pushNamed(context, '/scan-kiosk'),
            tooltip: 'Scan Kiosk QR',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
                ? _buildEmptyState()
                : _buildBookingsList(),
      ),
    );
  }

  Widget _buildEmptyState() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(
            _error != null
                ? FluentIcons.error_circle_24_regular
                : FluentIcons.calendar_clock_24_regular,
            size: 64,
            color: _error != null ? const Color(0xFFEF4444) : const Color(0xFF65D7A5),
          ),
          const SizedBox(height: 16),
          Text(
            _error != null ? 'Unable to Load Bookings' : 'No Active Bookings',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error != null
                ? _error!
                : 'Discover and reserve any charging bay across 29,000+ national stations. When you arrive at the station, scan the dynamic QR on the kiosk screen to begin charging.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9BA9BC), height: 1.45),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(FluentIcons.search_24_regular),
            label: const Text('Discover 29,000+ Stations'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/scan-kiosk'),
            icon: const Icon(FluentIcons.qr_code_24_regular),
            label: const Text('Direct Walk-in QR Scanner'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      );

  Widget _buildBookingsList() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final b = _bookings[index];
          final status = b['status']?.toString().toUpperCase() ?? 'CONFIRMED';
          final isArrived = status == 'ARRIVED' || status == 'CHARGING';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isArrived
                    ? const Color(0xFF65D7A5).withValues(alpha: .5)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            color: const Color(0xFF131B28),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isArrived
                              ? const Color(0xFF65D7A5).withValues(alpha: .15)
                              : const Color(0xFF38BDF8).withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isArrived
                                ? const Color(0xFF65D7A5)
                                : const Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        b['bookingRef'] ?? b['id'] ?? '',
                        style: const TextStyle(
                            color: Color(0xFF9BA9BC), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    b['stationName'] ?? 'EV Charging Station',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connector: ${b['connectorStandard'] ?? 'CCS2'} • ${b['vehicleName'] ?? 'EV'}',
                    style: const TextStyle(
                        color: Color(0xFF9BA9BC), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/scan-kiosk'),
                          icon: const Icon(FluentIcons.qr_code_24_regular,
                              size: 18),
                          label: const Text('Scan Kiosk QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (isArrived) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sessions'),
                          icon: const Icon(FluentIcons.flash_24_regular,
                              size: 18),
                          label: const Text('Live Telemetry'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
}
