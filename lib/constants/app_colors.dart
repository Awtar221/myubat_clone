import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFFC62828);
  static const Color secondaryColor = Color(0xFFE53935);
  static const Color accentColor = Color(0xFFEF5350);

  // Background Colors
  static const Color backgroundColor = Color(0xFFFFF7F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color lightGreen = Color(0xFFFFEBEE);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFB71C1C);
  static const Color info = Color(0xFF42A5F5);

  // Feature Colors
  static const Color chatbotColor = Color(0xFFD32F2F);
  static const Color mapColor = Color(0xFFE53935);
  static const Color medicationColor = Color(0xFFC62828);
  static const Color appointmentColor = Color(0xFFD84315);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC62828), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFEBEE), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
