import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFFAF8FF);
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2373F4);
  static const secondary = Color(0xFF578EF5);
  static const cyan = Color(0xFF65D0F4);
  static const accent = Color(0xFFF2F7A0);
  static const ink = Color(0xFF131B2E);
  static const muted = Color(0xFF727786);
  static const border = Color(0xFFE2E4F0);
  static const paleBlue = Color(0xFFEEF1FF);
  static const paleCyan = Color(0xFFE4F8FD);
  static const expenseMine = Color.from(
    alpha: 0.3,
    red: 0.847,
    green: 0.788,
    blue: 0.98,
  );
  static const expenseMineBadge = Color(0xFFD8C9FA);
  static const danger = Color(0xFFBE3434);
  static const success = Color(0xFF16835D);
}

abstract final class AppRadii {
  static const card = 18.0;
  static const control = 13.0;
  static const pill = 999.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.white,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: Colors.transparent,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'sans-serif',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'sans-serif',
        color: AppColors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
