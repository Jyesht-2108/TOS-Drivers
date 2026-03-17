// Connection status banner widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sse_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_lifecycle_service.dart';

class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(sseConnectionStateProvider);
    final authState = ref.watch(authProvider);
    
    // Hide banner when connected or not authenticated
    if (isConnected || !authState.isAuthenticated) {
      return const SizedBox.shrink();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Connecting to server...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final user = authState.user;
              if (user != null) {
                final lifecycleService = ref.read(appLifecycleServiceProvider);
                lifecycleService.onLogin(user.id, user.token);
              }
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
