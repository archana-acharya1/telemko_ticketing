import 'package:flutter/material.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import 'login_screen.dart';
import '../../widgets/app_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  void performLogout(BuildContext context) async {
    print("[LogoutScreen] Logout initiated by user");

    try {
      await SessionManager.clearSession();
      print("[LogoutScreen] Session cleared successfully");
    } catch (e) {
      print("[LogoutScreen] Error clearing session: $e");
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) {
        print("[LogoutScreen] Navigating to LoginScreen after logout");
        return const LoginScreen();
      }),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Logout"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 80,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: AppPadding.lg),
            Text(
              "Are you sure you want to logout?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppPadding.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: "Logout",
                onPressed: () => performLogout(context),
                color: primaryColor,
              ),
            ),
            const SizedBox(height: AppPadding.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  print("[LogoutScreen] Logout canceled by user");
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppPadding.md,
                    horizontal: AppPadding.lg,
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
