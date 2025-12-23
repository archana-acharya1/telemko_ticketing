import 'package:flutter/material.dart';
import 'package:telemko_support/core/theme/app_text_styles.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';
import 'package:telemko_support/presentation/screens/navbar/main_navbar.dart';
import 'package:telemko_support/presentation/screens/auth/register_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../data/api/customer_api.dart';
import '../../../data/api/sms_api.dart';

class SmsLoginScreen extends StatefulWidget {
  const SmsLoginScreen({super.key});

  @override
  State<SmsLoginScreen> createState() => _SmsLoginScreenState();
}

class _SmsLoginScreenState extends State<SmsLoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool isOtpSent = false;
  bool isLoginEnabled = false;
  bool isLoading = false;
  bool customerNotFound = false;

  String? generatedOtp;

  String generateOtp() {
    final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString();
    print("[SMS Login] OTP generated: $otp");
    return otp;
  }

  //Verify customer and send OTP
  Future<void> verifyCustomerAndSendOtp() async {
    final mobile = phoneController.text.trim();

    if (mobile.isEmpty) {
      print("[SMS Login] Mobile number is empty, cannot proceed");
      return;
    }

    print("[SMS Login] Verifying customer for mobile: $mobile");

    setState(() {
      isLoading = true;
      customerNotFound = false;
    });

    try {
      final exists = await CustomerApi.verifyCustomerByMobile(mobile);
      print("[SMS Login] Customer exists: $exists");

      if (!exists) {
        print("[SMS Login] Customer NOT found for mobile: $mobile");
        setState(() {
          customerNotFound = true;
          isOtpSent = false;
        });
        return;
      }

      generatedOtp = generateOtp();

      await SmsApi.sendSms(
        mobile: mobile,
        message: "Your OTP is $generatedOtp",
      );
      print("[SMS Login] OTP sent successfully to $mobile");

      setState(() {
        isOtpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent successfully")),
      );
    } catch (e) {
      print("[SMS Login] Error during OTP flow: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Login after OTP
  void handleLogin() {
    if (!isLoginEnabled) {
      print("[SMS Login] OTP entered is invalid, login not allowed");
      return;
    }

    print("[SMS Login] OTP verified successfully, logging in");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavbar()),
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
                        duration: const Duration(milliseconds: 300),
                        child: customerNotFound
                            ? Column(
                          key: const ValueKey("not_registered"),
                          children: [
                            Text(
                              "You are not registered.",
                              style: AppTextStyles.bodyText1.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                print(
                                    "[SMS Login] Clicked 'Sign up', navigating to RegisterScreen");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Click here to Sign up",
                                style: AppTextStyles.bodyText1.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        )
                            : isOtpSent
                            ? AppTextField(
                          key: const ValueKey("otp"),
                          controller: otpController,
                          hintText: "Enter OTP",
                          prefixIcon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              isLoginEnabled = value == generatedOtp;
                            });
                            print(
                                "[SMS Login] OTP input changed, isLoginEnabled: $isLoginEnabled");
                          },
                        )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: !isOtpSent ? "OK" : "Login",
                          onPressed: () {
                            if (isLoading) return;

                            if (!isOtpSent) {
                              verifyCustomerAndSendOtp();
                            } else {
                              handleLogin();
                            }
                          },
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                TextButton(
                  onPressed: () {
                    print("[SMS Login] Navigating to LoginScreen for email login");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    "Continue with Email",
                    style: AppTextStyles.bodyText1.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
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
