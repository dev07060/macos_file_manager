import 'package:flutter/material.dart';

enum FSearchBarVariant { normal, subtle }

class FSearchBar extends StatelessWidget {
  const FSearchBar({
    super.key,
    required this.variant,
    required this.controller,
    this.width,
    this.height,
    this.hintText,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.textInputAction,
    this.onClear,
    this.isDarkMode = false,
  });

  final FSearchBarVariant variant;
  final TextEditingController controller;
  final double? width;
  final double? height;
  final String? hintText;
  final FocusNode? focusNode;
  final Function()? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final ValueChanged<bool>? onFocusChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onClear;
  final bool isDarkMode;

  factory FSearchBar.normal({
    Key? key,
    required TextEditingController controller,
    double? width,
    String? hintText,
    FocusNode? focusNode,
    Function()? onTap,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    ValueChanged<bool>? onFocusChanged,
    TextInputAction? textInputAction,
    VoidCallback? onClear,
    bool isDarkMode = false,
  }) {
    return FSearchBar(
      key: key,
      variant: FSearchBarVariant.normal,
      controller: controller,
      width: width,
      height: 52,
      hintText: hintText,
      focusNode: focusNode,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onFocusChanged: onFocusChanged,
      textInputAction: textInputAction,
      onClear: onClear,
      isDarkMode: isDarkMode,
    );
  }

  factory FSearchBar.subtle({
    Key? key,
    required TextEditingController controller,
    double? width,
    String? hintText,
    FocusNode? focusNode,
    Function()? onTap,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    ValueChanged<bool>? onFocusChanged,
    TextInputAction? textInputAction,
    VoidCallback? onClear,
    bool isDarkMode = false,
  }) {
    return FSearchBar(
      key: key,
      variant: FSearchBarVariant.subtle,
      width: width,
      height: 44,
      controller: controller,
      hintText: hintText,
      focusNode: focusNode,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onFocusChanged: onFocusChanged,
      textInputAction: textInputAction,
      onClear: onClear,
      isDarkMode: isDarkMode,
    );
  }

  OutlineInputBorder outlinedInputBorder(Color color) =>
      OutlineInputBorder(borderSide: BorderSide(color: color, width: 1), borderRadius: BorderRadius.circular(10));

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500;

    return Focus(
      focusNode: focusNode,
      onFocusChange: onFocusChanged,
      child: SizedBox(
        width: width,
        height: height,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder:
              (context, value, child) => TextField(
                controller: controller,
                cursorColor: textColor,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(color: textColor),
                textInputAction: textInputAction,
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: hintColor),
                  border: outlinedInputBorder(borderColor),
                  enabledBorder: outlinedInputBorder(borderColor),
                  focusedBorder: outlinedInputBorder(isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300),
                  contentPadding: contentPadding,
                  prefixIcon: Padding(
                    padding: prefixIconPadding,
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Center(child: Icon(Icons.search, size: iconSize, color: iconColor)),
                    ),
                  ),
                  suffixIcon:
                      controller.text.isEmpty
                          ? null
                          : Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                controller.clear();
                                onClear?.call();
                              },
                              child: SizedBox(
                                width: 50,
                                height: iconSize,
                                child: Center(
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  filled: true,
                  fillColor: backgroundColor,
                  isDense: true,
                ),
                onSubmitted: onSubmitted,
                onChanged: onChanged,
              ),
        ),
      ),
    );
  }

  EdgeInsetsGeometry get contentPadding {
    if (variant == FSearchBarVariant.normal) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    }
    return const EdgeInsets.all(12);
  }

  EdgeInsetsGeometry get prefixIconPadding {
    if (variant == FSearchBarVariant.normal) {
      return const EdgeInsets.fromLTRB(12, 14, 8, 14);
    }
    return const EdgeInsets.fromLTRB(12, 12, 8, 12);
  }

  double get iconSize {
    if (variant == FSearchBarVariant.normal) {
      return 24;
    }
    return 20;
  }
}
