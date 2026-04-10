import 'package:flutter/material.dart';

class AppColors {
  // --- The Lucid Ledger: Obsidian Foundation ---
  static const Color obsidianAbyss = Color(0xFF0A0C14);      // Atmospheric Background
  static const Color midnightVoid = Color(0xFF121421);       // Surface Depth
  
  // --- The Lucid Ledger: Financial Prism Accents ---
  static const Color pureMint = Color(0xFF00CFB4);           // Primary Highlight (Accent 1)
  static const Color coralPop = Color(0xFFFF6B6B);           // Secondary Glow (Accent 2)
  static const Color electricGold = Color(0xFFFFD166);       // Tertiary Detail
  
  // --- Functional Semantic Colors (Lucid Palette) ---
  static const Color expense = Color(0xFFFF6B6B);            // Coral (Mapped to Accent 2)
  static const Color income = Color(0xFF00CFB4);             // Mint (Mapped to Accent 1)
  static const Color warning = Color(0xFFFFD166);            // Gold
  
  // --- Ambient Effects & Overlays ---
  static Color glass(Color base, double opacity) => base.withOpacity(opacity);
  
  static const List<Color> prismMesh = [
    Color(0xFF00CFB4), // Mint
    Color(0xFFFF6B6B), // Coral
    Color(0xFF121421), // Midnight
    Color(0xFF0A0C14), // Obsidian
  ];

  // --- Glass & Gradient Rule (135° Mint to Coral) ---
  static const LinearGradient lucidGradient = LinearGradient(
    colors: [Color(0xFF00CFB4), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    transform: GradientRotation(2.35619), // 135 degrees (~2.36 radians)
  );

  static const LinearGradient glassOverlay = LinearGradient(
    colors: [
      Color(0x1A00CFB4), // 10% Mint
      Color(0x1AFF6B6B), // 10% Coral
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkFade = LinearGradient(
    colors: [Colors.transparent, Color(0xFF0A0C14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
