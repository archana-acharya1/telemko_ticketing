import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../widgets/app_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  //Perform logout and navigate to LoginScreen
  void performLogout(BuildContext context) {
    print("Logout initiated by user");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) {
        print("Navigating to LoginScreen after logout");
        return const LoginScreen();
      }),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logout"),
        backgroundColor: AppColors.primaryBlue,
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
              style: AppTextStyles.headline2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppPadding.xl),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: "Logout",
                onPressed: () => performLogout(context),
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: AppPadding.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  print("Logout canceled by user");
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
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.primaryBlue,
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
