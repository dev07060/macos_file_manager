import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:macos_file_manager/utils/Image_rotation_storage.dart';
import 'package:macos_file_manager/utils/dialog_utils.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  static Future<void> rotateAndSaveImage(String imagePath, int currentRotation, BuildContext context) async {
    try {
      final fileBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(fileBytes);

      if (originalImage == null) {
        DialogUtils.showErrorDialog(context, 'Failed to load image.');
        return;
      }

      // Rotate image
      img.Image rotatedImage = img.copyRotate(originalImage, angle: currentRotation);
      log('Image rotated: $currentRotation degrees');

      await _saveRotatedImage(imagePath, rotatedImage);

      // Save rotation state (after saving, this state becomes the new 0 degrees)
      await ImageRotationStorage.saveRotationState(imagePath, 0);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image has been rotated and saved.')));
      }
    } catch (e) {
      if (context.mounted) {
        DialogUtils.showErrorDialog(context, 'An error occurred while processing the image: $e');
      }
    }
  }

  // Load current rotation state
  static Future<int> getCurrentRotation(String imagePath) async {
    return ImageRotationStorage.loadRotationState(imagePath);
  }

  static Future<void> _saveRotatedImage(String imagePath, img.Image rotatedImage) async {
    final extension = path.extension(imagePath).toLowerCase();
    List<int> encodedImage;

    if (extension == '.jpg' || extension == '.jpeg') {
      encodedImage = img.encodeJpg(rotatedImage, quality: 90);
    } else {
      encodedImage = img.encodePng(rotatedImage);
    }

    await File(imagePath).writeAsBytes(encodedImage);
  }

  static Future<ui.Image> loadImage(File file) async {
    final Completer<ui.Image> completer = Completer();
    final Uint8List bytes = await file.readAsBytes();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }
}
