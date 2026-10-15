
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import 'custom_toast.dart';
import '../../shared/styles/lyn_palette.dart';

// ✅ Re-export ToastStates
export 'custom_toast.dart' show ToastStates, CustomToast;

// ─── Old showToast function (now uses CustomToast) ─
void showToast({
  required String message,
  required ToastStates state,
  BuildContext? context,
}) {
  // ✅ إذا كان هناك context، نستخدم CustomToast
  // وإلا نستخدم SnackBar التقليدي
  if (context != null) {
    CustomToast.show(
      context: context,
      message: message,
      state: state,
    );
  }
}

// ─── Default Button ────────────────────────────
Widget defaultButton({
  required VoidCallback function,
  required String text,
  double width = double.infinity,
  double height = 56,
  double radius = 12,
  bool isUpperCase = true,
  Color? background,
  Color? textColor,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: background ?? LynPalette.indigo,
    ),
    child: MaterialButton(
      onPressed: function,
      child: Text(
        isUpperCase ? text.toUpperCase() : text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ─── Default Form Field ────────────────────────
Widget defaultFormField({
  required TextEditingController controller,
  required TextInputType type,
  required String? Function(String?)? validate,
  required IconData prefix,
  String? hint,
  bool isPassword = false,
  IconData? suffix,
  VoidCallback? suffixPressed,
  VoidCallback? onTap,
  Function(String)? onSubmit,
  Function(String)? onChange,
  bool isDark = true,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: type,
    obscureText: isPassword,
    validator: validate,
    onTap: onTap,
    onFieldSubmitted: onSubmit,
    onChanged: onChange,
    style: TextStyle(color: LynSurface.textPrimary(isDark)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: LynSurface.textTertiary(isDark)),
      prefixIcon: Icon(prefix, color: LynSurface.textSecondary(isDark)),
      suffixIcon: suffix != null
          ? IconButton(
        onPressed: suffixPressed,
        icon: Icon(suffix, color: LynSurface.textSecondary(isDark)),
      )
          : null,
      filled: true,
      fillColor: LynSurface.surface(isDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: LynSurface.border(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: LynPalette.indigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: LynPalette.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}

// ─── Divider ───────────────────────────────────
Widget myDivider() => Divider(
  color: HexColor('#334155'),
  thickness: 1,
  height: 1,
);

// ─── Navigation ────────────────────────────────
void navigateTo(BuildContext context, Widget screen) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

void navigateAndFinish(BuildContext context, Widget screen) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => screen),
        (route) => false,
  );
}