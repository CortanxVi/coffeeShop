import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ──────────────────────────────
  static const Color primary = Color(0xFF4A2C17); // espresso
  static const Color primaryLight = Color(0xFF7B4F2E); // latte
  static const Color accent = Color(0xFFD4A96A); // caramel
  static const Color accentLight = Color(0xFFF5DEB3); // wheat
  static const Color background = Color(0xFFFDF6EE); // cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C1A0E);
  static const Color textMedium = Color(0xFF6B4C35);
  static const Color textLight = Color(0xFF9E7B5F);
  static const Color error = Color(0xFFB94040);
  static const Color success = Color(0xFF4A7C59);

  // ── TextStyles ────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textMedium,
    height: 1.5,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textMedium,
  );

  // ── Input Decoration ─────────────────────
  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryLight, size: 20),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: textLight, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primaryLight, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFFAF3EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
    );
  }

  // ── Buttons ───────────────────────────────
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    padding: const EdgeInsets.symmetric(vertical: 14),
  );

  static ButtonStyle outlineButton(Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(vertical: 12),
  );

  // ── ThemeData ─────────────────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    chipTheme: ChipThemeData(
      backgroundColor: accentLight,
      selectedColor: primary,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: Colors.transparent),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: accentLight, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  // ── Decorations ───────────────────────────
  static BoxDecoration get pageBackground =>
      const BoxDecoration(color: background);

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ── Logo / Header Widget ──────────────────
  static Widget cafeHeader({String? subtitle}) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.coffee, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 14),
        const Text('WanWan Café', style: headingLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: bodyMedium),
        ],
      ],
    );
  }

  // ── Social Button ─────────────────────────
  static Widget socialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: outlineButton(color),
        icon: Icon(icon, size: 18, color: color),
        label: Text('Sign in with $label'),
        onPressed: onPressed,
      ),
    );
  }

  // ── Divider with text ─────────────────────
  static Widget orDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('หรือ', style: bodyMedium.copyWith(color: textLight)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
