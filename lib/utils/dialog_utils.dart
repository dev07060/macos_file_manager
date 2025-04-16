import 'package:flutter/material.dart';

class DialogUtils {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('오류'),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          ),
    );
  }

  static Future<bool?> showShellScriptWarning(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('보안 경고'),
            content: const Text(
              '쉘 스크립트를 실행하면 시스템에 영향을 줄 수 있습니다. '
              '신뢰할 수 있는 스크립트만 실행하세요.\n\n계속하시겠습니까?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('실행', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
