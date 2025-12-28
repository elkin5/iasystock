// lib/themes/dark_theme.dart
import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  primaryColor: const Color(0xFF086d99),
  scaffoldBackgroundColor: const Color(0xFF2a2a3d),
  // Aclarado de #1c1c2b a #2a2a3d
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF086d99),
    secondary: Color(0xFF1c87c9),
    surface: Color(0xFF3a3a4d),
    // Aclarado de #2a2a3d a #3a3a4d
    surfaceVariant: Color(0xFF4a4a5d),
    // Nuevo color más claro
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xB3FFFFFF),
    // ~white70
    outline: Color(0xFF6a6a7d),
    // Nuevo color para bordes más visibles
    shadow: Color(0x40000000), // Sombra más suave
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFFFFF),
    ),
    displayMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFFFFF), // ← agregado
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFFFFF), // ← opcional, si también lo usas
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF86C5D8),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Color(0xB3FFFFFF),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0x99FFFFFF),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF086d99),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF2a2a3d), // Aclarado para coincidir con scaffold
    selectedItemColor: Color(0xFF086d99),
    unselectedItemColor: Color(0xFF9E9E9E),
  ),
  cardColor: const Color(0xFF3a3a4d),
  // Aclarado para coincidir con surface
  iconTheme: const IconThemeData(
    color: Color(0xFF086d99),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Color(0xFF086d99),
    textTheme: ButtonTextTheme.primary,
  ),
);
