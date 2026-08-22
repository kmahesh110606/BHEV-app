import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/booking_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'screens/operator_home_screen.dart';
import 'screens/kiosk_screen.dart';
import 'screens/qr_verification_screen.dart';
import 'screens/sessions_screen.dart';

import 'screens/trip_planner_screen.dart';

const backendBase = String.fromEnvironment(
  'CHARGEGRID_API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF65D7A5);
    const ink = Color(0xFF0B0F17);
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'CHARGEGRID',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: mint,
          brightness: Brightness.dark,
          surface: const Color(0xFF111723),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).apply(
          bodyColor: const Color(0xFFF5F7FA),
          displayColor: const Color(0xFFF5F7FA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF5F7FA),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          hintStyle: const TextStyle(color: Color(0xFF95A1B7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: mint, width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mint,
            foregroundColor: const Color(0xFF062118),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      routes: {
        '/': (ctx) => const GetStartedScreen(),
        '/sign-in': (ctx) => const LoginScreen(),
        '/customer': (ctx) => const AppShell(),
        '/operator': (ctx) => const OperatorHomeScreen(),
        '/kiosk': (ctx) => const KioskScreen(),
        '/bookings': (ctx) => const BookingScreen(),
        '/scan-kiosk': (ctx) => const QrVerificationScreen(),
        '/sessions': (ctx) => const SessionsScreen(),
        '/trip-planner': (ctx) => const TripPlannerScreen(),
      },
      initialRoute: '/',
    );
  }
}
