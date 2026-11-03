import 'package:flutter/material.dart';
import 'package:telemko_service/presentation/screens/auth/sms_auth_screen.dart';

import '../dashboard/lib/data/local/session_manager.dart';
import '../navbar/main_navbar.dart';

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
