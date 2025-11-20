import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/navbar/main_navbar.dart';
import '../dashboard/dashboard_screen.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  void handleLogin() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavbar()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.support_agent,
                size: 90,
                color: AppColors.primaryRed,
              ),

              const SizedBox(height: AppPadding.md),
              Text(
                "Telemko Support",
                style: AppTextStyles.headline1,
              ),

              const SizedBox(height: AppPadding.xl),

              AppTextField(
                controller: emailController,
                hintText: "Email",
                prefixIcon: Icons.email,
              ),

              const SizedBox(height: AppPadding.md),

              AppTextField(
                controller: passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock,
                obscureText: !isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => isPasswordVisible = !isPasswordVisible);
                  },
                ),
              ),

              const SizedBox(height: AppPadding.sm),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot Password?"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                  ),
                ),
              ),

              const SizedBox(height: AppPadding.md),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "Login",
                  onPressed: isLoading ? () {} : handleLogin,
                  color: AppColors.primaryRed,
                ),
              ),

              const SizedBox(height: AppPadding.lg),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                child: const Text("Continue as Guest"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
