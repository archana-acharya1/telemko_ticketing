// // lib/presentation/screens/auth/registration_otp_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/app_text_styles.dart';
// import '../../../core/theme/app_constants.dart';
// import '../../../services/mobile_verification_service.dart';
// import '../../widgets/app_button.dart';
// import '../../widgets/app_text_field.dart';
// import '../auth/registration_form_screen.dart';
//
// class RegistrationOtpScreen extends StatefulWidget {
//   final String mobile;
//
//   const RegistrationOtpScreen({super.key, required this.mobile});
//
//   @override
//   State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
// }
//
// class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
//   final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
//   final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
//   bool _isLoading = false;
//   bool _isExpired = false;
//   int _secondsRemaining = 600;
//   late Timer _timer;
//   String _otpMessage = "";
//
//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//
//     // Auto-focus first field
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_focusNodes.isNotEmpty) {
//         _focusNodes[0].requestFocus();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     for (var focusNode in _focusNodes) {
//       focusNode.dispose();
//     }
//     _timer.cancel();
//     super.dispose();
//   }
//
//   void _startTimer() {
//     _secondsRemaining = 60;
//     _isExpired = false;
//
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_secondsRemaining > 0) {
//         setState(() => _secondsRemaining--);
//       } else {
//         timer.cancel();
//         setState(() => _isExpired = true);
//       }
//     });
//   }
//
//   void _onOtpChanged(String value, int index) {
//     if (value.isNotEmpty && index < 5) {
//       _focusNodes[index + 1].requestFocus();
//     }
//
//     // Auto-verify if all fields are filled
//     if (_isAllFieldsFilled() && index == 5) {
//       _verifyOtp();
//     }
//   }
//
//   bool _isAllFieldsFilled() {
//     return _controllers.every((controller) => controller.text.isNotEmpty);
//   }
//
//   String _getOtp() {
//     return _controllers.map((c) => c.text).join();
//   }
//
//   Future<void> _verifyOtp() async {
//     if (!_isAllFieldsFilled()) {
//       _showSnackBar("Please enter complete OTP");
//       return;
//     }
//
//     if (_isExpired) {
//       _showSnackBar("OTP has expired. Please resend.");
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     final otp = _getOtp();
//
//     // Verify OTP by navigating to registration form (OTP will be verified there)
//     setState(() => _isLoading = false);
//
//     if (context.mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => RegistrationFormScreen(
//             mobile: widget.mobile,
//             verifiedOtp: otp,
//           ),
//         ),
//       );
//     }
//   }
//
//   void _clearOtpFields() {
//     for (var controller in _controllers) {
//       controller.clear();
//     }
//     _focusNodes[0].requestFocus();
//   }
//
//   Future<void> _resendOtp() async {
//     setState(() => _isLoading = true);
//
//     final result = await MobileVerificationService.resendOtp(widget.mobile);
//
//     setState(() {
//       _isLoading = false;
//       _otpMessage = result["message"] ?? "";
//     });
//
//     if (result["success"] == true) {
//       _clearOtpFields();
//       _startTimer();
//       _showSnackBar("OTP resent successfully");
//     } else {
//       _showSnackBar(result["message"] ?? "Failed to resend OTP");
//     }
//   }
//
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [AppColors.gradientTop, AppColors.gradientBottom],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(AppPadding.lg),
//             child: Column(
//               children: [
//                 const SizedBox(height: 40),
//
//                 // Back button
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
//                   ),
//                 ),
//
//                 Icon(Icons.verified_user, size: 80, color: AppColors.primaryBlue),
//                 const SizedBox(height: 12),
//                 Text("Verify Mobile", style: AppTextStyles.headline1),
//                 const SizedBox(height: 6),
//                 Text(
//                   "OTP sent to ${widget.mobile}",
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
//
//                 if (_otpMessage.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Text(
//                       _otpMessage,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontStyle: FontStyle.italic,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ],
//
//                 const SizedBox(height: 40),
//
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 16,
//                         offset: Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // OTP Input Fields
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: List.generate(6, (index) {
//                           return SizedBox(
//                             width: 45,
//                             child: TextField(
//                               controller: _controllers[index],
//                               focusNode: _focusNodes[index],
//                               textAlign: TextAlign.center,
//                               keyboardType: TextInputType.number,
//                               maxLength: 1,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               decoration: InputDecoration(
//                                 counterText: '',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                   borderSide: BorderSide(
//                                     color: AppColors.primaryBlue,
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               onChanged: (value) => _onOtpChanged(value, index),
//                             ),
//                           );
//                         }),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // Timer
//                       Text(
//                         _isExpired
//                             ? "OTP Expired"
//                             : "Resend OTP in $_secondsRemaining seconds",
//                         style: TextStyle(
//                           color: _isExpired ? Colors.red : Colors.grey[700],
//                           fontWeight: _isExpired ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//
//                       const SizedBox(height: AppPadding.md),
//
//                       // Verify Button
//                       SizedBox(
//                         width: double.infinity,
//                         child: AppButton(
//                           text: _isLoading ? "Verifying..." : "Verify OTP",
//                           color: AppColors.primaryBlue,
//                           onPressed: _isLoading || _isExpired ? null : _verifyOtp,
//                         ),
//                       ),
//
//                       const SizedBox(height: AppPadding.md),
//
//                       // Resend Button
//                       if (_isExpired)
//                         SizedBox(
//                           width: double.infinity,
//                           child: OutlinedButton(
//                             onPressed: _isLoading ? null : _resendOtp,
//                             style: OutlinedButton.styleFrom(
//                               side: BorderSide(color: AppColors.primaryBlue),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                             ),
//                             child: _isLoading
//                                 ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                               ),
//                             )
//                                 : Text(
//                               "Resend OTP",
//                               style: TextStyle(
//                                 color: AppColors.primaryBlue,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                       const SizedBox(height: AppPadding.md),
//
//                       // Back Link
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text(
//                           "Change Mobile Number",
//                           style: AppTextStyles.bodyText1.copyWith(
//                             decoration: TextDecoration.underline,
//                             color: AppColors.primaryBlue,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }