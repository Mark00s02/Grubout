import 'package:flutter/material.dart';

// ── Brand colours ──────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF3D7A48);
const kPrimaryLight = Color(0xFF5A9E68);
const kDark         = Color(0xFF1A1A1A);
const kBg           = Color(0xFFF5F5F5);
const kCard         = Colors.white;
const kGrey         = Color(0xFF9E9E9E);
const kLightGrey    = Color(0xFFE8E8E8);
const kDivider      = Color(0xFFEEEEEE);

// ── Meal-type colours ───────────────────────────────────────────────────────
const kBreakfastColor = Color(0xFFFF9800);
const kLunchColor     = Color(0xFF4CAF50);
const kDinnerColor    = Color(0xFF9C27B0);
const kSnacksColor    = Color(0xFFE91E63);

Color mealTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'breakfast': return kBreakfastColor;
    case 'lunch':     return kLunchColor;
    case 'dinner':    return kDinnerColor;
    default:          return kSnacksColor;
  }
}

IconData mealTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'breakfast': return Icons.free_breakfast;
    case 'lunch':     return Icons.lunch_dining;
    case 'dinner':    return Icons.dinner_dining;
    default:          return Icons.apple;
  }
}

// Keep for any code that still references it — returns empty string now.
String mealTypeEmoji(String _) => '';

// ── App theme ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaceColor   = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor        = isDark ? const Color(0xFF2A2A2A) : kBg;
    final textColor      = isDark ? const Color(0xFFF0F0F0) : kDark;
    final hintColor      = isDark ? const Color(0xFF888888) : kGrey;
    final dividerColor   = isDark ? const Color(0xFF333333) : kDivider;
    final scaffoldBg     = isDark ? const Color(0xFF121212) : Colors.white;

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      fontFamily: 'Roboto',
      primaryColor: kPrimary,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: surfaceColor,
      dividerColor: dividerColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        primary: kPrimary,
        brightness: brightness,
        surface: surfaceColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: kPrimary,
        unselectedItemColor: hintColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(backgroundColor: surfaceColor),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
