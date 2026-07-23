import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';

// ─── Dark Theme ────────────────────────────────
ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF6366F1),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF4338CA),
    onPrimaryContainer: Colors.white,
    secondary: const Color(0xFF818CF8),
    onSecondary: Colors.white,
    surface: const Color(0xFF1E293B),
    onSurface: const Color(0xFFF1F5F9),
    surfaceContainerHighest: const Color(0xFF334155),
    background: const Color(0xFF0F172A),
    onBackground: const Color(0xFFF1F5F9),
    error: const Color(0xFFEF4444),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E293B),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF334155), width: 1),
    ),
  ),
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    backgroundColor: Color(0xFF0F172A),
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Color(0xFFF1F5F9),
      letterSpacing: 0.5,
    ),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
    actionsIconTheme: IconThemeData(color: Color(0xFF94A3B8)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0F172A),
    unselectedItemColor: Color(0xFF64748B),
    selectedItemColor: Color(0xFF818CF8),
    type: BottomNavigationBarType.fixed,
    selectedIconTheme: IconThemeData(color: Color(0xFF818CF8), size: 24),
    unselectedIconTheme: IconThemeData(color: Color(0xFF64748B), size: 24),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFCBD5E1)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1E293B), elevation: 0),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1E293B),
    titleTextStyle: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 20, fontWeight: FontWeight.w600),
    contentTextStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFF334155), width: 1),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF818CF8),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E293B),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
    hintStyle: const TextStyle(color: Color(0xFF64748B)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF334155), thickness: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF818CF8),
    circularTrackColor: Color(0xFF334155),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF1E293B),
    textStyle: const TextStyle(color: Color(0xFFF1F5F9)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF334155)),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFF94A3B8),
    textColor: Color(0xFFE2E8F0),
    tileColor: Colors.transparent,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF334155),
    selectedColor: const Color(0xFF6366F1),
    labelStyle: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF6366F1),
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  useMaterial3: true,
);

// ─── Light Theme ───────────────────────────────
ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF6366F1),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE0E7FF),
    onPrimaryContainer: const Color(0xFF312E81),
    secondary: const Color(0xFF818CF8),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF1E293B),
    surfaceContainerHighest: const Color(0xFFF1F5F9),
    background: const Color(0xFFF8FAFC),
    onBackground: const Color(0xFF1E293B),
    error: const Color(0xFFEF4444),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    shadowColor: const Color(0xFF94A3B8).withOpacity(0.15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
  ),
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Color(0xFF1E293B),
      letterSpacing: 0.5,
    ),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Color(0xFF334155)),
    actionsIconTheme: IconThemeData(color: Color(0xFF334155)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    unselectedItemColor: Color(0xFF94A3B8),
    selectedItemColor: Color(0xFF6366F1),
    type: BottomNavigationBarType.fixed,
    selectedIconTheme: IconThemeData(color: Color(0xFF6366F1), size: 24),
    unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8), size: 24),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF475569)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFFF8FAFC), elevation: 1),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    titleTextStyle: const TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w600),
    contentTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF6366F1),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF1F5F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF64748B)),
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF6366F1),
    circularTrackColor: Color(0xFFE2E8F0),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Color(0xFF1E293B)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFF64748B),
    textColor: Color(0xFF334155),
    tileColor: Colors.transparent,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF1F5F9),
    selectedColor: const Color(0xFF6366F1),
    labelStyle: const TextStyle(color: Color(0xFF334155), fontSize: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF6366F1),
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  canvasColor: const Color(0xFFF1F5F9),
  useMaterial3: true,
);