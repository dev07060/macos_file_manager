import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/constants/app_strings.dart';
import 'package:macos_file_manager/model/file_category_config.dart';

class EditExtensionDialog extends HookConsumerWidget {
  final ExtensionMapping mapping;
  final List<String> categories;

  const EditExtensionDialog({required this.mapping, required this.categories, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(mapping.category);

    return AlertDialog(
      title: Text('${AppStrings.editExtensionTitle} .${mapping.extension}'),
      content: DropdownButtonFormField<String>(
        value: selectedCategory.value,
        decoration: const InputDecoration(labelText: AppStrings.categoryLabel),
        items:
            categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
        onChanged: (value) => selectedCategory.value = value,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(selectedCategory.value), child: const Text(AppStrings.edit)),
      ],
    );
  }
}
