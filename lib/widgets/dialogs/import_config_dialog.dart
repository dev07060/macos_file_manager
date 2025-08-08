import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/providers/file_category_config_provider.dart';

class ImportConfigDialog extends HookConsumerWidget {
  const ImportConfigDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = useTextEditingController();

    return AlertDialog(
      title: const Text(AppStrings.importSettingsTitle),
      content: SizedBox(
        width: 400,
        height: 200,
        child: TextField(
          controller: configController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            labelText: '설정 JSON',
            hintText: AppStrings.importSettingsHint,
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
        TextButton(
          onPressed: () async {
            final success = await ref
                .read(fileCategoryConfigProvider.notifier)
                .importConfig(configController.text);

            if (context.mounted) {
            Navigator.of(context).pop();

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.settingsImportedMessage)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.settingsImportFailedMessage)));
            }
            }
          },
          child: const Text(AppStrings.importSettings),
        ),
      ],
    );
  }
}
