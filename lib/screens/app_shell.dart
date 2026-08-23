import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'qr_verification_screen.dart';
import 'sessions_screen.dart';
import 'kiosk_screen.dart';
import 'profile_screen.dart';
import 'operator/operator_home_screen.dart';
import 'login_screen.dart';

/// Dynamic App Shell providing bottom navigation and strict role-based access control
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _operatorViewActive = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final hasCpoRole = auth.isOperator; // true ONLY if role == 'operator' || role == 'admin'

    // Driver Navigation Screens (Strictly for Customer/Driver mode)
    final List<Widget> driverScreens = [
      const HomeScreen(),
      const QrVerificationScreen(),
      const SessionsScreen(),
      const ProfileScreen(),
    ];

    // Operator Navigation Screens (Strictly for CPO Operators)
    final List<Widget> operatorScreens = [
      const OperatorHomeScreen(),
      const KioskScreen(),
      const SessionsScreen(),
      const HomeScreen(),
    ];

    // If user is a normal customer, they NEVER get operator mode
    final isShowingOperator = hasCpoRole && _operatorViewActive;
    final currentScreens = isShowingOperator ? operatorScreens : driverScreens;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isShowingOperator ? AppColors.sky.withOpacity(0.15) : AppColors.emerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isShowingOperator ? FluentIcons.building_24_filled : FluentIcons.flash_24_filled,
                color: isShowingOperator ? AppColors.sky : AppColors.emerald,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'URJAA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isShowingOperator ? AppColors.sky.withOpacity(0.2) : AppColors.emerald.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isShowingOperator ? 'CPO OPERATOR' : 'EV DRIVER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isShowingOperator ? AppColors.sky : AppColors.emerald,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  user?.name ?? (isShowingOperator ? 'CPO Control Room' : 'National EV Grid'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Role Quick Switcher Pill: Shown ONLY to verified CPOs / Admins
          if (hasCpoRole)
            TextButton.icon(
              onPressed: () => setState(() => _operatorViewActive = !_operatorViewActive),
              icon: Icon(
                isShowingOperator ? FluentIcons.vehicle_car_profile_24_filled : FluentIcons.building_24_filled,
                size: 16,
                color: isShowingOperator ? AppColors.emerald : AppColors.sky,
              ),
              label: Text(
                isShowingOperator ? 'Driver View' : 'CPO Console',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isShowingOperator ? AppColors.emerald : AppColors.sky,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(FluentIcons.sign_out_24_regular, size: 20, color: AppColors.textTertiary),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex < currentScreens.length ? _currentIndex : 0,
        children: currentScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < currentScreens.length ? _currentIndex : 0,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: isShowingOperator
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.building_24_regular),
                  activeIcon: Icon(FluentIcons.building_24_filled),
                  label: 'Console',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.gauge_24_regular),
                  activeIcon: Icon(FluentIcons.gauge_24_filled),
                  label: 'Kiosk',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.receipt_24_regular),
                  activeIcon: Icon(FluentIcons.receipt_24_filled),
                  label: 'Sessions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.map_24_regular),
                  activeIcon: Icon(FluentIcons.map_24_filled),
                  label: 'Stations',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.map_24_regular),
                  activeIcon: Icon(FluentIcons.map_24_filled),
                  label: 'Discover',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.qr_code_24_regular),
                  activeIcon: Icon(FluentIcons.qr_code_24_filled),
                  label: 'Scan QR',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.flash_24_regular),
                  activeIcon: Icon(FluentIcons.flash_24_filled),
                  label: 'Charging',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.person_24_regular),
                  activeIcon: Icon(FluentIcons.person_24_filled),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}
