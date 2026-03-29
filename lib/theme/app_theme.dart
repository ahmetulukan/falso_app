import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary brand colors
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryGreen = Color(0xFF34A853);
  static const Color primaryOrange = Color(0xFFFF6D00);

  // Background (Light / Ofsayt Style)
  static const Color bgDark = Color(0xFFF8F9FA);      // Main background — very light gray
  static const Color bgCard = Color(0xFFFFFFFF);       // Card background — white
  static const Color bgSurface = Color(0xFFF1F3F5);   // Surface — subtle gray

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);  // Near-black
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textAccent = Color(0xFFFF6D00);    // Orange accent

  // Category card colors
  static const Color categoryBlue = Color(0xFF1A73E8);
  static const Color categoryGreen = Color(0xFF34A853);
  static const Color categoryRed = Color(0xFFEA4335);
  static const Color categoryYellow = Color(0xFFF9AB00);
  static const Color categoryTeal = Color(0xFF0097A7);

  // Feedback
  static const Color correct = Color(0xFF34A853);
  static const Color wrong = Color(0xFFEA4335);
  static const Color warning = Color(0xFFF9AB00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8A50), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF34A853), Color(0xFF1E8E3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Compatibility aliases
  static const Color primaryPurple = primaryBlue;
  static const LinearGradient purpleGradient = primaryGradient;

  // Background gradient — almost flat white
  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgDark, Color(0xFFEEF0F2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryOrange,
        surface: AppColors.bgCard,
        error: AppColors.wrong,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class AppDecorations {
  static BoxDecoration get gradientBox => const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      );

  static BoxDecoration cardBox({Color? color}) => BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration glassBox() => BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      );
}
