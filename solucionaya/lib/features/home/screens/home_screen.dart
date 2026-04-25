import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SolucionaYa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider).signOut();
              if (!context.mounted) return;
              context.go(AppRoutes.loginEmail);
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Bienvenido a la pantalla principal',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
