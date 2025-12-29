import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../navbar/main_navbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  Future<void> handleLogin() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username/email/mobile and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    final loginData = await CustomerService.loginUser(
      usr: identifier,
      pwd: password,
    );

    setState(() => isLoading = false);

    if (loginData != null && loginData["sid"] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
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
                Text(
                  "Sign in to manage your support tickets",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: identifierController,
                        hintText: "Username / Email / Mobile",
                        prefixIcon: Icons.person,
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
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppPadding.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isLoading ? "Please wait..." : "Login",
                          color: AppColors.primaryBlue,
                          onPressed: isLoading ? () {} : handleLogin,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
