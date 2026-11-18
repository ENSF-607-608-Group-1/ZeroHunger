// app_theme.dart

import 'package:flutter/material.dart';

// The design's colours by name, so screens never type hex codes.
class ZhColors {
  ZhColors._(); // only holds colours, never created

  static const primary = Color(0xFF2E7D32);            // buttons, focus, selected
  static const onPrimary = Color(0xFFFFFFFF);          // text on primary
  static const primaryContainer = Color(0xFFDCEFD8);   // selected chips, success card
  static const onPrimaryContainer = Color(0xFF0F3D14); // text on primaryContainer
  static const background = Color(0xFFF6F8F3);         // page and app bar
  static const surface = Color(0xFFFFFFFF);            // cards, fields, sheets
  static const text = Color(0xFF1B1D1A);
  static const textSecondary = Color(0xFF5A6157);
  static const placeholder = Color(0xFF6F766B);
  static const outline = Color(0xFF8C9388);            // field and chip borders
  static const divider = Color(0xFFE3E6DF);            // card borders, dividers
  static const warningContainer = Color(0xFFFFF1D0);   // selected allergens, guest notice
  static const onWarning = Color(0xFF4A3300);
  static const warningIcon = Color(0xFF8A5A00);
  static const error = Color(0xFFB3261E);
  static const snackbar = Color(0xFF303330);
  static const snackbarAction = Color(0xFFA5D6A7);
}

// The app-wide theme. main.dart gives this to MaterialApp.
ThemeData zeroHungerTheme() {
  return ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: ZhColors.primary,
      onPrimary: ZhColors.onPrimary,
      primaryContainer: ZhColors.primaryContainer,
      onPrimaryContainer: ZhColors.onPrimaryContainer,
      secondary: ZhColors.warningIcon,
      onSecondary: ZhColors.onPrimary,
      secondaryContainer: ZhColors.warningContainer,
      onSecondaryContainer: ZhColors.onWarning,
      error: ZhColors.error,
      onError: ZhColors.onPrimary,
      surface: ZhColors.surface,
      onSurface: ZhColors.text,
      onSurfaceVariant: ZhColors.textSecondary,
      outline: ZhColors.outline,
      outlineVariant: ZhColors.divider,
    ),
    scaffoldBackgroundColor: ZhColors.background,
  );
}

// A text field in the design's style: 12 dp corners, white inside, label always
// sitting on the border, 1 dp grey border (2 dp green while typing, red when wrong).
InputDecoration zhField({
  required String label,
  String? hint,
  String? helper,
  String? suffixText,
  Widget? suffixIcon,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    counterText: '', // hides Flutter's own counter (the Title field shows "0/60" itself)
    filled: true,
    fillColor: ZhColors.surface,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(fontSize: 16, color: ZhColors.textSecondary),
    floatingLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ZhColors.textSecondary),
    hintStyle: const TextStyle(fontSize: 16, color: ZhColors.placeholder),
    helperStyle: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
    errorStyle: const TextStyle(fontSize: 12, color: ZhColors.error),
    suffixStyle: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
    contentPadding: padding,
    border: border(ZhColors.outline, 1),
    enabledBorder: border(ZhColors.outline, 1),
    focusedBorder: border(ZhColors.primary, 2),
    errorBorder: border(ZhColors.error, 1),
    focusedErrorBorder: border(ZhColors.error, 2),
  );
}

// The big green pill button, e.g. "Post food": 52 dp tall and as wide as it can be.
ButtonStyle zhPrimaryButton() => FilledButton.styleFrom(
      backgroundColor: ZhColors.primary,
      foregroundColor: ZhColors.onPrimary,
      disabledBackgroundColor: const Color(0x992E7D32), // lighter green while busy
      disabledForegroundColor: ZhColors.onPrimary,
      minimumSize: const Size.fromHeight(52),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

// Shows a short message at the bottom of the screen in the design's dark style.
// Pass onRetry to add a "Retry" button.
void showZhMessage(BuildContext context, String message, {VoidCallback? onRetry}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 14, color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ZhColors.snackbar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: onRetry == null
          ? null
          : SnackBarAction(label: 'Retry', textColor: ZhColors.snackbarAction, onPressed: onRetry),
    ));
}