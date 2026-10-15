
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import 'custom_toast.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

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
  double height = 52,
  double radius = LynSpace.md,
  bool isUpperCase = true,
  Color? background,
  Color? textColor,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: MaterialButton(
      onPressed: function,
      elevation: 0,
      highlightElevation: 0,
      color: background ?? LynPalette.indigo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: Text(
        isUpperCase ? text.toUpperCase() : text,
        style: LynType.subtitle.copyWith(color: textColor ?? Colors.white),
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
  // Without these the platform password manager has nothing to offer against, so every sign-in on a
  // new device is typed by hand.
  Iterable<String>? autofillHints,
  TextInputAction? textInputAction,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: type,
    obscureText: isPassword,
    validator: validate,
    onTap: onTap,
    onFieldSubmitted: onSubmit,
    onChanged: onChange,
    autofillHints: autofillHints,
    textInputAction: textInputAction,
    style: LynType.body.copyWith(color: LynSurface.textPrimary(isDark)),
    decoration: InputDecoration(
      hintText: hint,
      // The tertiary tone measured 3.5:1 on the field; a hint is text and has to be readable.
      hintStyle: LynType.body.copyWith(color: LynSurface.textSecondary(isDark)),
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
        borderRadius: BorderRadius.circular(LynSpace.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LynSpace.md),
        borderSide: BorderSide(color: LynSurface.border(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LynSpace.md),
        borderSide: BorderSide(color: LynPalette.indigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LynSpace.md),
        borderSide: BorderSide(color: LynPalette.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: LynSpace.lg, vertical: LynSpace.lg),
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