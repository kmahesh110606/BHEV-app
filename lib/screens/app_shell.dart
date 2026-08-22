import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'sessions_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _DriverHome(onNavigate: (index) => setState(() => _index = index)),
            const HomeScreen(),
            const SessionsScreen(),
            _MoreModule(onSignOut: () {
              AuthService.currentToken = null;
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            }),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          height: 70,
          backgroundColor: const Color(0xFF101722),
          indicatorColor: const Color(0xFF65D7A5).withValues(alpha: 0.17),
          destinations: const [
            NavigationDestination(
                icon: Icon(FluentIcons.home_24_regular),
                selectedIcon: Icon(FluentIcons.home_24_filled),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(FluentIcons.map_24_regular),
                selectedIcon: Icon(FluentIcons.map_24_filled),
                label: 'Discover'),
            NavigationDestination(
                icon: Icon(FluentIcons.flash_24_regular),
                selectedIcon: Icon(FluentIcons.flash_24_filled),
                label: 'Sessions'),
            NavigationDestination(
                icon: Icon(FluentIcons.grid_24_regular),
                selectedIcon: Icon(FluentIcons.grid_24_filled),
                label: 'More'),
          ],
        ),
      );
}

class _DriverHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _DriverHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _AppBrand(),
                const SizedBox(height: 22),
                _HeroPanel(onDiscover: () => onNavigate(1)),
                const SizedBox(height: 22),
                const _SectionTitle(
                    title: 'Your charging toolkit',
                    subtitle:
                        'Everything you need across connected CPO networks'),
                const SizedBox(height: 12),
                _ModuleGrid(onNavigate: onNavigate),
                const SizedBox(height: 24),
                const _SectionTitle(
                    title: 'How CHARGEGRID works',
                    subtitle: 'The same connected journey as the web portal'),
                const SizedBox(height: 12),
                const _JourneyRail(),
                const SizedBox(height: 22),
                const _NetworkBanner(),
              ]),
            ),
          ),
        ]),
      );
}

class _AppBrand extends StatelessWidget {
  const _AppBrand();
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFF65D7A5).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF65D7A5).withValues(alpha: 0.28))),
            child: const Icon(FluentIcons.flash_24_regular,
                color: Color(0xFF82EBB4))),
        const SizedBox(width: 10),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CHARGEGRID',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.4)),
          Text('UNIFIED EV PORTAL',
              style: TextStyle(
                  color: Color(0xFF8B99AD),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8))
        ])),
        IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications are all caught up.'))),
            icon: const Icon(FluentIcons.alert_24_regular,
                color: Color(0xFFA9B5C4))),
      ]);
}

class _HeroPanel extends StatelessWidget {
  final VoidCallback onDiscover;
  const _HeroPanel({required this.onDiscover});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF153E3D),
                Color(0xFF172239),
                Color(0xFF121622)
              ]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: const Color(0xFF74E5AD).withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF50C992).withValues(alpha: 0.08),
                blurRadius: 28,
                spreadRadius: 4)
          ],
        ),
        child: Stack(children: [
          Positioned(
              right: -25,
              top: -30,
              child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF67D8A2).withValues(alpha: 0.10)))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 5),
                  Text('NATIONAL UNIFIED EV FRAMEWORK',
                      style: TextStyle(
                          color: Color(0xFFA3F2C6),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5))
                ])),
            const SizedBox(height: 18),
            const Text('One network for\nevery charge.',
                style: TextStyle(
                    fontSize: 29,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8)),
            const SizedBox(height: 10),
            const Text(
                'Discover reliable chargers, reserve a connector, and manage your energy journey in one place.',
                style: TextStyle(
                    color: Color(0xFFC0CDDB), fontSize: 12, height: 1.45)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
                onPressed: onDiscover,
                icon: const Icon(FluentIcons.search_24_regular),
                label: const Text('Find charging points')),
          ]),
        ]),
      );
}

class _ModuleGrid extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _ModuleGrid({required this.onNavigate});
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.18,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _ModuleTile(
              icon: FluentIcons.map_24_regular,
              color: const Color(0xFF7AE0AF),
              title: 'Discover',
              description: 'Map, filters & live availability',
              onTap: () => onNavigate(1)),
          _ModuleTile(
              icon: FluentIcons.calendar_ltr_24_regular,
              color: const Color(0xFF88C9FF),
              title: 'Reservations',
              description: 'Manage bookings & QR scan',
              onTap: () => Navigator.pushNamed(context, '/bookings')),
          _ModuleTile(
              icon: FluentIcons.flash_24_regular,
              color: const Color(0xFFFFC56B),
              title: 'My Sessions',
              description: 'Energy, cost & payment',
              onTap: () => onNavigate(2)),
          _ModuleTile(
              icon: FluentIcons.qr_code_24_regular,
              color: const Color(0xFFF39BBE),
              title: 'QR Arrival',
              description: 'Camera verification at kiosk',
              onTap: () => Navigator.pushNamed(context, '/scan-kiosk')),
        ],
      );
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;
  const _ModuleTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF121B29),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: color.withValues(alpha: 0.17))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11)),
                        child: Icon(icon, color: color, size: 19)),
                    const Spacer(),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF99A7B9),
                            fontSize: 10,
                            height: 1.3))
                  ]))));
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF99A7B8)))
      ]);
}

class _JourneyRail extends StatelessWidget {
  const _JourneyRail();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: const Color(0xFF121B29),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
        child: const Column(children: [
          _JourneyStep(
              number: '01',
              icon: FluentIcons.search_24_regular,
              title: 'Discover stations',
              detail: 'Search every connected CPO network'),
          _JourneyStep(
              number: '02',
              icon: FluentIcons.calendar_ltr_24_regular,
              title: 'Reserve a slot',
              detail: 'Book an available connector safely'),
          _JourneyStep(
              number: '03',
              icon: FluentIcons.qr_code_24_regular,
              title: 'Verify at arrival',
              detail: 'Use the rotating station QR'),
          _JourneyStep(
              number: '04',
              icon: FluentIcons.flash_24_regular,
              title: 'Track & settle',
              detail: 'Monitor energy and pay in-app'),
        ]),
      );
}

class _JourneyStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String detail;
  const _JourneyStep(
      {required this.number,
      required this.icon,
      required this.title,
      required this.detail});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFF65D7A5).withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10)),
            child: Text(number,
                style: const TextStyle(
                    color: Color(0xFF8CEABC),
                    fontSize: 10,
                    fontWeight: FontWeight.w800))),
        const SizedBox(width: 11),
        Icon(icon, color: const Color(0xFFABC2D7), size: 20),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(detail,
              style: const TextStyle(color: Color(0xFF94A2B6), fontSize: 10))
        ]))
      ]));
}

class _NetworkBanner extends StatelessWidget {
  const _NetworkBanner();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF77B9FF).withValues(alpha: 0.08),
          border: Border.all(
              color: const Color(0xFF77B9FF).withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(18)),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(FluentIcons.shield_24_regular, color: Color(0xFF9ECFFF)),
        SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Interoperability, built in',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          SizedBox(height: 3),
          Text(
              'Your discovery, reservation, QR arrival and session data are designed to work across authorized operators.',
              style: TextStyle(
                  color: Color(0xFFBED8F3), fontSize: 11, height: 1.35))
        ]))
      ]));
}

class _MoreModule extends StatelessWidget {
  final VoidCallback onSignOut;
  const _MoreModule({required this.onSignOut});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(18), children: [
        const _AppBrand(),
        const SizedBox(height: 24),
        const _SectionTitle(
            title: 'More from CHARGEGRID',
            subtitle: 'Your vehicle, security and connected charging tools'),
        const SizedBox(height: 14),
        _MoreOption(
            icon: FluentIcons.qr_code_24_regular,
            title: 'QR arrival verification',
            detail: 'Open camera and verify the kiosk QR',
            color: const Color(0xFFF39BBE),
            onTap: () => Navigator.pushNamed(context, '/scan-kiosk')),
        const _MoreOption(
            icon: FluentIcons.vehicle_car_24_regular,
            title: 'My EV profile',
            detail: 'Vehicle connector and charging preferences',
            color: Color(0xFF83E5B2)),
        const _MoreOption(
            icon: FluentIcons.payment_24_regular,
            title: 'Payments & wallets',
            detail: 'UPI, cards and charging receipts',
            color: Color(0xFFFFC66B)),
        _MoreOption(
            icon: FluentIcons.building_24_regular,
            title: 'Station operator console',
            detail: 'For connected CPO partners',
            color: const Color(0xFF9FCBFF),
            onTap: () => Navigator.pushNamed(context, '/operator')),
        const _MoreOption(
            icon: FluentIcons.question_circle_24_regular,
            title: 'Help & support',
            detail: 'Booking, charging and payment help',
            color: Color(0xFFC5A5FF)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(FluentIcons.sign_out_24_regular),
            label: const Text('Sign out'))
      ]));
}

class _MoreOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final VoidCallback? onTap;
  const _MoreOption(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.color,
      this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: onTap ??
                  () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '$title module is ready for the next connected flow.'))),
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFF121B29),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07))),
                  child: Row(children: [
                    Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                          Text(detail,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF9AA8B9)))
                        ])),
                    const Icon(FluentIcons.chevron_right_24_regular,
                        size: 18, color: Color(0xFF94A3B5))
                  ])))));
}
