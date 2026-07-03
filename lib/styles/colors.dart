import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Colores de marca: se mantienen iguales en claro y oscuro
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFFDD835);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // Variantes CLARO
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color muted = Color(0xFF9CA3AF);

  // Variantes OSCURO
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE5E7EB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color mutedDark = Color(0xFF6B7280);
}