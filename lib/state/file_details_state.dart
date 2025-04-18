import 'package:flutter/material.dart';

class FileDetailsState {
  final ValueNotifier<bool> isInfoCollapsed;
  final ValueNotifier<int> rotationAngle;
  final ValueNotifier<bool> isEditingFilename;
  final ValueNotifier<int> lastSavedAngle;
  final ValueNotifier<bool> isCropping;
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  FileDetailsState()
    : isInfoCollapsed = ValueNotifier(false),
      rotationAngle = ValueNotifier(0),
      isEditingFilename = ValueNotifier(false),
      lastSavedAngle = ValueNotifier(0),
      isCropping = ValueNotifier(false),
      textEditingController = TextEditingController(),
      focusNode = FocusNode();

  void dispose() {
    isInfoCollapsed.dispose();
    rotationAngle.dispose();
    isEditingFilename.dispose();
    lastSavedAngle.dispose();
    isCropping.dispose();
    textEditingController.dispose();
    focusNode.dispose();
  }
}
