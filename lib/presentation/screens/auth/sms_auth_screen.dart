import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:telemko_support/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:telemko_support/presentation/screens/test/test_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../../services/customer_service.dart';
import '../../../services/mobile_verification_service.dart';
import '../../../services/session_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/legal_document_dialog.dart';
import '../dashboard/lib/data/local/session_manager.dart';
import '../navbar/main_navbar.dart';
import 'login_screen.dart';
import 'registration_form_screen.dart';

class SmsAuthScreen extends StatefulWidget {
  const SmsAuthScreen({super.key});

  @override
  State<SmsAuthScreen> createState() => _SmsAuthScreenState();
}

class _SmsAuthScreenState extends State<SmsAuthScreen> {
  final mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool otpSent = false;
  bool? isExistingUser;
  String storedMobile = "";

  bool _isOtpExpired = false;
  int _otpSecondsRemaining = 600;
  Timer? _otpTimer;

  // Track the last filled index for smart backspace
  int _lastFilledIndex = -1;

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes
    for (int i = 0; i < _otpFocusNodes.length; i++) {
      _otpFocusNodes[i].addListener(() {
        // When a field gains focus, select all text for easy deletion
        if (_otpFocusNodes[i].hasFocus && _otpControllers[i].text.isNotEmpty) {
          _otpControllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[i].text.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpSecondsRemaining = 600;
    _isOtpExpired = false;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpSecondsRemaining > 0) {
        setState(() => _otpSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isOtpExpired = true);
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    if (_isAllOtpFieldsFilled() && index == 5) {
      _verifyOtp();
    }
  }

  bool _isAllOtpFieldsFilled() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getEnteredOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _showLegalDocument(String type) {
    showDialog(
      context: context,
      builder: (context) => LegalDocumentDialog(documentType: type),
    );
  }

  // Update last filled index
  void _updateLastFilledIndex() {
    for (int i = 5; i >= 0; i--) {
      if (_otpControllers[i].text.isNotEmpty) {
        _lastFilledIndex = i;
        return;
      }
    }
    _lastFilledIndex = -1;
  }

  // Handle OTP input and navigation
  void _handleOtpInput(String value, int index) {
    if (value.length == 1) {
      // Digit entered - move to next field
      _otpControllers[index].text = value;
      _updateLastFilledIndex();

      if (index < 5) {
        Future.delayed(const Duration(milliseconds: 10), () {
          _otpFocusNodes[index + 1].requestFocus();
        });
      } else {
        // Last field - check if ready to submit
        if (_isAllOtpFieldsFilled()) {
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 100), () {
            _verifyOtp();
          });
        }
      }
    } else if (value.isEmpty) {
      // Backspace pressed
      _otpControllers[index].clear();
      _updateLastFilledIndex();

      // Smart backspace logic
      if (index > 0) {
        // Move to the last filled field or previous field
        int targetIndex = _lastFilledIndex >= 0 ? _lastFilledIndex : index - 1;

        Future.delayed(const Duration(milliseconds: 10), () {
          _otpFocusNodes[targetIndex].requestFocus();
          // Select all text in target field for easy deletion
          if (_otpControllers[targetIndex].text.isNotEmpty) {
            _otpControllers[targetIndex].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _otpControllers[targetIndex].text.length,
            );
          }
        });
      }
    }
  }

  // Clear all OTP fields
  void _clearAllOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _lastFilledIndex = -1;
    if (_otpFocusNodes.isNotEmpty) {
      _otpFocusNodes[0].requestFocus();
    }
  }

  // Clear OTP fields from a specific index backwards
  void _clearOtpFromIndex(int fromIndex) {
    for (int i = fromIndex; i < _otpControllers.length; i++) {
      _otpControllers[i].clear();
    }
    _updateLastFilledIndex();

    // Focus on the cleared field
    if (fromIndex >= 0 && fromIndex < _otpFocusNodes.length) {
      _otpFocusNodes[fromIndex].requestFocus();
    }
  }

  Future<void> _sendOtp() async {
    final mobile = mobileController.text.trim();

    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Enter mobile number",
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Enter 10-digit mobile",
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      storedMobile = mobile;
      isExistingUser = null;
    });

    try {
      print("📱 Starting OTP flow for: $mobile");

      final customerExists = await MobileVerificationService.isCustomerExists(mobile);
      print("✅ Customer check result: $customerExists");

      setState(() {
        isExistingUser = customerExists;
      });

      Map<String, dynamic> otpResult;

      if (customerExists) {
        print("👤 EXISTING CUSTOMER - Sending LOGIN OTP");
        otpResult = await MobileVerificationService.sendLoginOtp(mobile);
      } else {
        print("👤 NEW CUSTOMER - Sending REGISTRATION OTP");
        otpResult = await MobileVerificationService.sendRegistrationOtp(mobile);
      }

      setState(() => isLoading = false);

      if (otpResult["success"] == true) {
        setState(() {
          otpSent = true;
        });
        _clearAllOtpFields();
        _startOtpTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              otpResult["message"] ?? "OTP sent successfully",
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Focus first OTP field
        if (_otpFocusNodes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              otpResult["message"] ?? "Failed to send OTP",
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error in _sendOtp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isAllOtpFieldsFilled()) {
      _showSnackBar("Please enter all OTP digits");
      return;
    }

    if (_isOtpExpired) {
      _showSnackBar("OTP has expired. Please request a new one.");
      return;
    }

    final otp = _getEnteredOtp();
    print("🔄 Verifying OTP: $otp for mobile: $storedMobile");

    setState(() => isLoading = true);

    try {
      if (isExistingUser == true) {
        print("📞 Calling CustomerService.loginWithOtp...");

        final loginData = await CustomerService.loginWithOtp(storedMobile, otp);

        setState(() => isLoading = false);

        if (loginData != null && loginData["sid"] != null) {
          print("✅ OTP Login successful!");

          await Future.delayed(const Duration(milliseconds: 300));

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainNavbar()),
                (route) => false,
          );

          _showSnackBar("Login successful!");
        } else {
          print("❌ OTP Login failed - No session data returned");
          _showSnackBar("Invalid OTP or login failed");
          _clearAllOtpFields();
        }
      } else {
        setState(() => isLoading = false);
        print("👤 New user, navigating to registration");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationFormScreen(
              mobile: storedMobile,
              verifiedOtp: otp,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("💥 Error in OTP verification: $e");
      _showSnackBar("Error: ${e.toString()}");
      _clearAllOtpFields();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        backgroundColor: message.toLowerCase().contains("success")
            ? AppColors.success
            : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
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
            padding: const EdgeInsets.all(AppPadding.md),
            child: Column(
              children: [
                const SizedBox(height: 40),

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

                const SizedBox(height: 6),

                // User status indicator
                if (otpSent && isExistingUser != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: isExistingUser!
                          ? AppColors.success.withOpacity(isDarkMode ? 0.2 : 0.1)
                          : colorScheme.primary.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isExistingUser!
                            ? AppColors.success
                            : colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isExistingUser! ? Icons.person : Icons.person_add,
                          color: isExistingUser! ? AppColors.success : colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExistingUser! ? "Registered user" : "New user",
                          style: TextStyle(
                            color: isExistingUser! ? AppColors.success : colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black12,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        otpSent ? "Enter OTP" : "Login/Register",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (!otpSent)
                        TextField(
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Enter your mobile number",
                            hintText: "Enter 10-digit number",
                            prefixIcon: Icon(Icons.phone, color: colorScheme.primary.withOpacity(0.8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceVariant.withOpacity(0.9),
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),

                      // OTP fields (when OTP sent)
                      if (otpSent) ...[
                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            "Enter the 6-digit OTP sent to $storedMobile",
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 45,
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  // Handle backspace for rapid deletion
                                  if (event is KeyDownEvent &&
                                      event.logicalKey == LogicalKeyboardKey.backspace) {
                                    if (_otpControllers[index].text.isEmpty && index > 0) {
                                      // Clear previous field and move focus there
                                      _otpControllers[index - 1].clear();
                                      _otpFocusNodes[index - 1].requestFocus();
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextFormField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    _handleOtpInput(value, index);
                                  },
                                  onTap: () {
                                    // When tapping a field with text, select all for easy deletion
                                    if (_otpControllers[index].text.isNotEmpty) {
                                      _otpControllers[index].selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _otpControllers[index].text.length,
                                      );
                                    }
                                  },
                                  textInputAction: index == 5 ? TextInputAction.done : TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 20),

                        // Quick clear button
                        if (_lastFilledIndex > 0)
                          TextButton(
                            onPressed: () {
                              // Clear all OTP fields
                              _clearAllOtpFields();
                            },
                            child: Text(
                              "Clear All",
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // OTP timer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isOtpExpired
                                ? colorScheme.errorContainer
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: _isOtpExpired
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isOtpExpired ? Icons.timer_off : Icons.timer,
                                color: _isOtpExpired
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isOtpExpired ? "OTP Expired" : "Valid for ${_formatTime(_otpSecondsRemaining)}",
                                style: TextStyle(
                                  color: _isOtpExpired
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 20),

                      // Main action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : (otpSent ? _verifyOtp : _sendOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            isLoading
                                ? "Please wait..."
                                : otpSent
                                ? (isExistingUser == true ? "Login" : "Continue Registration")
                                : "Send OTP",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Resend OTP button (when expired)
                      if (otpSent && _isOtpExpired)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _sendOtp,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              backgroundColor: colorScheme.primary.withOpacity(0.1),
                            ),
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Alternative option
                      TextButton(
                        onPressed: otpSent
                            ? () {
                          setState(() {
                            otpSent = false;
                            _clearAllOtpFields();
                            mobileController.clear();
                          });
                        }
                            : () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: Text(
                          otpSent ? "Change Mobile Number" : "Login with Password",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Column(
                  children: [
                    // First line
                    Text(
                      "By tapping on Login, you are agreeing to our",
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Second line with clickable links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Terms & Conditions link
                        GestureDetector(
                          onTap: () => _showLegalDocument('terms'),
                          child: Text(
                            "Terms & Conditions",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        Text(
                          " and ",
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),

                        // Privacy Policy link
                        GestureDetector(
                          onTap: () => _showLegalDocument('privacy'),
                          child: Text(
                            "Privacy Policy",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        Text(
                          " ! ",
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}