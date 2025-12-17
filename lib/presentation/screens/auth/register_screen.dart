import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final createPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isCreatePasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  String? errorMessage;

  void handleRegister() async {
    setState(() {
      errorMessage = null;
    });

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = createPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "All fields are required";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Passwords do not match";
      });
      return;
    }

    //loading simulation for delay
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);

    // Navigate to login, will change later
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gradientTop,
              AppColors.gradientBottom,
            ],
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

                Icon(
                  Icons.support_agent,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),

                const SizedBox(height: 12),

                Text(
                  "Telemko Support",
                  style: AppTextStyles.headline1,
                ),

                const SizedBox(height: 6),

                Text(
                  "Create an account to manage your support tickets",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // register card
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
                        controller: nameController,
                        hintText: "Full Name",
                        prefixIcon: Icons.person,
                      ),

                      const SizedBox(height: AppPadding.md),

                      AppTextField(
                        controller: emailController,
                        hintText: "Phone / Email",
                        prefixIcon: Icons.email,
                      ),

                      const SizedBox(height: AppPadding.md),

                      //  Create Password
                      AppTextField(
                        controller: createPasswordController,
                        hintText: "Create Password",
                        prefixIcon: Icons.lock,
                        obscureText: !isCreatePasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isCreatePasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isCreatePasswordVisible = !isCreatePasswordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: AppPadding.md),

                      //  Confirm Password
                      AppTextField(
                        controller: confirmPasswordController,
                        hintText: "Confirm Password",
                        prefixIcon: Icons.lock,
                        obscureText: !isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isConfirmPasswordVisible = !isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: AppPadding.md),

                      // Error message
                      if (errorMessage != null) ...[
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppPadding.md),
                      ],

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isLoading ? "Registering..." : "Register",
                          onPressed: isLoading ? () {} : handleRegister,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      const SizedBox(height: AppPadding.md),

                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppPadding.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
