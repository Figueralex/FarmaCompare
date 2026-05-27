import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1E88E5), // Azul acento sutil (médico)
      scaffoldBackgroundColor: Colors.white, // Blanco puro
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E88E5),
        secondary: Color(0xFF00ACC1),
        background: Colors.white,
        surface: Colors.white,
      ),
      fontFamily: 'Inter', // Fuente moderna, si está disponible, o Roboto por defecto
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50], // Casi blanco
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }
}
