import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:macos_file_manager/utils/image_utils.dart';

class ImagePreview extends StatelessWidget {
  final String imagePath;
  final bool isFullView;
  final ValueNotifier<int> rotationAngle;
  final ValueNotifier<bool> isCropping;
  final ValueNotifier<int> imageKey;
  final VoidCallback onCropComplete;

  const ImagePreview({
    super.key,
    required this.imagePath,
    required this.isFullView,
    required this.rotationAngle,
    required this.isCropping,
    required this.imageKey,
    required this.onCropComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFullView) {
      return _buildCompactPreview();
    }
    return _buildFullPreview(context);
  }

  Widget _buildCompactPreview() {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxHeight: 300),
      child: Transform.rotate(
        angle: rotationAngle.value * math.pi / 180,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          cacheWidth: null,
          key: ValueKey('image_${imageKey.value}'),
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Unable to load image', style: TextStyle(color: Colors.red)));
          },
        ),
      ),
    );
  }

  Widget _buildFullPreview(BuildContext context) {
    final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey<ExtendedImageEditorState>();

    return isCropping.value ? _buildCroppingView(editorKey, context) : _buildRotatedView();
  }

  Widget _buildCroppingView(GlobalKey<ExtendedImageEditorState> editorKey, BuildContext context) {
    return Stack(
      children: [
        Transform.rotate(
          angle: rotationAngle.value * math.pi / 180,
          child: ExtendedImage.file(
            File(imagePath),
            fit: BoxFit.contain,
            mode: ExtendedImageMode.editor,
            enableLoadState: true,
            initEditorConfigHandler: (state) {
              return EditorConfig(
                maxScale: 8.0,
                cropRectPadding: const EdgeInsets.all(20.0),
                hitTestSize: 20.0,
                cropAspectRatio: 3 / 2,
                cornerColor: Colors.white,
                lineColor: Colors.white,
              );
            },
            extendedImageEditorKey: editorKey,
            loadStateChanged: (state) {
              if (state.extendedImageLoadState == LoadState.failed) {
                return const Center(child: Text('Unable to load image', style: TextStyle(color: Colors.red)));
              }
              return null;
            },
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: () async {
                  final editorState = editorKey.currentState;
                  if (editorState != null) {
                    await _saveCroppedImage(editorState, imagePath, context, isCropping);
                  }
                },
                child: const Icon(Icons.check),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  isCropping.value = false;
                },
                child: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRotatedView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
        child: AspectRatio(
          aspectRatio: 1, // 정사각형 영역 확보
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Transform.rotate(
              angle: rotationAngle.value * math.pi / 180,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain, // contain으로 변경
                cacheWidth: null,
                key: ValueKey('image_${imageKey.value}'),
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Unable to load image', style: TextStyle(color: Colors.red)));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCroppedImage(
    ExtendedImageEditorState editorState,
    String imagePath,
    BuildContext context,
    ValueNotifier<bool> isCropping,
  ) async {
    final cropRect = editorState.getCropRect();
    if (cropRect == null) return;

    final File imageFile = File(imagePath);
    final ui.Image image = await ImageUtils.loadImage(imageFile);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(image, cropRect, Rect.fromLTWH(0, 0, cropRect.width, cropRect.height), Paint());

    final ui.Picture picture = recorder.endRecording();
    final ui.Image croppedImage = await picture.toImage(cropRect.width.toInt(), cropRect.height.toInt());

    final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List croppedImageBytes = byteData.buffer.asUint8List();
    await imageFile.writeAsBytes(croppedImageBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image cropped and saved successfully')));
    }
    onCropComplete();
    isCropping.value = false;
  }
}
