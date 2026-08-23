import 'package:flutter/material.dart';

/// URJAA Design System Colors — Obsidian Dark, Emerald Accent & Tiranga Tokens
class AppColors {
  // ── Obsidian Dark Theme (Primary Default) ──
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF131720);
  static const Color surfaceCard = Color(0xFF181D2A);
  static const Color surfaceElevated = Color(0xFF1F2636);
  static const Color surfaceHover = Color(0xFF263044);

  // ── Borders ──
  static const Color borderSubtle = Color(0x1AFFFFFF);
  static const Color borderMedium = Color(0x33FFFFFF);
  static const Color borderStrong = Color(0x66FFFFFF);
  static const Color borderAccent = Color(0x4D10B981);

  // ── Emerald Primary Brand Accent ──
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldGlow = Color(0x4010B981);

  // ── Telemetry & Diagnostic Accents ──
  static const Color sky = Color(0xFF38BDF8);
  static const Color skyDark = Color(0xFF0284C7);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color crimson = Color(0xFFEF4444);
  static const Color crimsonGlow = Color(0x40EF4444);

  // ── Typography Colors ──
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF475569);

  // ── Tiranga / National EV Grid Gov Colors ──
  static const Color saffron = Color(0xFFFF9933);
  static const Color saffronDark = Color(0xFFEA580C);
  static const Color indiaNavy = Color(0xFF06038D);
  static const Color indiaGreen = Color(0xFF138808);
  static const Color govSurface = Color(0xFFFFF7ED);

  // ── Gradients ──
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tirangaGradient = LinearGradient(
    colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF181D2A), Color(0xFF131720)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
