import 'package:telemko_support/presentation/screens/dashboard/lib/data/local/session_manager.dart';

class SessionHelper {
  // Save session after username/password login
  static Future<void> saveAfterPasswordLogin(Map<String, dynamic> loginData) async {
    print("💾 Saving password login session...");

    final sid = loginData["sid"];
    final user = loginData["user"] ?? {};
    final fullName = user["full_name"] ?? "";
    final email = user["email"] ?? "";
    final mobile = user["mobile_no"] ?? "";

    if (sid != null && sid.isNotEmpty) {
      await SessionManager.saveCustomerSession(
        customerName: fullName.isNotEmpty ? fullName : email,
        mobileNo: mobile,
        emailId: email,
        sid: sid,
        loginType: 'password',
      );
      print(" Password login session saved");
    }
  }

  // Save session after OTP login
  static Future<void> saveAfterOtpLogin({
    required String mobile,
    required String sid,
    required Map<String, dynamic> loginResult,
  }) async {
    print("💾 Saving OTP login session...");

    final user = loginResult['user'] ?? '';
    final fullName = loginResult['full_name'] ?? '';
    final data = loginResult['data'] ?? {};

    // Extract customer name
    String customerName = fullName;
    if (customerName.isEmpty) {
      customerName = user.isNotEmpty ? user : "Customer ($mobile)";
    }

    // Extract email
    String emailId = '';
    if (user.contains('@')) {
      emailId = user;
    } else if (data['email'] != null) {
      emailId = data['email'];
    } else {
      // Use mobile as email for consistency with username/password login
      emailId = "$mobile@telemko.com";
    }

    if (sid.isNotEmpty) {
      await SessionManager.saveCustomerSession(
        customerName: customerName,
        mobileNo: mobile,
        emailId: emailId,
        sid: sid,
        loginType: 'mobile', // Or 'otp' - whichever matches password login
      );
      print("✅ OTP login session saved");
      print("   Customer Name: $customerName");
      print("   Mobile: $mobile");
      print("   Email: $emailId");
      print("   SID: ${sid.substring(0, 20)}...");
    }
  }

  // Debug current session
  static Future<void> debugCurrentSession() async {
    print("🔍 === CURRENT SESSION ===");
    final session = await SessionManager.getCustomerSession();
    if (session != null) {
      session.forEach((key, value) {
        print("  $key: $value");
      });
    } else {
      print("  No session found");
    }
    print("==========================");
  }
}