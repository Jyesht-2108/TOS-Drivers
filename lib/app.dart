import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

/// Root application widget
class TosDriverApp extends ConsumerWidget {
  const TosDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'TOS Driver App',
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text('TOS Driver App - Setup Complete'),
        ),
      ),
    );
  }
}
