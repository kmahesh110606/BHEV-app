import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../theme/app_colors.dart';

/// Dynamic QR Code view with 30-second countdown ring and glowing green/red halo
class DynamicQrView extends StatefulWidget {
  final String qrToken;
  final bool isOccupied;
  final String stationName;
  final VoidCallback onRefresh;
  final double size;

  const DynamicQrView({
    super.key,
    required this.qrToken,
    this.isOccupied = false,
    required this.stationName,
    required this.onRefresh,
    this.size = 200,
  });

  @override
  State<DynamicQrView> createState() => _DynamicQrViewState();
}

class _DynamicQrViewState extends State<DynamicQrView> {
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        widget.onRefresh();
        setState(() => _secondsLeft = 30);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DynamicQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrToken != widget.qrToken) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final haloColor = widget.isOccupied ? AppColors.crimson : AppColors.emerald;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Halo QR Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: haloColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: haloColor.withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: widget.qrToken,
                  version: QrVersions.auto,
                  size: widget.size,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF090A0F),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF090A0F),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: haloColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: haloColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isOccupied
                          ? FluentIcons.record_stop_24_filled
                          : FluentIcons.checkmark_circle_24_filled,
                      size: 14,
                      color: haloColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isOccupied
                          ? 'OCCUPIED / IN-USE'
                          : 'READY / OPEN TO SCAN',
                      style: TextStyle(
                        color: haloColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Countdown Timer Ring & Refresh
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: _secondsLeft / 30,
                strokeWidth: 2.5,
                color: AppColors.emerald,
                backgroundColor: AppColors.borderSubtle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Rotating token refreshes in ${_secondsLeft}s',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(FluentIcons.arrow_sync_24_regular, size: 16, color: AppColors.textTertiary),
              onPressed: () {
                widget.onRefresh();
                _startTimer();
              },
              tooltip: 'Force refresh token',
            ),
          ],
        ),
      ],
    );
  }
}
