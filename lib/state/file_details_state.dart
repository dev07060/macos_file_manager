// lib/src/widgets/file_details/state/file_details_state.dart

import 'package:flutter/material.dart';

class FileDetailsState {
  final ValueNotifier<bool> isInfoCollapsed;
  final ValueNotifier<int> rotationAngle;
  final ValueNotifier<bool> isEditingFilename;
  final ValueNotifier<int> lastSavedAngle;
  final ValueNotifier<bool> isCropping; // 추가
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  FileDetailsState()
    : isInfoCollapsed = ValueNotifier(false),
      rotationAngle = ValueNotifier(0),
      isEditingFilename = ValueNotifier(false),
      lastSavedAngle = ValueNotifier(0),
      isCropping = ValueNotifier(false), // 추가
      textEditingController = TextEditingController(),
      focusNode = FocusNode();

  void dispose() {
    isInfoCollapsed.dispose();
    rotationAngle.dispose();
    isEditingFilename.dispose();
    lastSavedAngle.dispose();
    isCropping.dispose(); // 추가
    textEditingController.dispose();
    focusNode.dispose();
  }
}
