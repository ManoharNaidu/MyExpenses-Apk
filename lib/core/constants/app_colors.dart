import 'package:flutter/material.dart';

class AppColors {
  // Sapphire Night (Dark Theme)
  static const Color sapphireDark = Color(0xFF1A1B2E); // Deep background
  static const Color sapphireSurface = Color(0xFF25263D); // Card surface
  static const Color sapphirePrimary = Color(0xFF6C5CE7); // Deep violet
  static const Color sapphireSecondary = Color(0xFFA29BFE); // Light lavender
  static const Color sapphireAccent = Color(0xFF00D2D3); // Cyan/Teal
  
  // Aurora Pearl (Light Theme)
  static const Color auroraLight = Color(0xFFF8F9FD); // Soft white background
  static const Color auroraSurface = Colors.white; // Pure white surface
  static const Color auroraPrimary = Color(0xFF4834D4); // Bold royal blue
  static const Color auroraSecondary = Color(0xFF686DE0); // Mid blue
  static const Color auroraAccent = Color(0xFFF0932B); // Vibrant orange
  
  // Semantic Colors
  static const Color expense = Color(0xFFFF7675); // Soft red
  static const Color income = Color(0xFF55E6C1); // Soft green
  
  // Glassmorphism Helpers
  static Color glassWhite(double opacity) => Colors.white.withOpacity(opacity);
  static Color glassBlack(double opacity) => Colors.black.withOpacity(opacity);
  static Color glassSapphire(double opacity) => sapphireDark.withOpacity(opacity);
  
  // Gradients
  static const LinearGradient sapphireGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D2D3), Color(0xFF54A0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
