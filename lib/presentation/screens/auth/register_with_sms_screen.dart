// // lib/presentation/screens/auth/register_with_sms_screen.dart
// import 'package:flutter/material.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/app_text_styles.dart';
// import '../../../core/theme/app_constants.dart';
// import '../../../services/mobile_verification_service.dart';
// import '../../widgets/app_button.dart';
// import '../../widgets/app_text_field.dart';
// import '../otp/registration_otp_screen.dart';
// import 'sms_auth_screen.dart';
//
// class RegisterWithSmsScreen extends StatefulWidget {
//   const RegisterWithSmsScreen({super.key});
//
//   @override
//   State<RegisterWithSmsScreen> createState() => _RegisterWithSmsScreenState();
// }
//
// class _RegisterWithSmsScreenState extends State<RegisterWithSmsScreen> {
//   final mobileController = TextEditingController();
//   bool isLoading = false;
//   bool? userExists;
//
//   Future<void> checkMobileForRegistration() async {
//     final mobile = mobileController.text.trim();
//
//     // Validate mobile number
//     if (mobile.isEmpty) {
//       _showSnackBar("Please enter mobile number");
//       return;
//     }
//
//     if (mobile.length != 10) {
//       _showSnackBar("Please enter valid 10-digit mobile number");
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//       userExists = null;
//     });
//
//     try {
//       // Check if mobile already registered
//       final exists = await MobileVerificationService.isMobileAlreadyRegistered(mobile);
//
//       setState(() {
//         userExists = exists;
//         isLoading = false;
//       });
//
//       if (exists) {
//         // User already registered - show alert
//         _showAlreadyRegisteredAlert(mobile);
//       } else {
//         // User doesn't exist - send OTP for registration
//         await _sendRegistrationOtp(mobile);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       _showSnackBar("Error checking mobile number. Please try again.");
//     }
//   }
//
//   Future<void> _sendRegistrationOtp(String mobile) async {
//     setState(() => isLoading = true);
//
//     final result = await MobileVerificationService.sendRegistrationOtp(mobile);
//
//     setState(() => isLoading = false);
//
//     if (result["success"] == true && context.mounted) {
//       // Navigate to registration OTP screen
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => RegistrationOtpScreen(mobile: mobile),
//         ),
//       );
//     } else if (context.mounted) {
//       _showSnackBar(result["message"] ?? "Failed to send OTP. Please try again.");
//     }
//   }
//
//   void _showAlreadyRegisteredAlert(String mobile) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.info, color: Colors.orange[800]),
//             const SizedBox(width: 10),
//             const Text("Already Registered"),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "The mobile number $mobile is already registered.",
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "Please login instead of registering again.",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 mobileController.clear();
//                 userExists = null;
//               });
//             },
//             child: const Text("Use Different Number"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context); // Close dialog
//               _navigateToLogin(mobile);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primaryBlue,
//             ),
//             child: const Text("Login Now", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _navigateToLogin(String mobile) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SmsAuthScreen(),
//       ),
//     );
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
//   void dispose() {
//     mobileController.dispose();
//     super.dispose();
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
//                 Icon(Icons.app_registration, size: 80, color: AppColors.primaryBlue),
//                 const SizedBox(height: 12),
//                 Text("Register with SMS", style: AppTextStyles.headline1),
//                 const SizedBox(height: 6),
//                 Text(
//                   "Enter your mobile number to create account",
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
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
//                       // Mobile Input
//                       AppTextField(
//                         controller: mobileController,
//                         hintText: "Mobile Number",
//                         prefixIcon: Icons.phone,
//                         keyboardType: TextInputType.phone,
//                       ),
//
//                       const SizedBox(height: AppPadding.md),
//
//                       // Already Registered Message
//                       if (userExists == true)
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.orange[50],
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.orange),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(Icons.info, color: Colors.orange[800], size: 20),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     "Already Registered",
//                                     style: TextStyle(
//                                       color: Colors.orange[800],
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 "This number is already registered. Please login instead.",
//                                 style: TextStyle(color: Colors.orange[700]),
//                               ),
//                               const SizedBox(height: 12),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: AppButton(
//                                   text: "Login Now",
//                                   color: AppColors.primaryBlue,
//                                   onPressed: () => _navigateToLogin(mobileController.text.trim()),
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               TextButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     mobileController.clear();
//                                     userExists = null;
//                                   });
//                                 },
//                                 child: const Text("Use Different Number"),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                       const SizedBox(height: AppPadding.md),
//
//                       // Check Button
//                       SizedBox(
//                         width: double.infinity,
//                         child: AppButton(
//                           text: isLoading ? "Checking..." : "Continue",
//                           color: AppColors.primaryBlue,
//                           onPressed: isLoading ? null : checkMobileForRegistration,
//                         ),
//                       ),
//
//                       const SizedBox(height: AppPadding.md),
//
//                       // Back Link
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text(
//                           "Back to Registration Options",
//                           style: AppTextStyles.bodyText1.copyWith(
//                             decoration: TextDecoration.underline,
//                             fontWeight: FontWeight.w600,
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