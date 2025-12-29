package presentation.screens.auth;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import '../navbar/main_navbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  bool otpSent = false;
  bool useSmsLogin = false;

  /// ---------- Normal login ----------
  Future<void> handleLogin() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter username/email/mobile and password")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // Fetch customer first
      final customer = await CustomerService.fetchCustomerByIdentifier(identifier);
      if (customer == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Customer not found")));
        return;
      }

      // Login
      final loginData = await CustomerService.loginUser(usr: identifier, pwd: password);
      if (loginData == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Invalid credentials")));
        return;
      }

      // Save session
      await SessionManager.saveCustomerSession(
        customerName: customer["customer_name"] ?? "",
        mobileNo: customer["mobile_no"] ?? "",
        emailId: customer["email_id"] ?? "",
        sid: loginData["sid"] ?? "",
        loginType: "normal",
      );

      // Navigate to main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ---------- Send OTP ----------
  Future<void> sendOtp() async {
    final mobile = mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter your mobile number")));
      return;
    }

    setState(() => isLoading = true);
    final success = await CustomerService.sendOtp(mobile);
    setState(() => isLoading = false);

    if (success) {
      setState(() => otpSent = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP sent successfully")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to send OTP")));
    }
  }

  /// ---------- Login with OTP ----------
  Future<void> loginWithOtp() async {
    final mobile = mobileController.text.trim();
    final otp = otpController.text.trim();

    if (mobile.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter mobile number and OTP")));
      return;
    }

    setState(() => isLoading = true);
    final loginData = await CustomerService.loginWithOtp(mobile: mobile, otp: otp);
    setState(() => isLoading = false);

    if (loginData == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
      return;
    }

    final customer = loginData["customer"];
    await SessionManager.saveCustomerSession(
      customerName: customer?["customer_name"] ?? "",
      mobileNo: customer?["mobile_no"] ?? "",
      emailId: customer?["email_id"] ?? "",
      sid: loginData["sid"] ?? "",
      loginType: "otp",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavbar()),
    );
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    otpController.dispose();
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
                  useSmsLogin
                      ? "Enter your mobile to receive OTP"
                      : "Sign in to manage your support tickets",
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
                      if (!useSmsLogin) ...[
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
                            icon: Icon(isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => isPasswordVisible = !isPasswordVisible),
                          ),
                        ),
                      ] else ...[
                        AppTextField(
                          controller: mobileController,
                          hintText: "Mobile Number",
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        if (otpSent) ...[
                          const SizedBox(height: AppPadding.md),
                          AppTextField(
                            controller: otpController,
                            hintText: "Enter OTP",
                            prefixIcon: Icons.lock,
                            keyboardType: TextInputType.number,
                          ),
                        ]
                      ],
                      const SizedBox(height: AppPadding.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isLoading
                              ? "Please wait..."
                              : useSmsLogin
                                  ? otpSent
                                      ? "Login"
                                      : "Send OTP"
                                  : "Login",
                          onPressed: isLoading
                              ? () {}
                              : useSmsLogin
                                  ? otpSent
                                      ? loginWithOtp
                                      : sendOtp
                                  : handleLogin,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppPadding.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              useSmsLogin ? "Want to login with password? " : "Don’t have an account? "),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                useSmsLogin = !useSmsLogin;
                                otpSent = false;
                              });
                            },
                            child: Text(
                              useSmsLogin ? "Login normally" : "Register now",
                              style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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
