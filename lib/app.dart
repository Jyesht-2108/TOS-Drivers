import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';

/// Root application widget
class TosDriverApp extends ConsumerWidget {
  const TosDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TOS Driver App',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
