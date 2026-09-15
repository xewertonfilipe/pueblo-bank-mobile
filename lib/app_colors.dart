import 'package:flutter/material.dart';

class AppColors {
  static const int _bluePrimaryValue = 0xFF075985;
  static const MaterialColor primary = MaterialColor(
    _bluePrimaryValue,
    <int, Color>{
      50: Color(0xFFE0F2FE),
      100: Color(0xFFBAE6FD),
      200: Color(0xFF7DD3FC),
      300: Color(0xFF38BDF8),
      400: Color(0xFF0EA5E9),
      500: Color(_bluePrimaryValue),
      600: Color(0xFF0369A1),
      700: Color(0xFF075985),
      800: Color(0xFF0C4A6E),
      900: Color(0xFF082F49),
    },
  );
  static const Color background = Colors.white;
  static const Color shadow = Colors.black12;
  static const Color error = Color(0xFFB42318);
  static const Color success = Color(0xFF15803D);
  static const Color income = Color(0xFF15803D);
  static const Color expense = Color(0xFFB42318);
}
