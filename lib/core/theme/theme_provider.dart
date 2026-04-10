import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';

final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider();
});

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    // --- Lucid Ledger Foundation ---
    final backgroundColor = isDark ? AppColors.obsidianAbyss : const Color(0xFFFAFBFD);
    final surfaceColor = isDark ? AppColors.midnightVoid : Colors.white;
    final primaryColor = AppColors.pureMint;
    final secondaryColor = AppColors.coralPop;

    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onSurface: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
      ),

      // --- Lucid Typography: Manrope (Headlines) & Inter (Body) ---
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.manrope(textStyle: baseTextTheme.displayLarge),
        displayMedium: GoogleFonts.manrope(textStyle: baseTextTheme.displayMedium),
        displaySmall: GoogleFonts.manrope(textStyle: baseTextTheme.displaySmall),
        headlineLarge: GoogleFonts.manrope(textStyle: baseTextTheme.headlineLarge, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.manrope(textStyle: baseTextTheme.headlineMedium, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.manrope(textStyle: baseTextTheme.headlineSmall, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.manrope(textStyle: baseTextTheme.titleLarge, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.manrope(textStyle: baseTextTheme.titleMedium, fontWeight: FontWeight.w500),
      ).apply(
        bodyColor: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),

      // --- Shape Rule: 24px Roundness ---
      // --- No-Line Rule: Zero BorderSide ---
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none, // Enforcing No-Line Rule
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.obsidianAbyss.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        indicatorColor: primaryColor.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 72,
        elevation: 0,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: primaryColor, size: 26);
          }
          return IconThemeData(color: isDark ? Colors.white38 : Colors.black38, size: 24);
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? AppColors.obsidianAbyss : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0, // Atmospheric: No harsh shadows
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // No-Line Rule
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3), width: 2), // Ghost border for focus
        ),
      ),
    );
  }



  Future<void> _loadTheme() async {
    final saved = await SecureStorage.readString(_themeKey);
    if (saved == 'dark') {
      _mode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await SecureStorage.writeString(
      _themeKey,
      _mode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}