import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/auth/sms_login_screen.dart';
import 'package:telemko_support/presentation/screens/auth/register_screen.dart';
import 'package:telemko_support/presentation/screens/navbar/main_navbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../../data/api/auth_api.dart';

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

  //Handle login logic
  void handleLogin() async {
    setState(() => isLoading = true);

    final identifier = emailController.text.trim();
    final password = passwordController.text;

    // Logs: Starting login attempt
    print("Login attempt started with identifier: $identifier");
    print("Password length: ${password.length}");

    if (identifier.isEmpty || password.isEmpty) {
      print("Login failed: Identifier or password empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter username/email/mobile and password")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      print("Calling Auth API for login...");
      await AuthApi.login(identifier: identifier, password: password);

      print("Login successful, session saved in SessionManager");


      if (!mounted) return;

      print("Login successful for identifier: $identifier, navigating to MainNavbar");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    } catch (e) {
      print("Login failed: Error during Auth API call: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientTop, AppColors.gradientBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.support_agent, size: 80, color: AppColors.primaryBlue),
                const SizedBox(height: 12),
                Text("Telemko Support", style: AppTextStyles.headline1),
                const SizedBox(height: 6),
                Text("Sign in to manage your support tickets",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: emailController,
                        hintText: "Username",
                        prefixIcon: Icons.email,
                      ),
                      const SizedBox(height: AppPadding.md),
                      AppTextField(
                        controller: passwordController,
                        hintText: "Password",
                        prefixIcon: Icons.lock,
                        obscureText: !isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: AppPadding.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            print("User clicked Forgot Password"); // Log action
                          },
                          style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                      const SizedBox(height: AppPadding.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isLoading ? "Logging in..." : "Login",
                          onPressed: handleLogin,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppPadding.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don’t have an account? "),
                          GestureDetector(
                            onTap: () {
                              print("Navigating to RegisterScreen"); // Log navigation
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: Text("Register now",
                                style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.lg),
                TextButton(
                  onPressed: () {
                    print("Navigating to SMS Login screen"); // Log navigation
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SmsLoginScreen()),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
                  child: Text(
                    "Login with SMS",
                    style: AppTextStyles.bodyText1.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
