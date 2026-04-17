import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const bg       = Color(0xFF08080F);
  static const surface  = Color(0xFF0F0F1C);
  static const surface2 = Color(0xFF161626);
  static const aqua     = Color(0xFF00E5FF);
  static const aquaDim  = Color(0xFF00B8CC);
  static const neon     = Color(0xFFCC00FF);
  static const success  = Color(0xFF00E676);
  static const error    = Color(0xFFFF1744);
  static const warn     = Color(0xFFFFD740);
  static const txt1     = Color(0xFFEEF2FF);
  static const txt2     = Color(0xFF6677AA);
  static const txt3     = Color(0xFF334466);
  static const border   = Color(0x12FFFFFF);
  static const card     = Color(0x0EFFFFFF);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.aqua,
      secondary: AppColors.neon,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.scheherazadeNew(
        color: AppColors.txt1,
        fontSize: 40,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.scheherazadeNew(
        color: AppColors.txt1,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.tajawal(color: AppColors.txt1, fontSize: 14),
      bodyMedium: GoogleFonts.tajawal(color: AppColors.txt2, fontSize: 12),
    ),
  );
}
