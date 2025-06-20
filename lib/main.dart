import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_file_manager/providers/theme_provider.dart';
import 'package:macos_file_manager/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/favorites_provider.dart';
import 'src/home.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  await dotenv.load(fileName: "assets/env/.dev.env");

  runApp(
    ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)], child: const MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'macOS File Viewer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
