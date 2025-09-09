import 'package:flutter/material.dart';

class NotificationBanner extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onAction;
  final String? actionLabel;

  const NotificationBanner({
    super.key,
    required this.message,
    required this.type,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
}
