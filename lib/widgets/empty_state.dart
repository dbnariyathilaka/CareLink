import 'package:flutter/material.dart';

/// Shown wherever a screen has no real data to display yet, instead of
/// synthetic/mock content. Keep messages honest about *why* it's empty.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? textColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? Colors.grey.shade400;
    final resolvedTextColor = textColor ?? Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: resolvedIconColor),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resolvedTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
