import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Reusable error alert widget for displaying destructive error messages
/// Uses ShadAlert.destructive with customizable title and description
class ErrorAlert extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onDismiss;

  const ErrorAlert({
    super.key,
    required this.title,
    required this.description,
    this.onDismiss,
  });

  /// Factory method for session expired error
  factory ErrorAlert.sessionExpired({VoidCallback? onDismiss}) {
    return ErrorAlert(
      title: 'Error',
      description: 'Your session has expired. Please log in again.',
      onDismiss: onDismiss,
    );
  }

  /// Factory method for generic error with custom message
  factory ErrorAlert.genericError(String message, {VoidCallback? onDismiss}) {
    return ErrorAlert(
      title: 'Error',
      description: message,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadAlert.destructive(
      iconData: LucideIcons.circleAlert,
      title: Text(title),
      description: Text(description),
    );
  }
}