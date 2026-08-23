import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/auth_service.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';

/// User Profile & Account Screen for EV drivers with strict role isolation
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _syncTime;

  @override
  void initState() {
    super.initState();
    _loadCacheStatus();
  }

  Future<void> _loadCacheStatus() async {
    final t = await OfflineCacheService.getLastSyncTime();
    if (mounted) setState(() => _syncTime = t);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final isOperator = auth.isOperator;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            GlassContainer(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (isOperator ? AppColors.sky : AppColors.emerald).withOpacity(0.2),
                    child: Icon(
                      isOperator ? FluentIcons.building_24_filled : FluentIcons.person_24_filled,
                      color: isOperator ? AppColors.sky : AppColors.emerald,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'EV Driver',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'driver@chargegrid.in',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isOperator ? AppColors.sky : AppColors.emerald).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOperator ? '● VERIFIED CPO OPERATOR' : '● VERIFIED EV DRIVER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isOperator ? AppColors.sky : AppColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account & Protocol Info
            const Text('Account & Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            GlassContainer(
              child: Column(
                children: [
                  if (isOperator) ...[
                    _settingTile(
                      icon: FluentIcons.building_24_filled,
                      title: 'CPO Enterprise Console',
                      subtitle: 'Manage your station fleet, live queue, and CPO revenue',
                      trailing: const Icon(FluentIcons.chevron_right_24_regular, size: 16, color: AppColors.textTertiary),
                    ),
                    const Divider(height: 20),
                  ] else ...[
                    _settingTile(
                      icon: FluentIcons.building_24_filled,
                      title: 'Apply for CPO Operator Partnership',
                      subtitle: 'Register private or commercial EV charging stations on URJAA',
                      trailing: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('CPO Registration requires business verification & BEE license.'),
                            ),
                          );
                        },
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.sky, fontSize: 12)),
                      ),
                    ),
                    const Divider(height: 20),
                  ],
                  _settingTile(
                    icon: FluentIcons.cloud_checkmark_24_filled,
                    title: 'Offline Station Dataset',
                    subtitle: _syncTime ?? 'National BEE & CPO stations cached',
                    trailing: IconButton(
                      icon: const Icon(FluentIcons.arrow_sync_24_regular, size: 18, color: AppColors.emerald),
                      onPressed: _loadCacheStatus,
                    ),
                  ),
                  const Divider(height: 20),
                  _settingTile(
                    icon: FluentIcons.shield_checkmark_24_filled,
                    title: 'BEE UEI National Grid Protocol',
                    subtitle: 'Connected to India Open Unified Charging Infrastructure',
                    trailing: const Icon(FluentIcons.checkmark_24_filled, color: AppColors.emerald, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.crimson,
                  side: const BorderSide(color: AppColors.crimson),
                ),
                icon: const Icon(FluentIcons.sign_out_24_filled, size: 18),
                label: const Text('Sign Out of URJAA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.emerald),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
