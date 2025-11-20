import 'package:flutter/material.dart';
import 'package:telemko_support/core/theme/app_theme.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telemko Support',

      themeMode: ThemeMode.system,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: const LoginScreen(),
    );
  }
}
