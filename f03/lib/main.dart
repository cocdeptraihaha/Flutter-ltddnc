import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'core/navigation.dart';
import 'screens/admin_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(
    const ProviderScope(
      child: KeBookF03App(),
    ),
  );
}

class KeBookF03App extends StatelessWidget {
  const KeBookF03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'KeBook F03 Admin',
      debugShowCheckedModeBanner: false,
      theme: buildKeBookAdminTheme(),
      home: const AdminLoginScreen(),
    );
  }
}
