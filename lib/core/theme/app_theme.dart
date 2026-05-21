import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: DesignTokens.primary,
          onPrimary: DesignTokens.onPrimary,
          primaryContainer: DesignTokens.primaryContainer,
          onPrimaryContainer: DesignTokens.textPrimary,
          secondary: DesignTokens.bestie,
          onSecondary: DesignTokens.onBestie,
          secondaryContainer: DesignTokens.bestieContainer,
          onSecondaryContainer: DesignTokens.onBestie,
          error: DesignTokens.error,
          onError: Colors.white,
          surface: DesignTokens.surface,
          onSurface: DesignTokens.textPrimary,
          surfaceContainerHighest: DesignTokens.surfaceVariant,
          outline: DesignTokens.outline,
          outlineVariant: DesignTokens.outlineVariant,
        ),
        scaffoldBackgroundColor: DesignTokens.background,
        fontFamily: DesignTokens.fontBody,
        textTheme: _textTheme(DesignTokens.textPrimary),
        appBarTheme: AppBarTheme(
          backgroundColor: DesignTokens.surface,
          foregroundColor: DesignTokens.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: DesignTokens.fontDisplay,
            fontSize: DesignTokens.fontLg,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        cardTheme: CardTheme(
          color: DesignTokens.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            side: const BorderSide(color: DesignTokens.outline, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DesignTokens.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: const BorderSide(color: DesignTokens.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: const BorderSide(color: DesignTokens.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide:
                const BorderSide(color: DesignTokens.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: DesignTokens.textDisabled,
            fontSize: DesignTokens.fontMd,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.primary,
            foregroundColor: DesignTokens.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space24,
              vertical: DesignTokens.space16,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: DesignTokens.surface,
          indicatorColor: DesignTokens.primaryContainer,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: DesignTokens.fontBody,
              fontSize: DesignTokens.fontXs,
              fontWeight: FontWeight.w500,
            ),
          ),
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: DesignTokens.outlineVariant,
          thickness: 1,
          space: 0,
        ),
        extensions: const [InSightThemeExtension.light],
      );

  // ─────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: DesignTokens.primary,
          onPrimary: DesignTokens.onPrimary,
          primaryContainer: Color(0xFF3A5C4A),
          onPrimaryContainer: DesignTokens.darkTextPrimary,
          secondary: DesignTokens.bestie,
          onSecondary: DesignTokens.onBestie,
          secondaryContainer: Color(0xFF5C3D2A),
          onSecondaryContainer: DesignTokens.bestieContainer,
          error: DesignTokens.error,
          onError: Colors.white,
          surface: DesignTokens.darkSurface,
          onSurface: DesignTokens.darkTextPrimary,
          surfaceContainerHighest: DesignTokens.darkSurfaceVariant,
          outline: DesignTokens.darkOutline,
          outlineVariant: DesignTokens.darkSurfaceVariant,
        ),
        scaffoldBackgroundColor: DesignTokens.darkBackground,
        fontFamily: DesignTokens.fontBody,
        textTheme: _textTheme(DesignTokens.darkTextPrimary),
        appBarTheme: AppBarTheme(
          backgroundColor: DesignTokens.darkSurface,
          foregroundColor: DesignTokens.darkTextPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: DesignTokens.fontDisplay,
            fontSize: DesignTokens.fontLg,
            fontWeight: FontWeight.w600,
            color: DesignTokens.darkTextPrimary,
          ),
        ),
        cardTheme: CardTheme(
          color: DesignTokens.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            side: const BorderSide(color: DesignTokens.darkOutline, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DesignTokens.darkSurfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: const BorderSide(color: DesignTokens.darkOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: const BorderSide(color: DesignTokens.darkOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide:
                const BorderSide(color: DesignTokens.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: DesignTokens.darkTextSecondary,
            fontSize: DesignTokens.fontMd,
          ),
        ),
        extensions: const [InSightThemeExtension.dark],
      );

  // ─────────────────────────────────────────
  // SHARED TEXT THEME
  // ─────────────────────────────────────────
  static TextTheme _textTheme(Color textColor) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: DesignTokens.fontDisplay,
          fontSize: DesignTokens.font3xl,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        displayMedium: TextStyle(
          fontFamily: DesignTokens.fontDisplay,
          fontSize: DesignTokens.font2xl,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontFamily: DesignTokens.fontDisplay,
          fontSize: DesignTokens.fontXl,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleMedium: TextStyle(
          fontFamily: DesignTokens.fontBody,
          fontSize: DesignTokens.fontLg,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontFamily: DesignTokens.fontBody,
          fontSize: DesignTokens.fontMd,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: DesignTokens.fontBody,
          fontSize: DesignTokens.fontSm,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        labelLarge: TextStyle(
          fontFamily: DesignTokens.fontBody,
          fontSize: DesignTokens.fontMd,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        labelSmall: TextStyle(
          fontFamily: DesignTokens.fontBody,
          fontSize: DesignTokens.fontXs,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      );
}

// ─────────────────────────────────────────
// THEME EXTENSION — persona-aware tokens
// ─────────────────────────────────────────
class InSightThemeExtension extends ThemeExtension<InSightThemeExtension> {
  final Color bestie;
  final Color bestieContainer;
  final Color mentor;
  final Color mentorContainer;
  final Color soulmate;
  final Color soulmateContainer;
  final Color sosColor;
  final Color quotaFull;
  final Color quotaLow;
  final Color quotaEmpty;

  const InSightThemeExtension({
    required this.bestie,
    required this.bestieContainer,
    required this.mentor,
    required this.mentorContainer,
    required this.soulmate,
    required this.soulmateContainer,
    required this.sosColor,
    required this.quotaFull,
    required this.quotaLow,
    required this.quotaEmpty,
  });

  static const light = InSightThemeExtension(
    bestie: DesignTokens.bestie,
    bestieContainer: DesignTokens.bestieContainer,
    mentor: DesignTokens.mentor,
    mentorContainer: DesignTokens.mentorContainer,
    soulmate: DesignTokens.soulmate,
    soulmateContainer: DesignTokens.soulmateContainer,
    sosColor: DesignTokens.sos,
    quotaFull: DesignTokens.primary,
    quotaLow: DesignTokens.warning,
    quotaEmpty: DesignTokens.error,
  );

  static const dark = InSightThemeExtension(
    bestie: DesignTokens.bestie,
    bestieContainer: Color(0xFF5C3D2A),
    mentor: DesignTokens.mentor,
    mentorContainer: Color(0xFF1E3A4A),
    soulmate: DesignTokens.soulmate,
    soulmateContainer: Color(0xFF3A2A4A),
    sosColor: DesignTokens.sos,
    quotaFull: DesignTokens.primary,
    quotaLow: DesignTokens.warning,
    quotaEmpty: DesignTokens.error,
  );

  @override
  ThemeExtension<InSightThemeExtension> copyWith({
    Color? bestie,
    Color? bestieContainer,
    Color? mentor,
    Color? mentorContainer,
    Color? soulmate,
    Color? soulmateContainer,
    Color? sosColor,
    Color? quotaFull,
    Color? quotaLow,
    Color? quotaEmpty,
  }) {
    return InSightThemeExtension(
      bestie: bestie ?? this.bestie,
      bestieContainer: bestieContainer ?? this.bestieContainer,
      mentor: mentor ?? this.mentor,
      mentorContainer: mentorContainer ?? this.mentorContainer,
      soulmate: soulmate ?? this.soulmate,
      soulmateContainer: soulmateContainer ?? this.soulmateContainer,
      sosColor: sosColor ?? this.sosColor,
      quotaFull: quotaFull ?? this.quotaFull,
      quotaLow: quotaLow ?? this.quotaLow,
      quotaEmpty: quotaEmpty ?? this.quotaEmpty,
    );
  }

  @override
  ThemeExtension<InSightThemeExtension> lerp(
      ThemeExtension<InSightThemeExtension>? other, double t) {
    if (other is! InSightThemeExtension) return this;
    return InSightThemeExtension(
      bestie: Color.lerp(bestie, other.bestie, t)!,
      bestieContainer: Color.lerp(bestieContainer, other.bestieContainer, t)!,
      mentor: Color.lerp(mentor, other.mentor, t)!,
      mentorContainer: Color.lerp(mentorContainer, other.mentorContainer, t)!,
      soulmate: Color.lerp(soulmate, other.soulmate, t)!,
      soulmateContainer:
          Color.lerp(soulmateContainer, other.soulmateContainer, t)!,
      sosColor: Color.lerp(sosColor, other.sosColor, t)!,
      quotaFull: Color.lerp(quotaFull, other.quotaFull, t)!,
      quotaLow: Color.lerp(quotaLow, other.quotaLow, t)!,
      quotaEmpty: Color.lerp(quotaEmpty, other.quotaEmpty, t)!,
    );
  }
}
