import 'package:flutter/material.dart';
import 'package:telemko_service/presentation/screens/auth/auth_gate.dart';
import 'package:telemko_service/presentation/screens/dashboard/lib/data/local/session_manager.dart';

import 'core/theme/app_theme.dart';

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
      title: 'Telemko Service',

      themeMode: ThemeMode.system,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: const AuthGate(),
      // home: const LoginScreen(),
    );
  }
}
