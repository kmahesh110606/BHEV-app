import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import 'sessions_screen.dart';

/// Screen allowing EV drivers to scan rotating kiosk dynamic QR or enter token manually
class QrVerificationScreen extends StatefulWidget {
  final String? initialToken;

  const QrVerificationScreen({super.key, this.initialToken});

  @override
  State<QrVerificationScreen> createState() => _QrVerificationScreenState();
}

class _QrVerificationScreenState extends State<QrVerificationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isVerifying = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter rotating QR security token')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _statusMessage = null;
    });

    final res = await ApiService.verifyArrivalQr(qrToken: token);

    setState(() {
      _isVerifying = false;
      _isSuccess = res['success'] == true;
      _statusMessage = res['message']?.toString();
    });

    if (_isSuccess && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(FluentIcons.checkmark_circle_24_filled, color: AppColors.emerald, size: 28),
              const SizedBox(width: 10),
              const Text('Presence Verified!'),
            ],
          ),
          content: const Text(
            'Physical proof-of-presence confirmed. Charger bay unlocked and live telemetry session initiated.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SessionsScreen()),
                );
              },
              child: const Text('View Live Session'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Top Scanner Simulation Box
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Scanner Overlay Frame
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.emerald, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        FluentIcons.qr_code_24_regular,
                        size: 72,
                        color: AppColors.emerald.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align scanner with Station Kiosk QR',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Manual Token Input
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual TOTP / HMAC Verification',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Paste rotating token string displayed on the kiosk screen if camera scan is unavailable.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _tokenController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'ey...token.signature',
                      prefixIcon: Icon(FluentIcons.key_24_regular, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isVerifying ? null : _handleVerifyToken,
                      icon: _isVerifying
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(FluentIcons.checkmark_circle_24_filled, size: 18),
                      label: const Text('Verify Presence & Start Charge'),
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isSuccess ? AppColors.emerald.withOpacity(0.15) : AppColors.crimson.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isSuccess ? AppColors.emerald.withOpacity(0.3) : AppColors.crimson.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_isSuccess ? FluentIcons.checkmark_circle_24_filled : FluentIcons.dismiss_circle_24_filled,
                        color: _isSuccess ? AppColors.emerald : AppColors.crimson, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(color: _isSuccess ? AppColors.emerald : AppColors.crimson, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
