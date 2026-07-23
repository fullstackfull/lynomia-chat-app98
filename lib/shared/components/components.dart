
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import 'custom_toast.dart';

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
      color: background ?? HexColor('#6366F1'),
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
    style: TextStyle(color: isDark ? HexColor('#F1F5F9') : HexColor('#0F172A')),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? HexColor('#64748B') : HexColor('#94A3B8')),
      prefixIcon: Icon(prefix, color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
      suffixIcon: suffix != null
          ? IconButton(
        onPressed: suffixPressed,
        icon: Icon(suffix, color: isDark ? HexColor('#94A3B8') : HexColor('#64748B')),
      )
          : null,
      filled: true,
      fillColor: isDark ? HexColor('#1E293B') : HexColor('#F1F5F9'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? HexColor('#334155') : HexColor('#E2E8F0')),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: HexColor('#6366F1'), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: HexColor('#EF4444')),
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