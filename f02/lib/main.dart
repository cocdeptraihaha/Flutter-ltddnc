import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
      home: const IntroScreen(),
    );
  }
}
