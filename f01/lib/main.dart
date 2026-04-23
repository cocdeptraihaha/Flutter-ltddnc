import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/intro_screen.dart';

void main() {
  runApp(const KeBookF01App());
}

class KeBookF01App extends StatelessWidget {
  const KeBookF01App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeBook F01',
      debugShowCheckedModeBanner: false,
      theme: buildKeBookAdminTheme(),
      home: const IntroScreen(),
    );
  }
}
