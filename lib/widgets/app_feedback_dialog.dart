import 'package:flutter/material.dart';

enum AppFeedbackType { info, success, error }

Future<void> showAppFeedbackDialog(
  BuildContext context, {
  required String title,
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
  String actionLabel = 'Continue',
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  final Color actionColor = switch (type) {
    AppFeedbackType.error => scheme.error,
    AppFeedbackType.success => scheme.primary,
    AppFeedbackType.info => scheme.primary,
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                _normalizeErrorMessage(message),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _normalizeErrorMessage(String value) {
  var message = value.trim();
  if (message.startsWith('Exception: ')) {
    message = message.replaceFirst('Exception: ', '');
  }
  return message;
}
