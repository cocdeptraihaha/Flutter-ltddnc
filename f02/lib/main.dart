import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'screens/admin_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(
    const ProviderScope(
      child: KeBookF02App(),
    ),
  );
}

class KeBookF02App extends StatelessWidget {
  const KeBookF02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeBook F02',
      debugShowCheckedModeBanner: false,
      theme: buildKeBookAdminTheme(),
      home: const AdminLoginScreen(),
    );
  }
}
