import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../navbar/main_navbar.dart';
import 'sms_auth_screen.dart';

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
        SnackBar(
          content: Text(
            "Enter username/email/mobile and password",
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
        SnackBar(
          content: Text(
            "Invalid credentials",
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
              Color(0xFF0A0A0A),
              Color(0xFF121212),
              Color(0xFF1A1A1A),
            ]
                : [
              Color(0xFFF5FAFF),
              Color(0xFFEAF3FD),
              Color(0xFFE0ECFB),
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
                const SizedBox(height: 30),

                // Logo
                SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: Center(
                    child: Image.asset(
                      isDarkMode
                          ? 'assets/images/black.png'
                          : 'assets/images/white.png',
                      height: 80,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Main card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black12,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isDarkMode
                        ? Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    )
                        : null,
                  ),
                  child: Column(
                    children: [
                      // Title INSIDE CARD
                      Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Sign in to your account",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Username/Email/Mobile field
                      AppTextField(
                        controller: identifierController,
                        hintText: "Username / Email / Mobile",
                        prefixIcon: Icons.person,
                      ),

                      const SizedBox(height: AppPadding.md),

                      // Password field
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
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isLoading ? "Please wait..." : "Login",
                          color: colorScheme.primary,
                          onPressed: isLoading ? null : handleLogin,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider with OR
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colorScheme.outline.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colorScheme.outline.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // SMS Login button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SmsAuthScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            backgroundColor: colorScheme.primary.withOpacity(isDarkMode ? 0.1 : 0.05),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sms,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Login/Register with SMS",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Help text for SMS login
                      if (!isDarkMode) const SizedBox(height: 16),
                      if (!isDarkMode)
                        Text(
                          "We'll send you an OTP via SMS",
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Support text at bottom
                Text(
                  "Need help? Contact support@telemko.com",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}