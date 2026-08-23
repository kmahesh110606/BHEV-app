import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../models/station_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';

/// Slot Booking Screen for atomic reservation on the open UEI network
class BookingScreen extends StatefulWidget {
  final StationModel station;

  const BookingScreen({super.key, required this.station});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDurationMins = 30;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  ConnectorModel? _selectedConnector;
  bool _isEmergency = false;
  bool _isSubmitting = false;

  final List<int> _durations = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    if (widget.station.connectors.isNotEmpty) {
      _selectedConnector = widget.station.connectors.firstWhere(
        (c) => c.isAvailable,
        orElse: () => widget.station.connectors.first,
      );
    }
  }

  double get _estimatedEnergyKwh {
    final powerKw = _selectedConnector?.maxPowerKw ?? 60.0;
    return (powerKw * (_selectedDurationMins / 60.0)) * 0.85; // 85% average taper
  }

  double get _estimatedCost {
    final rate = _selectedConnector?.tariff?.pricePerKwh ?? widget.station.baseTariffPerKwh;
    final flat = _selectedConnector?.tariff?.flatFee ?? widget.station.connectionFlatFee;
    return (_estimatedEnergyKwh * rate) + flat;
  }

  Future<void> _handleBookSlot() async {
    if (_selectedConnector == null) return;
    setState(() => _isSubmitting = true);

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final end = start.add(Duration(minutes: _selectedDurationMins));

    final booking = await ApiService.createBooking(
      locationId: widget.station.id,
      connectorId: _selectedConnector!.id,
      slotStart: start,
      slotEnd: end,
      vehicleType: _isEmergency ? 'EMERGENCY' : 'EV',
    );

    setState(() => _isSubmitting = false);

    if (booking != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(FluentIcons.checkmark_circle_24_filled, color: AppColors.emerald, size: 28),
              const SizedBox(width: 10),
              const Text('Slot Reserved!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking Ref: ${booking.bookingRef}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emerald)),
              const SizedBox(height: 8),
              Text('Station: ${widget.station.name}'),
              Text('Bay: ${_selectedConnector!.standard} (${_selectedConnector!.maxPowerKw.toInt()} kW)'),
              Text('Time: ${booking.slotStart.hour}:${booking.slotStart.minute.toString().padLeft(2, '0')} - ${booking.slotEnd.hour}:${booking.slotEnd.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 12),
              const Text(
                'Please arrive at the kiosk and scan the dynamic QR code within your slot window to begin charging.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to details or home
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to reserve slot. Bay might be occupied or network offline.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reserve Charging Slot', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Mini Header
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FluentIcons.flash_24_filled, color: AppColors.emerald, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.station.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${widget.station.city} · Rate: ₹${widget.station.baseTariffPerKwh}/kWh',
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Connector Bay
            const Text('Select Connector Bay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Column(
              children: widget.station.connectors.map((c) {
                final isSelected = _selectedConnector?.id == c.id;
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 8),
                  borderColor: isSelected ? AppColors.emerald : AppColors.borderSubtle,
                  backgroundColor: isSelected ? AppColors.emerald.withOpacity(0.08) : AppColors.surfaceCard,
                  onTap: () => setState(() => _selectedConnector = c),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? FluentIcons.radio_button_24_filled : FluentIcons.radio_button_24_regular,
                            color: isSelected ? AppColors.emerald : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text('${c.standard} (${c.maxPowerKw.toInt()} kW ${c.powerType})',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      Text(
                        c.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: c.isAvailable ? AppColors.emerald : AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Duration Selector
            const Text('Estimated Session Duration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: _durations.map((d) {
                final isSelected = _selectedDurationMins == d;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Center(child: Text('${d}m')),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedDurationMins = d),
                      selectedColor: AppColors.emerald,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isSelected ? AppColors.emerald : AppColors.borderSubtle),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Emergency Fleet Override Toggle
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(FluentIcons.warning_24_filled, color: AppColors.crimson, size: 20),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Fleet Vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('Ambulance / Municipal fast pre-emption', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isEmergency,
                    onChanged: (val) => setState(() => _isEmergency = val),
                    activeColor: AppColors.crimson,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cost & Energy Summary Box
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderColor: AppColors.borderAccent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Delivered Energy', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('~${_estimatedEnergyKwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Energy Tariff', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₹${widget.station.baseTariffPerKwh}/kWh',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Connection Flat Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₹${widget.station.connectionFlatFee.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Total Bill', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(
                        '₹${_estimatedCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.emerald),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleBookSlot,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Confirm Reservation'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
