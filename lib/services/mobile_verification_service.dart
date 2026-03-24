// lib/services/mobile_verification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class MobileVerificationService {
  static const String baseUrl = "http://erp.telemko.com";
  static const String apiToken = "d8194889a199fc4:598c54965a4e106";

  static String? _extractSidFromSetCookie(Map<String, String> headers) {
    final setCookie = headers["set-cookie"] ?? headers["Set-Cookie"];
    if (setCookie == null || setCookie.isEmpty) return null;

    // `Set-Cookie` can contain multiple cookies.
    final cookieStrings = setCookie.split(',');
    for (final cookieStr in cookieStrings) {
      final trimmed = cookieStr.trim();
      final match = RegExp(r"sid=([^;\s,]+)").firstMatch(trimmed);
      final sid = match?.group(1)?.trim();
      if (sid != null && sid.isNotEmpty && sid != "Logged In" && sid.length > 10) {
        return sid;
      }
    }
    return null;
  }

  static bool _looksLikeValidSid(dynamic sid) {
    if (sid is! String) return false;
    return sid.isNotEmpty && sid != "Logged In" && sid.length > 10;
  }

  /// Public helper to validate SID (e.g. after registration) so only valid sessions are used.
  static bool isValidSid(dynamic sid) {
    if (sid == null) return false;
    final s = sid is String ? sid : sid.toString();
    return s.isNotEmpty && s != "Logged In" && s.length > 10;
  }


  /// Check if customer exists using the verify_customer_and_user API
  static Future<bool> isCustomerExists(String mobileNo) async {
    try {
      print("🔍 Checking if customer exists: $mobileNo");

      // Use the verify_customer_and_user API endpoint
      final url = Uri.parse(
          "$baseUrl/api/method/telemko_support.api.verify_customer_user.verify_customer_and_user?mobile_no=$mobileNo"
      );

      final response = await http.get(url);
      print("📊 Verification API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'];

        // Check if customer exists based on API response
        final customerExists = message['customer_exists'] ?? false;
        final userExists = message['user_exists'] ?? false;

        print("✅ API Response: customer_exists=$customerExists, user_exists=$userExists");

        // Consider it exists if either customer or user exists
        return customerExists || userExists;
      } else {
        print("❌ Verification API Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Verification API Exception: $e");
      return false;
    }
  }

  /// Send OTP for LOGIN (existing customers)
  static Future<Map<String, dynamic>> sendLoginOtp(String mobileNo) async {
    try {
      print("📱 Sending LOGIN OTP to: $mobileNo");

      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.send_otp.send_otp"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "token $apiToken",
        },
        body: jsonEncode({"mobile_no": mobileNo}),
      );

      print("📊 Login OTP Status: ${response.statusCode}");
      print("📊 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? {};

        return {
          "success": true,
          "message": message['message'] ?? "Login OTP sent successfully",
          "api_response": data
        };
      } else {
        return {
          "success": false,
          "message": "Failed to send login OTP",
          "error": "Status: ${response.statusCode}",
          "api_response": response.body
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error",
        "error": e.toString()
      };
    }
  }

  /// Send OTP for REGISTRATION (new customers)
  /// Send OTP for REGISTRATION (new customers)
  static Future<Map<String, dynamic>> sendRegistrationOtp(String mobileNo) async {
    try {
      print("📱 Sending REGISTRATION OTP to: $mobileNo");

      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.registration.send_otp.send_registration_otp"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "token $apiToken",
        },
        body: jsonEncode({"mobile_no": mobileNo}),
      );

      print("📊 Registration OTP Status: ${response.statusCode}");
      print("📊 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? {};

        return {
          "success": true,
          "message": message['message'] ?? "Registration OTP sent successfully",
          "api_response": data
        };
      } else {
        return {
          "success": false,
          "message": "Failed to send registration OTP",
          "error": "Status: ${response.statusCode}",
          "api_response": response.body
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error",
        "error": e.toString()
      };
    }
  }
  /// Verify OTP and LOGIN (existing customers)
  static Future<Map<String, dynamic>> verifyLoginOtp(String mobileNo, String otp) async {
    try {
      print("🔐 Verifying LOGIN OTP for: $mobileNo");

      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.custom_mobile_login.mobile_login"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "token $apiToken",
          },
        body: jsonEncode({
          "mobile_no": mobileNo,
          "otp": otp,
        }),
      );

      print("📊 Login API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? {};

        print("📊 Full API Response: $data");

        // Extract ALL important data
        final sidFromBody = message['sid'];
        final sidFromCookie = _extractSidFromSetCookie(response.headers);
        final sid = _looksLikeValidSid(sidFromBody) ? sidFromBody : sidFromCookie;
        final user = message['user']?.toString();
        final fullName = message['full_name']?.toString();
        final responseMessage = message['message']?.toString() ?? '';

        if (sid != null && sid.toString().isNotEmpty) {
          print("✅ Login verified successfully!");
          print("   SID: $sid");
          print("   User: $user");
          print("   Full Name: $fullName");

          return {
            "success": true,
            "message": responseMessage,
            "sid": sid,
            "user": user,
            "full_name": fullName,
            "data": message,  // Include full data
          };
        } else {
          print("❌ No valid SID in response body or cookie");
          return {
            "success": false,
            "message": "Login failed: No session ID",
            "error": "No SID in response",
          };
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        return {
          "success": false,
          "message": "Invalid OTP or server error",
          "error": "Status: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("❌ Network error: $e");
      return {
        "success": false,
        "message": "Network error",
        "error": e.toString(),
      };
    }
  }
  /// Complete registration
  static Future<Map<String, dynamic>> completeRegistration({
    required String mobileNo,
    required String otp,
    required String customerName,
    required String emailId,
    String? vehicleNumber,
    String? customerPrimaryAddress,
  }) async {
    try {
      print("📝 Completing registration for: $mobileNo");
      print("🚗 Vehicle Number: $vehicleNumber");
      print("🏠 Customer Address: $customerPrimaryAddress");

      // ✅ FIX: Create request body with optional fields
      Map<String, dynamic> requestBody = {
        "mobile_no": mobileNo,
        "otp": otp,
        "customer_name": customerName,
        "email_id": emailId,
      };


      if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
        requestBody["vehicle_number"] = vehicleNumber.trim();
      }

      if (customerPrimaryAddress != null && customerPrimaryAddress.trim().isNotEmpty) {
        requestBody["customer_primary_address"] = customerPrimaryAddress.trim();
      }

      print(" Request Body: $requestBody");

      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.registration.verify_and_complete.complete_registration"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "token $apiToken",
          },
        body: jsonEncode(requestBody),
      );

      print(" Complete Registration Status: ${response.statusCode}");
      print(" Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? {};

        // Check if registration was successful
        final responseMessage = message['message']?.toString().toLowerCase() ?? '';
        final isSuccess = responseMessage.contains('success') ||
            responseMessage.contains('registered') ||
            responseMessage.contains('created');

        if (isSuccess) {
          // After successful registration, you might want to auto-login
          // or save the user data. The API might return a SID.
          final sidFromBody = message['sid'];
          final sidFromCookie = _extractSidFromSetCookie(response.headers);
          final sid = _looksLikeValidSid(sidFromBody) ? sidFromBody : sidFromCookie;

          if (sid != null) {
            // Save session after registration
            await SessionManager.saveCustomerSession(
              customerName: customerName,
              mobileNo: mobileNo,
              emailId: emailId,
              sid: sid,
              loginType: 'otp',
            );
            print(" Registration successful and session saved!");
          }

          return {
            "success": true,
            "message": message['message'] ?? "Registration successful",
            "data": data,
            "api_response": data,
            "sid": sid,
          };
        } else {
          return {
            "success": false,
            "message": message['message'] ?? "Registration failed",
            "error": message['message'],
            "api_response": data
          };
        }
      } else {
        return {
          "success": false,
          "message": "Registration failed",
          "error": "Status: ${response.statusCode}",
          "api_response": response.body
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error",
        "error": e.toString()
      };
    }
  }
  /// Send appropriate OTP based on customer status
  static Future<Map<String, dynamic>> sendAppropriateOtp(String mobileNo) async {
    try {
      // Step 1: Check if customer exists
      final customerExists = await isCustomerExists(mobileNo);

      if (customerExists) {
        print("👤 Customer exists - sending LOGIN OTP");
        return await sendLoginOtp(mobileNo);
      } else {
        print("👤 New customer - sending REGISTRATION OTP");
        return await sendRegistrationOtp(mobileNo);
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Failed to send OTP",
        "error": e.toString()
      };
    }
  }
}