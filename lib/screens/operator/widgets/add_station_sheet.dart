import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../../services/operator_service.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';

/// Modal sheet for deploying a new EV charging station to the national URJAA grid
class AddStationSheet extends StatefulWidget {
  const AddStationSheet({super.key});

  @override
  State<AddStationSheet> createState() => _AddStationSheetState();
}

class _AddStationSheetState extends State<AddStationSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bengaluru');
  final _stateController = TextEditingController(text: 'Karnataka');
  final _pincodeController = TextEditingController(text: '560001');
  final _latController = TextEditingController(text: '12.9716');
  final _lngController = TextEditingController(text: '77.5946');
  final _powerController = TextEditingController(text: '60');
  final _tariffController = TextEditingController(text: '14.5');
  final _flatFeeController = TextEditingController(text: '20.0');

  String _selectedStandard = 'CCS2';
  bool _isSubmitting = false;

  final List<String> _standards = ['CCS2', 'Type2', 'GBT_DC', 'GBT_AC', 'CHAdeMO'];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _powerController.dispose();
    _tariffController.dispose();
    _flatFeeController.dispose();
    super.dispose();
  }

  Future<void> _handleUseGpsLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 GPS Coordinates detected and filled!')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (name.isEmpty || address.isEmpty || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required station details and coordinates')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final opService = context.read<OperatorService>();
    final success = await opService.addStation(
      name: name,
      address: address,
      city: city,
      state: state,
      pincode: _pincodeController.text.trim(),
      latitude: lat,
      longitude: lng,
      connectorStandard: _selectedStandard,
      maxPowerKw: double.tryParse(_powerController.text.trim()) ?? 60.0,
      pricePerKwh: double.tryParse(_tariffController.text.trim()) ?? 14.5,
      flatFee: double.tryParse(_flatFeeController.text.trim()) ?? 20.0,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Station successfully deployed to URJAA Grid!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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

            const Text(
              '➕ Deploy New Charging Station',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add station coordinates, charger pedestal standard, and tariff rules.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Station Name', hintText: 'e.g. Koramangala HyperCharge DC Hub'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Street Address', hintText: 'e.g. 80 Feet Road, 4th Block'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _pincodeController, decoration: const InputDecoration(labelText: 'Pincode'))),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: TextField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude'))),
              ],
            ),
            const SizedBox(height: 8),

            TextButton.icon(
              onPressed: _handleUseGpsLocation,
              icon: const Icon(FluentIcons.location_24_filled, size: 16, color: AppColors.emerald),
              label: const Text('📍 Use Current Device GPS Coordinates', style: TextStyle(color: AppColors.emerald, fontSize: 12)),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _selectedStandard,
              decoration: const InputDecoration(labelText: 'Primary Charger Standard'),
              items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedStandard = val ?? 'CCS2'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: TextField(controller: _powerController, decoration: const InputDecoration(labelText: 'Power (kW)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _tariffController, decoration: const InputDecoration(labelText: 'Rate (₹/kWh)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _flatFeeController, decoration: const InputDecoration(labelText: 'Flat Fee (₹)'))),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Deploy & Publish Station'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
