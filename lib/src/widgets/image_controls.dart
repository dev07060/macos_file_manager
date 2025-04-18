import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:macos_file_manager/utils/image_utils.dart';

class ImageControlsWidget extends StatelessWidget {
  final ValueNotifier<int> rotationAngle;
  final ValueNotifier<bool> isCropping;
  final ValueNotifier<int> lastSavedAngle;
  final String imagePath;
  final ValueNotifier<int> imageKey;

  final Function()? onImageSaved;

  const ImageControlsWidget({
    super.key,
    required this.rotationAngle,
    required this.isCropping,
    required this.lastSavedAngle,
    required this.imagePath,
    required this.imageKey,
    this.onImageSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentedButton(
              icon: const Icon(Icons.rotate_left, size: 20),
              tooltipText: 'rotate left 90°',
              onPressed:
                  isCropping.value
                      ? null
                      : () {
                        // 반시계 방향 (왼쪽) 회전
                        int newAngle = (rotationAngle.value - 90) % 360;
                        if (newAngle < 0) newAngle += 360;
                        rotationAngle.value = newAngle;
                        log('왼쪽 회전: ${rotationAngle.value}');
                      },
              isFirst: true,
            ),
            _buildSegmentedButton(
              icon: const Icon(Icons.rotate_right, size: 20),
              tooltipText: 'rotate right 90°',
              onPressed:
                  isCropping.value
                      ? null
                      : () {
                        // 시계 방향 (오른쪽) 회전
                        rotationAngle.value = (rotationAngle.value + 90) % 360;
                        log('오른쪽 회전: ${rotationAngle.value}');
                      },
            ),
            _buildSegmentedButton(
              icon: const Icon(Icons.crop, size: 20),
              tooltipText: 'crop image',
              onPressed: () {
                isCropping.value = !isCropping.value;
              },
            ),
            _buildSegmentedButton(
              icon: const Icon(Icons.save, size: 20),
              tooltipText: 'save rotated image',
              onPressed:
                  isCropping.value || rotationAngle.value == lastSavedAngle.value
                      ? null
                      : () async {
                        await ImageUtils.rotateAndSaveImage(imagePath, rotationAngle.value, context);
                        lastSavedAngle.value = rotationAngle.value;
                        rotationAngle.value = 0;

                        // 이미지 저장 후 새로고침
                        if (onImageSaved != null) {
                          onImageSaved!();
                        }
                      },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton({
    required Widget icon,
    required String tooltipText,
    required VoidCallback? onPressed,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: isFirst ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
          right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
        ),
      ),
      child: IconButton(
        icon: icon,
        tooltip: tooltipText,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          backgroundColor: onPressed == null ? Colors.grey.shade300 : null,
        ),
      ),
    );
  }
}
