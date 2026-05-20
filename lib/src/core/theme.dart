import 'package:flutter/material.dart';

final ThemeData whatsappTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF075E54),
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFF25D366)),
  scaffoldBackgroundColor: const Color(0xFFF0F2F5),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF075E54),
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF25D366),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyText1: TextStyle(color: Colors.black87),
    bodyText2: TextStyle(color: Colors.black54),
  ),
);
