import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';

class AddExtensionDialog extends HookConsumerWidget {
  final List<String> categories;

  const AddExtensionDialog({required this.categories, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionController = useTextEditingController();
    final selectedCategory = useState<String?>(null);

    return AlertDialog(
      title: const Text(AppStrings.addExtensionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: extensionController,
            decoration: const InputDecoration(labelText: AppStrings.extensionLabel, hintText: AppStrings.extensionHint),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCategory.value,
            decoration: const InputDecoration(labelText: AppStrings.categoryLabel),
            items:
                categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
            onChanged: (value) => selectedCategory.value = value,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
        TextButton(
          onPressed:
              selectedCategory.value != null && extensionController.text.isNotEmpty
                  ? () =>
                      Navigator.of(context).pop({'extension': extensionController.text, 'category': selectedCategory.value})
                  : null,
          child: const Text(AppStrings.add),
        ),
      ],
    );
  }
}
