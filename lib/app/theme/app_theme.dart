import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static const coral = Color(0xFFD82E50);
  static const coralActive = Color(0xFFB51F40);
  static const coralSoft = Color(0xFFFBE5E8);
  static const orange = Color(0xFFF97316);
  static const orangeSoft = Color(0xFFFFE8D5);
  static const yellow = Color(0xFFF6D86B);
  static const yellowSoft = Color(0xFFFFF1C8);
  static const lilac = Color(0xFFDCD5F4);
  static const lilacSoft = Color(0xFFF1EDFC);
  static const canvas = Color(0xFFFFF8E7);
  static const ink = Color(0xFF24201F);
  static const body = Color(0xFF514843);
  static const muted = Color(0xFF706762);
  static const hairline = Color(0xFFE9E0CC);
  static const success = Color(0xFF27734D);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFC13515);

  static final _lightScheme =
      ColorScheme.fromSeed(
        seedColor: coral,
        brightness: Brightness.light,
      ).copyWith(
        primary: coralActive,
        onPrimary: Colors.white,
        primaryContainer: coralSoft,
        onPrimaryContainer: const Color(0xFF3F0012),
        secondary: orange,
        onSecondary: Colors.white,
        secondaryContainer: orangeSoft,
        onSecondaryContainer: const Color(0xFF4A1F00),
        tertiary: yellow,
        onTertiary: const Color(0xFF2D2200),
        tertiaryContainer: yellowSoft,
        onTertiaryContainer: const Color(0xFF251A00),
        surfaceContainerLow: Colors.white,
        surfaceContainer: Colors.white,
        surface: canvas,
        onSurface: ink,
        onSurfaceVariant: body,
        outline: hairline,
        error: error,
        onError: Colors.white,
      );

  static const _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: ink,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'NotoSansThai',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'NotoSansThai',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: body,
    ),
    bodySmall: TextStyle(
      fontFamily: 'NotoSansThai',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: muted,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Prompt',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    labelMedium: TextStyle(
      fontFamily: 'NotoSansThai',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontFamily: 'NotoSansThai',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
  );

  static final light = ThemeData(
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: canvas,
    fontFamily: 'NotoSansThai',
    textTheme: _textTheme,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Prompt',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: AppRadii.field,
        borderSide: BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.field,
        borderSide: BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.field,
        borderSide: BorderSide(color: coral, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.field,
        borderSide: BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadii.field,
        borderSide: BorderSide(color: error, width: 2),
      ),
      labelStyle: TextStyle(color: muted),
      floatingLabelStyle: TextStyle(color: coralActive),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: coralActive,
        foregroundColor: Colors.white,
        disabledBackgroundColor: coralSoft,
        disabledForegroundColor: muted,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
        textStyle: const TextStyle(
          fontFamily: 'Prompt',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: hairline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: coralActive,
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: const BorderSide(color: hairline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: coralSoft,
      disabledColor: const Color(0xFFF4F4F5),
      side: const BorderSide(color: hairline),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(color: ink),
      secondaryLabelStyle: const TextStyle(color: ink),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: canvas,
      indicatorColor: lilacSoft,
      elevation: 0,
      height: 76,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'NotoSansThai',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? coralActive : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? coralActive : muted,
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.hero),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: TextStyle(
        fontFamily: 'NotoSansThai',
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? coral : null,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? coral : null,
      ),
    ),
    dividerTheme: const DividerThemeData(color: hairline),
  );
}
