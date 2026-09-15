import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class AppFeedback {
  const AppFeedback._();

  static void showSuccess(BuildContext context, String message) {
    Flushbar(
      message: message,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class AppFeedbackPanel extends StatelessWidget {
  const AppFeedbackPanel({
    required this.icon,
    required this.title,
    super.key,
    this.actionLabel,
    this.onAction,
    this.color,
    this.actionIcon = Icons.refresh,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: accentColor),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
