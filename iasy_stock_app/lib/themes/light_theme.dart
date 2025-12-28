// lib/themes/light_theme.dart
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  primaryColor: const Color(0xFF086d99),
  scaffoldBackgroundColor: const Color(0xFFF4F4F9),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF086d99),
    secondary: Color(0xFF1c87c9),
    surface: Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
  ),
  // textTheme: const TextTheme(
  //   displayLarge: TextStyle(
  //     fontSize: 24,
  //     fontWeight: FontWeight.bold,
  //     color: Colors.black87,
  //   ),
  //   titleLarge: TextStyle(
  //     fontSize: 20,
  //     fontWeight: FontWeight.bold,
  //     color: Color(0xFF086d99),
  //   ),
  //   bodyLarge: TextStyle(
  //     fontSize: 16,
  //     color: Colors.black87,
  //   ),
  //   bodyMedium: TextStyle(
  //     fontSize: 14,
  //     color: Color(0xFFB0C4DE),
  //   ),
  // ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black87, // Encabezados visibles
    ),
    displayMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.black87, // Encabezados visibles
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87, // Encabezados visibles
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF086d99), // Color para subtítulos
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Colors.black87, // Texto principal visible
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Colors.black54, // Ajuste para texto secundario
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF086d99),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFF4F4F9),
    selectedItemColor: Color(0xFF086d99),
    unselectedItemColor: Colors.grey,
  ),
  cardColor: const Color(0xFFFFFFFF),
  iconTheme: const IconThemeData(
    color: Color(0xFF086d99),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Color(0xFF086d99),
    textTheme: ButtonTextTheme.primary,
  ),
);
