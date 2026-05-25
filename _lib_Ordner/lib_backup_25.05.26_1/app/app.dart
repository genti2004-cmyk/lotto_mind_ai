import 'package:flutter/material.dart';

import '../navigation/main_navigation_screen.dart';

class LottoApp extends StatelessWidget {
  const LottoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);
    const primaryDark = Color(0xFF1D4ED8);
    const background = Color(0xFFF6F8FC);
    const surface = Colors.white;
    const textPrimary = Color(0xFF111827);
    const textSecondary = Color(0xFF6B7280);
    const border = Color(0xFFE5E7EB);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: surface,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
    );

    return MaterialApp(
      title: 'Lotto Mind AI',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: background,
        textTheme: base.textTheme.copyWith(
          headlineLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textPrimary, height: 1.15),
          headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, height: 1.2),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary, height: 1.2),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, height: 1.2),
          titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary, height: 1.25),
          bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, height: 1.45),
          bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary, height: 1.4),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2),
          labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary, height: 1.2),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: textPrimary,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
          hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border, width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.4)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryDark,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF111827),
          contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
