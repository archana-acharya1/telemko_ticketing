import 'package:flutter/material.dart';
import 'package:telemko_support/core/theme/app_theme.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';
import 'package:telemko_support/presentation/screens/auth/sms_login_screen.dart';
import 'package:telemko_support/presentation/screens/dashboard/lib/data/local/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Restore session on app startup
  await SessionManager.getSid();
  
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

      home: const SmsLoginScreen(),
      // home: const LoginScreen(),
    );
  }
}
