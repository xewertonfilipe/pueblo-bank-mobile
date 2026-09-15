import 'package:flutter/material.dart';

import 'app_typography.dart';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF075985),
  );

  return ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'Manrope',
    fontFamilyFallback: const ['sans-serif'],
    textTheme: AppTypography.textTheme(colorScheme),
    useMaterial3: true,
  );
}
