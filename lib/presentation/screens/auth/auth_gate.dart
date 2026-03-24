import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/auth/sms_auth_screen.dart';
import 'package:telemko_support/presentation/screens/dashboard/lib/data/local/session_manager.dart';
import 'package:telemko_support/presentation/screens/navbar/main_navbar.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (SessionManager.isLoggedIn()) {
      // return const DashboardScreen();
      return const MainNavbar();
    } else {
      return const SmsAuthScreen();
    }
  }
}
