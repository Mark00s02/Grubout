import 'package:flutter/material.dart';

// ── Brand colours ──────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF2E7D4F);
const kPrimaryDark  = Color(0xFF1F5C39);
const kPrimaryLight = Color(0xFF5FB07E);
const kGold         = Color(0xFFE2A93B);
const kDanger       = Color(0xFFE5484D);

// Macro colours — used consistently in every chart, bar and legend.
const kProteinColor = Color(0xFF4F86F7);
const kCarbsColor   = Color(0xFFD07A16); // validated with protein/fat for CVD + contrast
const kFatColor     = Color(0xFFC2459B);
const kWaterColor   = Color(0xFF3BA7E0);

// ── Meal-type colours ───────────────────────────────────────────────────────
const kBreakfastColor = Color(0xFFF2A33A);
const kLunchColor     = Color(0xFF2E9E5B);
const kDinnerColor    = Color(0xFF8E5CD9);
const kSnacksColor    = Color(0xFFE8607A);

const mealTypes = ['breakfast', 'lunch', 'dinner', 'snacks'];

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
    case 'breakfast': return Icons.wb_twilight_rounded;
    case 'lunch':     return Icons.wb_sunny_rounded;
    case 'dinner':    return Icons.nights_stay_rounded;
    default:          return Icons.cookie_rounded;
  }
}

String mealTypeLabel(String type) =>
    type.isEmpty ? type : type[0].toUpperCase() + type.substring(1).toLowerCase();

/// Theme-aware colours. Use `context.colors.x` instead of hard-coded values so
/// every screen works in both light and dark mode.
class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color track;
  final bool isDark;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.track,
    required this.isDark,
  });

  static const light = AppColors(
    background: Color(0xFFF6F7F3),
    surface:    Colors.white,
    surfaceAlt: Color(0xFFEFF2EC),
    text:       Color(0xFF14201A),
    textMuted:  Color(0xFF6D7A72),
    border:     Color(0xFFE3E8E1),
    track:      Color(0xFFE6EBE4),
    isDark:     false,
  );

  static const dark = AppColors(
    background: Color(0xFF0E1411),
    surface:    Color(0xFF17201B),
    surfaceAlt: Color(0xFF212C25),
    text:       Color(0xFFEDF2EE),
    textMuted:  Color(0xFF93A198),
    border:     Color(0xFF2A362F),
    track:      Color(0xFF2A362F),
    isDark:     true,
  );
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  TextTheme get text => Theme.of(this).textTheme;
}

// ── App theme ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => _build(AppColors.light, Brightness.light);
  static ThemeData get darkTheme => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: brightness,
    ).copyWith(
      primary: c.isDark ? kPrimaryLight : kPrimary,
      onPrimary: Colors.white,
      surface: c.surface,
      onSurface: c.text,
      error: kDanger,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final textTheme = base.textTheme.apply(bodyColor: c.text, displayColor: c.text).copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.5),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.3),
          titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700, color: c.text),
          titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, color: c.text),
          bodySmall: base.textTheme.bodySmall?.copyWith(color: c.textMuted),
        );

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: c.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
        labelStyle: TextStyle(color: c.textMuted),
        prefixIconColor: c.textMuted,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.surfaceAlt,
        selectedColor: scheme.primary,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.isDark ? c.surfaceAlt : const Color(0xFF14201A),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kPrimary : null),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: c.textMuted,
        indicatorColor: scheme.primary,
        dividerColor: c.border,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      listTileTheme: ListTileThemeData(iconColor: c.textMuted),
    );
  }
}
