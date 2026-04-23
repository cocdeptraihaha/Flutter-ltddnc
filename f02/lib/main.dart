import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/intro_screen.dart';

void main() {
  runApp(const KeBookF02App());
}

class KeBookF02App extends StatelessWidget {
  const KeBookF02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeBook F02',
      debugShowCheckedModeBanner: false,
      theme: buildKeBookAdminTheme(),
      home: const IntroScreen(),
    );
  }
}
