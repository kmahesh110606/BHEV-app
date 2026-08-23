import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import 'sessions_screen.dart';

/// Screen allowing EV drivers to scan rotating kiosk dynamic QR with live camera or enter token manually
class QrVerificationScreen extends StatefulWidget {
  final String? initialToken;

  const QrVerificationScreen({super.key, this.initialToken});

  @override
  State<QrVerificationScreen> createState() => _QrVerificationScreenState();
}

class _QrVerificationScreenState extends State<QrVerificationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isVerifying = false;
  String? _statusMessage;
  bool _isSuccess = false;
  bool _hasScanned = false;

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
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || _isVerifying) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() {
          _hasScanned = true;
          _tokenController.text = rawValue;
        });
        _handleVerifyToken(rawValue);
        break;
      }
    }
  }

  Future<void> _handleVerifyToken([String? overrideToken]) async {
    final token = (overrideToken ?? _tokenController.text).trim();
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
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(FluentIcons.checkmark_circle_24_filled, color: AppColors.emerald, size: 28),
              SizedBox(width: 10),
              Text('Presence Verified!'),
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
    } else {
      // Re-enable scanning after 2 seconds if failed
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hasScanned = false);
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _tokenController.text = data.text!;
      _handleVerifyToken(data.text!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Live Camera Viewfinder Box
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.emerald, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // MobileScanner live stream
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),

                    // Viewfinder Target Box Overlay
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.emerald, width: 2.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _cornerDecoration(top: true, left: true),
                              _cornerDecoration(top: true, left: false),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _cornerDecoration(top: false, left: true),
                              _cornerDecoration(top: false, left: false),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Camera Controls Overlay (Torch & Switch)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(FluentIcons.flash_24_filled, size: 18),
                            onPressed: () => _scannerController.toggleTorch(),
                            tooltip: 'Toggle Flashlight',
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(FluentIcons.camera_switch_24_filled, size: 18),
                            onPressed: () => _scannerController.switchCamera(),
                            tooltip: 'Switch Camera',
                          ),
                        ],
                      ),
                    ),

                    // Instruction Pill
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at Station Kiosk Dynamic QR',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Manual Token & Clipboard Input
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manual Security Token Entry',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(FluentIcons.clipboard_paste_24_regular, size: 14, color: AppColors.emerald),
                        label: const Text('Paste', style: TextStyle(fontSize: 11, color: AppColors.emerald)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter rotating TOTP/HMAC token displayed on the kiosk if camera is unavailable.',
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
                      onPressed: _isVerifying ? null : () => _handleVerifyToken(),
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

  Widget _cornerDecoration({required bool top, required bool left}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(8) : Radius.zero,
          topRight: top && !left ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}
