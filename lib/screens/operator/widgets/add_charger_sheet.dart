import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/operator_service.dart';
import '../../../theme/app_colors.dart';

/// Modal sheet for attaching an additional charger pedestal to an active station
class AddChargerSheet extends StatefulWidget {
  final String stationId;
  final String stationName;

  const AddChargerSheet({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<AddChargerSheet> createState() => _AddChargerSheetState();
}

class _AddChargerSheetState extends State<AddChargerSheet> {
  String _selectedStandard = 'CCS2';
  final _powerController = TextEditingController(text: '60');
  final _tariffController = TextEditingController(text: '14.5');
  final _flatFeeController = TextEditingController(text: '20.0');
  bool _isSubmitting = false;

  final List<String> _standards = ['CCS2', 'Type2', 'GBT_DC', 'GBT_AC', 'CHAdeMO'];

  @override
  void dispose() {
    _powerController.dispose();
    _tariffController.dispose();
    _flatFeeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    final opService = context.read<OperatorService>();
    final success = await opService.addChargerToStation(
      stationId: widget.stationId,
      standard: _selectedStandard,
      maxPowerKw: double.tryParse(_powerController.text.trim()) ?? 60.0,
      pricePerKwh: double.tryParse(_tariffController.text.trim()) ?? 14.5,
      flatFee: double.tryParse(_flatFeeController.text.trim()) ?? 20.0,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pedestal attached and activated!')),
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

          const Text('🔌 Add Charger Pedestal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Station: ${widget.stationName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _selectedStandard,
            decoration: const InputDecoration(labelText: 'Connector Standard'),
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
                  : const Text('Add & Activate Pedestal'),
            ),
          ),
        ],
      ),
    );
  }
}
