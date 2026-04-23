import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../../../screens/admin_login_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    return auth.when(
      data: (state) {
        if (state is AuthAdmin) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(
                title: const Text('Email'),
                subtitle: Text(state.user.email ?? '—'),
              ),
              ListTile(
                title: const Text('Tên'),
                subtitle: Text(state.user.fullName ?? '—'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    await Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminLoginScreen(),
                      ),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
            ],
          );
        }
        return const Center(child: Text('Chưa đăng nhập'));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
