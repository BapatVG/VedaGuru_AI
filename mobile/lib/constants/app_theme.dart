import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sacred Vedic Palette
  static const Color primarySaffron = Color(0xFFE65100);     // Deep Sacred Saffron
  static const Color primaryLight = Color(0xFFFF833A);       // Bright Saffron
  static const Color primaryDark = Color(0xFFAC1900);        // Vedic Vermilion / Kumkum
  
  static const Color sacredGold = Color(0xFFD4AF37);         // Temple Gold
  static const Color sacredGoldLight = Color(0xFFFFDF73);    // Shimmering Gold
  
  static const Color bgCream = Color(0xFFFCF9F2);            // Clean Parchment / Milk White
  static const Color surfaceCard = Color(0xFFFFFFFF);        // Pure Card Background
  static const Color surfaceElevated = Color(0xFFFFF7EB);    // Warm Gold Tint Card
  
  static const Color textDark = Color(0xFF261C14);           // Deep Espresso / Charcoal
  static const Color textMuted = Color(0xFF75675E);          // Warm Grey Muted
  static const Color textSanskrit = Color(0xFF8B1E0F);       // Sacred Ochre / Red
  static const Color darkBg = Color(0xFF140D07);             // Midnight Mandir
  static const Color darkCard = Color(0xFF22160E);           // Midnight Sanctum Card

  // Sacred Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFFFE082), Color(0xFFAA7A1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient saffronGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFF833A), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient midnightGradient = LinearGradient(
    colors: [Color(0xFF1F1209), Color(0xFF2D180C), Color(0xFF140B06)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration sacredBoxDecoration({Color? bgColor, double radius = 16, bool hasGlow = false}) {
    return BoxDecoration(
      color: bgColor ?? surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: sacredGold.withValues(alpha: 0.35), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: (hasGlow ? sacredGold : primarySaffron).withValues(alpha: hasGlow ? 0.18 : 0.06),
          blurRadius: hasGlow ? 16 : 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySaffron,
        primary: primarySaffron,
        secondary: sacredGold,
        surface: bgCream,
      ),
      scaffoldBackgroundColor: bgCream,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: 1.1,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textDark, height: 1.5),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textMuted, height: 1.4),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 2,
        shadowColor: primarySaffron.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: sacredGold.withValues(alpha: 0.2), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySaffron,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primarySaffron.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: sacredGold.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: sacredGold.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primarySaffron, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
      ),
    );
  }
}
