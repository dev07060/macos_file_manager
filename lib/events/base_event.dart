import 'package:flutter/material.dart';

mixin class BaseEvent {
  /// Show a simple snackbar message to the user
  void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: duration, action: action),
      );
    }
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText, style: isDangerous ? const TextStyle(color: Colors.red) : null),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  /// Wrap an async action with error dialog and optional success snackbar
  Future<T?> handleErrorWithDialog<T>(
    Future<T> Function() action,
    BuildContext context, {
    String title = 'Error',
    String? successMessage,
    bool showErrorDetails = true,
  }) async {
    try {
      final result = await action();
      if (successMessage != null) {
        showSnackBar(context, successMessage);
      }
      return result;
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            showErrorDetails ? 'Error occurred while action: $e' : 'An error occurred',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Confirm')),
          ],
        ),
      );
      return null;
    }
  }

  /// Show an input dialog and return the entered string
  Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool Function(String)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            validator: validator != null
                ? (value) => validator(value ?? '') ? null : 'Input is invalid'
                : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(cancelText)),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show a loading indicator and close it when the task is complete
  Future<T?> showLoadingWhile<T>(
    Future<T> Function() action,
    BuildContext context, {
    String loadingText = 'Processing...',
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(width: 20),
              Text(loadingText),
            ],
          ),
        );
      },
    );

    try {
      final result = await action();
      // Close loading dialog after task completion
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (e) {
      // Close loading dialog if an error occurs
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      rethrow; // Rethrow the error to be handled by handleErrorWithDialog
    }
  }
}
