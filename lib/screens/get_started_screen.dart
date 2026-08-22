import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const _Atmosphere(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandLockup(),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF65D7A5).withValues(alpha: 0.11),
                      border: Border.all(
                          color:
                              const Color(0xFF65D7A5).withValues(alpha: 0.36)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.location_16_filled,
                            size: 15, color: Color(0xFF8DF2C1)),
                        SizedBox(width: 7),
                        Text('INDIA • UNIFIED EV INFRASTRUCTURE',
                            style: TextStyle(
                                color: Color(0xFF9AF3C8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.04,
                        letterSpacing: -1.4,
                      ),
                      children: const [
                        TextSpan(text: 'Charge smarter.\n'),
                        TextSpan(
                            text: 'Travel with ',
                            style: TextStyle(color: Color(0xFFDCE5F3))),
                        TextSpan(
                            text: 'confidence.',
                            style: TextStyle(color: Color(0xFF7DE8B1))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Find dependable charging points, understand availability at a glance, and reserve the connector that fits your journey.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: const Color(0xFFABB7C9), height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  const _TrustRail(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                      icon: const Icon(FluentIcons.arrow_right_24_regular),
                      label: const Text('Get started'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/customer'),
                      child: const Text('Explore charging points first',
                          style: TextStyle(
                              color: Color(0xFFD3DBE9),
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                        'Availability signals are refreshed from connected operators.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF758198))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF65D7A5).withValues(alpha: 0.10),
              border: Border.all(
                  color: const Color(0xFF65D7A5).withValues(alpha: 0.38)),
            ),
            child: const Icon(FluentIcons.flash_24_regular,
                color: Color(0xFF79E6AD)),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHARGEGRID',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4)),
              Text('UNIFIED EV PORTAL',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8390A5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9)),
            ],
          ),
        ],
      );
}

class _TrustRail extends StatelessWidget {
  const _TrustRail();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF101925).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          children: [
            Expanded(child: _TrustMetric(value: 'Live', label: 'availability')),
            _RailDivider(),
            Expanded(
                child: _TrustMetric(value: 'One tap', label: 'to reserve')),
            _RailDivider(),
            Expanded(child: _TrustMetric(value: 'Clear', label: 'reliability')),
          ],
        ),
      );
}

class _TrustMetric extends StatelessWidget {
  final String value;
  final String label;
  const _TrustMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF8AF0BC),
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(color: Color(0xFF8D9AAF), fontSize: 10)),
        ],
      );
}

class _RailDivider extends StatelessWidget {
  const _RailDivider();
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 26, color: Colors.white.withValues(alpha: 0.10));
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071B21), Color(0xFF0B0F17), Color(0xFF121125)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -105,
                right: -90,
                child: _orb(240, const Color(0xFF2DCEA2), 0.17)),
            Positioned(
                bottom: 88,
                left: -120,
                child: _orb(270, const Color(0xFF3E89FF), 0.12)),
            Positioned(
              right: 32,
              top: 130,
              child: Transform.rotate(
                angle: 0.45,
                child: Container(
                    width: 2,
                    height: 370,
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
          ],
        ),
      );

  Widget _orb(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: opacity),
                  blurRadius: 90,
                  spreadRadius: 32)
            ]),
      );
}
