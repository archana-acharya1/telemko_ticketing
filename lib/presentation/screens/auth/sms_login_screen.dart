import 'package:flutter/material.dart';
import 'package:telemko_support/core/theme/app_text_styles.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';
import 'package:telemko_support/presentation/screens/navbar/main_navbar.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../data/api/customer_api.dart';
import '../../../data/api/sms_api.dart';
import '../../../data/api/auth_api.dart';

class SmsLoginScreen extends StatefulWidget {
  const SmsLoginScreen({super.key});

  @override
  State<SmsLoginScreen> createState() => _SmsLoginScreenState();
}

class _SmsLoginScreenState extends State<SmsLoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool isOtpSent = false;
  bool isLoading = false;
  bool customerNotFound = false;

  // STEP 1: Request OTP from backend
  Future<void> requestOtp() async {
    final mobile = phoneController.text.trim();
    print("[SMS Login] Requesting OTP for mobile: $mobile");

    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter mobile number")),
      );
      print("[SMS Login] Mobile number empty, aborting OTP request");
      return;
    }

    setState(() {
      isLoading = true;
      customerNotFound = false;
    });

    try {
      print("[SMS Login] Verifying customer existence...");
      final exists = await CustomerApi.verifyCustomerByMobile(mobile);
      print("[SMS Login] Customer exists: $exists");

      if (!exists) {
        setState(() {
          customerNotFound = true;
          isOtpSent = false;
        });
        print("[SMS Login] Customer not found, cannot send OTP");
        return;
      }

      print("[SMS Login] Sending OTP...");
      await SmsApi.sendOtp(mobile: mobile);
      print("[SMS Login] OTP sent successfully to $mobile");

      setState(() => isOtpSent = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP sent successfully")));
    } catch (e) {
      print("[SMS Login] Error sending OTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP: $e")),
      );
    } finally {
      setState(() => isLoading = false);
      print("[SMS Login] OTP request process finished");
    }
  }

  // STEP 2: Verify OTP + AUTO LOGIN
  Future<void> loginWithOtp() async {
    final mobile = phoneController.text.trim();
    final otp = otpController.text.trim();
    print("[SMS Login] Attempting login for $mobile with OTP: $otp");

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter OTP")),
      );
      print("[SMS Login] OTP empty, aborting login");
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthApi.mobileLogin(
        mobile: mobile,
        otp: otp,
      );

      if (!mounted) return;
      print("[SMS Login] Mobile login successful for $mobile");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    } catch (e) {
      print("[SMS Login] Mobile login failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid or expired OTP: $e")));
    } finally {
      setState(() => isLoading = false);
      print("[SMS Login] Login process finished");
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.primaryBlue,
                    onPressed: () {
                      print("[SMS Login] Navigating back to LoginScreen");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Icon(Icons.sms_outlined,
                    size: 80, color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  "Login with SMS",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "We’ll send a one-time password to your phone",
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
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
                        controller: phoneController,
                        hintText: "Mobile Number",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: isOtpSent
                            ? AppTextField(
                          key: const ValueKey("otp"),
                          controller: otpController,
                          hintText: "Enter OTP",
                          prefixIcon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                        )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: isOtpSent ? "Login" : "Send OTP",
                          onPressed: () {
                            print(
                                "[SMS Login] Button pressed (isOtpSent=$isOtpSent, isLoading=$isLoading)");
                            if (isLoading) return;

                            if (isOtpSent) {
                              loginWithOtp();
                            } else {
                              requestOtp();
                            }
                          },
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      if (customerNotFound) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Mobile number not registered",
                          style: AppTextStyles.bodyText1.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
