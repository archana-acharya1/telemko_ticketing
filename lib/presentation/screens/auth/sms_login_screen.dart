import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import '../navbar/main_navbar.dart';
import 'login_screen.dart';

class SmsLoginScreen extends StatefulWidget {
  const SmsLoginScreen({super.key});

  @override
  State<SmsLoginScreen> createState() => _SmsLoginScreenState();
}

class _SmsLoginScreenState extends State<SmsLoginScreen> {
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  bool isLoading = false;
  bool otpSent = false;

  Future<void> sendOtp() async {
    final mobile = mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter your mobile number")));
      return;
    }

    setState(() => isLoading = true);
    final sent = await CustomerService.sendOtp(mobile);
    setState(() => isLoading = false);

    if (sent) {
      setState(() => otpSent = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP sent successfully")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to send OTP")));
    }
  }

  Future<void> verifyOtp() async {
    final mobile = mobileController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter OTP")));
      return;
    }

    setState(() => isLoading = true);
    final loginData = await CustomerService.loginWithOtp(mobile, otp);
    setState(() => isLoading = false);

    if (loginData != null && loginData["sid"] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  void dispose() {
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
                Icon(Icons.mobile_friendly, size: 80, color: AppColors.primaryBlue),
                const SizedBox(height: 12),
                Text("SMS Login", style: AppTextStyles.headline1),
                const SizedBox(height: 6),
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
                        controller: mobileController,
                        hintText: "Mobile Number",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppPadding.md),
                      if (otpSent)
                        AppTextField(
                          controller: otpController,
                          hintText: "Enter OTP",
                          prefixIcon: Icons.lock,
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: AppPadding.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isLoading
                              ? "Processing..."
                              : otpSent
                              ? "Verify OTP"
                              : "Send OTP",
                          color: AppColors.primaryBlue,
                          onPressed: isLoading
                              ? () {}
                              : otpSent
                              ? verifyOtp
                              : sendOtp,
                        ),
                      ),
                      const SizedBox(height: AppPadding.md),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: Text(
                          "Login with Username/Password",
                          style: AppTextStyles.bodyText1.copyWith(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
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
