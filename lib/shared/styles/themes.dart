import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lyn_palette.dart';

// ─── Dark Theme ────────────────────────────────
ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: LynPalette.indigo,
    onPrimary: Colors.white,
    primaryContainer: LynPalette.indigoDeep,
    onPrimaryContainer: Colors.white,
    secondary: LynPalette.indigoOnDark,
    onSecondary: Colors.white,
    surface: LynPalette.inkRaised,
    onSurface: LynPalette.onDark,
    surfaceContainerHighest: LynPalette.lineDark,
    background: LynPalette.ink,
    onBackground: LynPalette.onDark,
    error: LynPalette.danger,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: LynPalette.ink,
  cardTheme: CardThemeData(
    color: LynPalette.inkRaised,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: LynPalette.lineDark, width: 1),
    ),
  ),
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: LynPalette.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    backgroundColor: LynPalette.ink,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: LynPalette.onDark,
      letterSpacing: 0.5,
    ),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: LynPalette.onDarkSoft),
    actionsIconTheme: IconThemeData(color: LynPalette.onDarkSoft),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: LynPalette.ink,
    unselectedItemColor: LynPalette.subtle,
    selectedItemColor: LynPalette.indigoOnDark,
    type: BottomNavigationBarType.fixed,
    selectedIconTheme: IconThemeData(color: LynPalette.indigoOnDark, size: 24),
    unselectedIconTheme: IconThemeData(color: LynPalette.subtle, size: 24),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: LynPalette.onDark),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: LynPalette.onDark),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LynPalette.onDarkSoft),
    bodyLarge: TextStyle(fontSize: 16, color: LynPalette.onDarkSoft),
    bodyMedium: TextStyle(fontSize: 14, color: LynPalette.onDarkSoft),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LynPalette.subtle),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: LynPalette.inkRaised, elevation: 0),
  dialogTheme: DialogThemeData(
    backgroundColor: LynPalette.inkRaised,
    titleTextStyle: const TextStyle(color: LynPalette.onDark, fontSize: 20, fontWeight: FontWeight.w600),
    contentTextStyle: const TextStyle(color: LynPalette.onDarkSoft, fontSize: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: LynPalette.lineDark, width: 1),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LynPalette.indigoOnDark,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LynPalette.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LynPalette.inkRaised,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LynPalette.lineDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LynPalette.lineDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LynPalette.indigoOnDark, width: 2),
    ),
    labelStyle: const TextStyle(color: LynPalette.onDarkSoft),
    hintStyle: const TextStyle(color: LynPalette.subtle),
  ),
  dividerTheme: const DividerThemeData(color: LynPalette.lineDark, thickness: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: LynPalette.indigoOnDark,
    circularTrackColor: LynPalette.lineDark,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: LynPalette.inkRaised,
    textStyle: const TextStyle(color: LynPalette.onDark),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: LynPalette.lineDark),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: LynPalette.onDarkSoft,
    textColor: LynPalette.onDarkSoft,
    tileColor: Colors.transparent,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: LynPalette.lineDark,
    selectedColor: LynPalette.indigo,
    labelStyle: const TextStyle(color: LynPalette.onDark, fontSize: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: LynPalette.indigo,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  useMaterial3: true,
);

// ─── Light Theme ───────────────────────────────
ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: LynPalette.indigo,
    onPrimary: Colors.white,
    primaryContainer: LynPalette.indigoWash,
    onPrimaryContainer: LynPalette.indigoInk,
    secondary: LynPalette.indigo,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: LynPalette.inkSoft,
    surfaceContainerHighest: LynPalette.mist,
    background: LynPalette.paperSoft,
    onBackground: LynPalette.inkSoft,
    error: LynPalette.danger,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: LynPalette.paperSoft,
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    shadowColor: LynPalette.subtle.withOpacity(0.15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: LynPalette.line, width: 1),
    ),
  ),
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: LynPalette.paperSoft,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: LynPalette.inkSoft,
      letterSpacing: 0.5,
    ),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: LynPalette.inkSoft),
    actionsIconTheme: IconThemeData(color: LynPalette.inkSoft),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    unselectedItemColor: LynPalette.subtle,
    selectedItemColor: LynPalette.indigo,
    type: BottomNavigationBarType.fixed,
    selectedIconTheme: IconThemeData(color: LynPalette.indigo, size: 24),
    unselectedIconTheme: IconThemeData(color: LynPalette.subtle, size: 24),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: LynPalette.ink),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: LynPalette.inkSoft),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LynPalette.inkSoft),
    bodyLarge: TextStyle(fontSize: 16, color: LynPalette.inkSoft),
    bodyMedium: TextStyle(fontSize: 14, color: LynPalette.muted),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LynPalette.subtle),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: LynPalette.paperSoft, elevation: 1),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    titleTextStyle: const TextStyle(color: LynPalette.inkSoft, fontSize: 20, fontWeight: FontWeight.w600),
    contentTextStyle: const TextStyle(color: LynPalette.muted, fontSize: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: LynPalette.line, width: 1),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LynPalette.indigo,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LynPalette.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LynPalette.mist,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LynPalette.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LynPalette.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LynPalette.indigo, width: 2),
    ),
    labelStyle: const TextStyle(color: LynPalette.muted),
    hintStyle: const TextStyle(color: LynPalette.subtle),
  ),
  dividerTheme: const DividerThemeData(color: LynPalette.line, thickness: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: LynPalette.indigo,
    circularTrackColor: LynPalette.line,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: LynPalette.inkSoft),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: LynPalette.line),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: LynPalette.muted,
    textColor: LynPalette.inkSoft,
    tileColor: Colors.transparent,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: LynPalette.mist,
    selectedColor: LynPalette.indigo,
    labelStyle: const TextStyle(color: LynPalette.inkSoft, fontSize: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: LynPalette.indigo,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  canvasColor: LynPalette.mist,
  useMaterial3: true,
);