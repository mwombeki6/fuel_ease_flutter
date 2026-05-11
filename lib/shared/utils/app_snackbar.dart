import 'package:flutter/material.dart';

import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class AppSnackbar {
  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.error, Icons.error_outline_rounded);

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_outline_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info_outline_rounded);

  /// Show a friendly error message extracted from any thrown value.
  static void fromError(BuildContext context, Object e) =>
      error(context, friendlyMessage(e));

  /// Convert any thrown error to a user-facing string.
  static String friendlyMessage(Object e) {
    if (e is ApiError) return e.message;
    final msg = e.toString().toLowerCase();
    if (msg.contains('no internet') || msg.contains('socketexception') ||
        msg.contains('no route') || msg.contains('connection error')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('timeout')) return 'Request timed out. Try again.';
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      return 'You don\'t have permission to do that.';
    }
    if (msg.contains('404')) return 'The requested resource was not found.';
    if (msg.contains('500') || msg.contains('server error')) {
      return 'Server error. Please try again later.';
    }
    return 'Something went wrong. Pull down to retry.';
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
      ));
  }
}
