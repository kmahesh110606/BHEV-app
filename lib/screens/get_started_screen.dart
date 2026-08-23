import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

/// Animated welcome & onboarding screen highlighting URJAA capabilities
class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Unified Open EV Infrastructure',
      'subtitle': 'One universal account across India. Discover 10,000+ public and commercial DC fast charging stations.',
      'icon': FluentIcons.vehicle_car_profile_24_filled,
      'color': AppColors.emerald,
    },
    {
      'title': 'Dynamic QR Check-in',
      'subtitle': 'Scan rotating HMAC security tokens directly on charger kiosks for instant physical proof-of-presence.',
      'icon': FluentIcons.qr_code_24_filled,
      'color': AppColors.sky,
    },
    {
      'title': 'Live Telemetry & Fair Queue',
      'subtitle': 'Monitor real-time SoC%, power delivery, and transparent ₹/kWh rates. Join virtual lines when bays are full.',
      'icon': FluentIcons.flash_24_filled,
      'color': AppColors.amber,
    },
    {
      'title': 'URJAA CPO Operator Console',
      'subtitle': 'Complete enterprise suite for station managers: multi-station fleet, telemetry, queues, and UPI settlements.',
      'icon': FluentIcons.building_24_filled,
      'color': AppColors.saffron,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(FluentIcons.flash_24_filled, color: AppColors.emerald, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'URJAA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.03,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Skip', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                ],
              ),

              // Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, idx) {
                    final slide = _slides[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (slide['color'] as Color).withOpacity(0.12),
                            border: Border.all(color: (slide['color'] as Color).withOpacity(0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: (slide['color'] as Color).withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(slide['icon'] as IconData, size: 54, color: slide['color'] as Color),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.03,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (idx) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == idx ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == idx ? AppColors.emerald : AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: Text(_currentPage == _slides.length - 1 ? 'Get Started' : 'Continue'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
