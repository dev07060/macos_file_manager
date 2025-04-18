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
        DialogUtils.showErrorDialog(context, '이미지를 로드할 수 없습니다.');
        return;
      }

      // 이미지 회전
      img.Image rotatedImage = img.copyRotate(originalImage, angle: currentRotation);
      log('이미지 회전: $currentRotation도');

      await _saveRotatedImage(imagePath, rotatedImage);

      // 회전 상태 저장 (저장 후에는 이 상태가 새로운 0도가 됨)
      await ImageRotationStorage.saveRotationState(imagePath, 0);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지가 회전되어 저장되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        DialogUtils.showErrorDialog(context, '이미지 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  // 현재 회전 상태 로드
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
