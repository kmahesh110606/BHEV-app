import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../main.dart';
import '../services/api_service.dart';

class QrVerificationScreen extends StatefulWidget {
  const QrVerificationScreen({super.key});

  @override
  State<QrVerificationScreen> createState() => _QrVerificationScreenState();
}

class _QrVerificationScreenState extends State<QrVerificationScreen> {
  final _api = ApiService(backendBase);
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _verifying = false;
  Map<String, dynamic>? _verified;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_verifying || _verified != null) return;
    final token = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (token == null || token.trim().isEmpty) return;

    setState(() {
      _verifying = true;
      _error = null;
    });
    await _controller.stop();
    try {
      final result = await _api.verifyArrival(token.trim());
      if (mounted) setState(() => _verified = result);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
        await _controller.start();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kiosk QR verification'),
          actions: [
            IconButton(
              tooltip: 'Toggle flash',
              onPressed: _controller.toggleTorch,
              icon: const Icon(FluentIcons.flashlight_24_regular),
            ),
            IconButton(
              tooltip: 'Switch camera',
              onPressed: _controller.switchCamera,
              icon: const Icon(FluentIcons.camera_switch_24_regular),
            ),
          ],
        ),
        body: Stack(children: [
          Positioned.fill(
            child: _verified == null
                ? MobileScanner(
                    controller: _controller,
                    onDetect: _handleCapture,
                  )
                : Container(color: const Color(0xFF0B0F17)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .25),
                    Colors.transparent,
                    Colors.black.withValues(alpha: .72),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 245,
              height: 245,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: _verified == null
                        ? const Color(0xFF65D7A5)
                        : const Color(0xFF88C9FF),
                    width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121B29).withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                ),
                child: _verified == null
                    ? _ScannerInstructions(
                        verifying: _verifying,
                        error: _error,
                      )
                    : _VerifiedPanel(result: _verified!),
              ),
            ),
          )
        ]),
      );
}

class _ScannerInstructions extends StatelessWidget {
  final bool verifying;
  final String? error;

  const _ScannerInstructions({required this.verifying, this.error});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              verifying
                  ? FluentIcons.shield_task_24_regular
                  : FluentIcons.qr_code_24_regular,
              color: const Color(0xFF8DEBBC),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              verifying ? 'Verifying kiosk token...' : 'Scan the kiosk QR',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            )),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Point the camera at the rotating QR shown on the charging kiosk. The app verifies the signed token before charging starts.',
            style: TextStyle(color: Color(0xFFC0CAD8), fontSize: 12, height: 1.4),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!,
                style: const TextStyle(color: Color(0xFFFFAAA4), fontSize: 11)),
          ],
        ],
      );
}

class _VerifiedPanel extends StatelessWidget {
  final Map<String, dynamic> result;

  const _VerifiedPanel({required this.result});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.checkmark_circle_24_filled,
              color: Color(0xFF65D7A5), size: 42),
          const SizedBox(height: 10),
          const Text('Kiosk verified',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(
            'Station ${result['stationId']} • Connector ${result['connectorId']}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB7C4D2), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/sessions'),
              icon: const Icon(FluentIcons.flash_24_regular),
              label: const Text('Open charging session'),
            ),
          ),
        ],
      );
}
