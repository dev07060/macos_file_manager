import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_file_manager/model/file_system_item.dart';
import 'package:macos_file_manager/utils/dialog_utils.dart';

mixin class ScriptEvent {
  Future<Map<String, dynamic>> executeShellScript(String scriptPath, BuildContext context) async {
    try {
      // Check and grant execute permission for the script
      final statResult = await Process.run('chmod', ['+x', scriptPath]);
      if (statResult.exitCode != 0) {
        return {'success': false, 'output': 'Failed to grant execute permission: ${statResult.stderr}'};
      }

      // Execute the script
      final result = await Process.run('sh', [scriptPath]);

      return {
        'success': result.exitCode == 0,
        'output': result.stdout,
        'error': result.stderr,
        'exitCode': result.exitCode,
      };
    } catch (e) {
      return {'success': false, 'output': 'error occurred while executing script: $e'};
    }
  }

  Future<void> executeScript(BuildContext context, WidgetRef ref, FileSystemItem item) async {
    final shouldProceed = await DialogUtils.showShellScriptWarning(context);
    if (shouldProceed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [CircularProgressIndicator.adaptive(), SizedBox(width: 20), Text('Running shell script...')],
            ),
          ),
    );

    final result = await executeShellScript(item.path, context);
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(result['success'] ? 'success' : 'failed'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result['success']) Text('exit code: ${result['exitCode'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  const Text('Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                    width: double.infinity,
                    child: SelectableText(
                      result['output'] ?? 'none',
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    ),
                  ),
                  if (result['error'] != null && result['error'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                      width: double.infinity,
                      child: SelectableText(
                        result['error'] ?? '',
                        style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('close'))],
          ),
    );
  }
}
