import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:macos_file_manager/utils/dialog_utils.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  static Future<void> rotateAndSaveImage(String imagePath, int rotationDegrees, BuildContext context) async {
    try {
      final fileBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(fileBytes);

      if (originalImage == null) {
        DialogUtils.showErrorDialog(context, '이미지를 로드할 수 없습니다.');
        return;
      }

      // 이미지 회전
      img.Image rotatedImage;
      if (rotationDegrees == 90) {
        rotatedImage = img.copyRotate(originalImage, angle: 90);
      } else if (rotationDegrees == 180) {
        rotatedImage = img.copyRotate(originalImage, angle: 180);
      } else if (rotationDegrees == 270) {
        rotatedImage = img.copyRotate(originalImage, angle: 270);
      } else {
        DialogUtils.showErrorDialog(context, '올바르지 않은 회전 각도입니다.');
        return;
      }

      await _saveRotatedImage(imagePath, rotatedImage);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지가 회전되어 저장되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        DialogUtils.showErrorDialog(context, '이미지 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  static Future<void> _saveRotatedImage(String imagePath, img.Image rotatedImage) async {
    final extension = path.extension(imagePath).toLowerCase();
    List<int> encodedImage;

    if (extension == '.jpg' || extension == '.jpeg') {
      encodedImage = img.encodeJpg(rotatedImage, quality: 90);
    } else if (extension == '.png') {
      encodedImage = img.encodePng(rotatedImage);
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
