import 'package:flutter/material.dart';

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
