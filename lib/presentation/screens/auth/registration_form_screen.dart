import 'package:flutter/material.dart';
import 'package:telemko_support/services/mobile_verification_service.dart';
import 'package:telemko_support/presentation/screens/navbar/main_navbar.dart';
import 'package:telemko_support/presentation/screens/auth/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_constants.dart';
import '../../widgets/app_button.dart';

class RegistrationFormScreen extends StatefulWidget {
  final String mobile;
  final String verifiedOtp;

  const RegistrationFormScreen({
    super.key,
    required this.mobile,
    required this.verifiedOtp,
  });

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _addressController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isLoading = true;
      });

      try {
        print(" Completing registration for mobile: ${widget.mobile}");

        // Construct full email from username
        final username = _emailController.text.trim();
        final fullEmail = '$username@telemko.com';

        print(" Constructed email: $fullEmail");

        final result = await MobileVerificationService.completeRegistration(
          mobileNo: widget.mobile,
          otp: widget.verifiedOtp,
          customerName: _nameController.text.trim(),
          emailId: fullEmail, // Use the constructed full email
          vehicleNumber: _vehicleController.text.trim(),
          customerPrimaryAddress: _addressController.text.trim(),
        );

        setState(() {
          isLoading = false;
        });

        print(" Registration Result: ${result["success"]}");
        print(" Registration Message: ${result["message"]}");

        if (result["success"] == true) {
          // Check if auto-login was successful
          if (result["auto_login"] == true && result["sid"] != null) {
            print(" Registration + Auto-login successful! Navigating to main app...");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result["message"] ?? "Registration successful!"),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavbar()),
                  (route) => false,
            );
          } else {
            print(" Registration successful! Navigating to login...");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result["message"] ?? "Registration successful! Please login."),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          }
        } else {
          // Check if it's actually a success disguised as failure
          final errorMsg = result["message"]?.toString().toLowerCase() ?? "";

          if (errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
            final loginResult = await MobileVerificationService.verifyLoginOtp(
              widget.mobile,
              widget.verifiedOtp,
            );

            if (loginResult["success"] == true && loginResult["sid"] != null) {
              print("✅ Login successful (user already existed)");

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Welcome back! Login successful."),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavbar()),
                    (route) => false,
              );
              return;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Registration failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        print("❌ Registration error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Registration"),
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Complete Your Profile",
                style: AppTextStyles.headline2.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Fill in your details to complete registration",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),

              // Mobile Number (read-only)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mobile Number",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.mobile,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: " Name *",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppPadding.md),

              // Email with auto-suffix - Better version using suffixText
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Enter email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                      suffixText: "@telemko.com",
                      suffixStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.contains('@')) {
                        return 'Just enter username without @telemko.com';
                      }
                      // Allow letters, numbers, dots, underscores
                      if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
                        return 'Only letters, numbers, dots and underscores allowed';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild to update preview
                    },
                  ),
                  const SizedBox(height: 4),
                  if (_emailController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        "Email will be: ${_emailController.text.trim()}@telemko.com",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppPadding.md),

              // Vehicle Number (Optional)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _vehicleController,
                    decoration: InputDecoration(
                      hintText: "Vehicle Number (Optional)",
                      prefixIcon: Icon(Icons.directions_car),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text(
                      "Example: BA 1 PA 1234",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppPadding.md),

              // Customer Address (Optional)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: "Primary Address (Optional)",
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text(
                      "Your address for service requests",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: isLoading ? "Processing..." : "Complete Registration",
                  color: AppColors.primaryBlue,
                  onPressed: isLoading ? null : _completeRegistration,
                ),
              ),

              const SizedBox(height: 16),

              // Note about optional fields
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Vehicle number and address are optional. You can add them later from your profile.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}