import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/operator_home_screen.dart';

const backendBase = 'http://10.0.2.2:3000';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF39FF96);
    return MaterialApp(
      title: 'UEI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D0F),
        primaryColor: accent,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(shape: const StadiumBorder())),
      ),
      routes: {
        '/': (ctx) => const LoginScreen(),
        '/customer': (ctx) => const HomeScreen(),
        '/operator': (ctx) => const OperatorHomeScreen(),
      },
      initialRoute: '/',
    );
  }
}
