import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const _tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  static TextTheme textTheme(ColorScheme colorScheme) {
    final textColor = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurfaceVariant;

    return TextTheme(
      displaySmall: TextStyle(
        color: textColor,
        fontSize: 32,
        height: 1.18,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: textColor,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontSize: 22,
        height: 1.27,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: textColor,
        fontSize: 16,
        height: 1.38,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        color: mutedColor,
        fontSize: 12,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        color: mutedColor,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        color: mutedColor,
        fontSize: 11,
        height: 1.45,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static TextStyle financialValue(
    TextStyle? base, {
    Color? color,
  }) {
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabularFigures,
    );
  }

  static TextStyle financialPrimary(TextTheme textTheme) {
    return financialValue(textTheme.displaySmall);
  }

  static TextStyle financialCompact(TextTheme textTheme, {Color? color}) {
    return financialValue(textTheme.bodyLarge, color: color);
  }
}
