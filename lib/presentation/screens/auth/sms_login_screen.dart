import 'package:flutter/material.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../navbar/main_navbar.dart';

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

  void sendOtp() async {
    if (phoneController.text.isEmpty) return;

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isOtpSent = true;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent to your mobile number')),
    );
  }

  void handleLogin() async {
    if (!isLoginEnabled) return;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            // ✅ GRADIENT BACKGROUND
            width: double.infinity,
            height: constraints.maxHeight,
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button (on gradient)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: AppColors.primaryBlue,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Icon
                      Icon(
                        Icons.sms_outlined,
                        size: 80,
                        color: AppColors.primaryBlue,
                      ),

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

                      // ✅ PURE WHITE CARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white, // 👈 IMPORTANT
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
                                child: isOtpSent
                                    ? AppTextField(
                                  key: const ValueKey("otp"),
                                  controller: otpController,
                                  hintText: "Enter OTP",
                                  prefixIcon: Icons.lock_outline,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      isLoginEnabled =
                                          value.length == 6;
                                    });
                                  },
                                )
                                    : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text:
                                  !isOtpSent ? "Get OTP" : "Login",
                                  onPressed: () {
                                    if (isLoading) return;
                                    !isOtpSent
                                        ? sendOtp()
                                        : handleLogin();
                                  },
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
