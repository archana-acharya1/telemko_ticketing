// register_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterApi {
  static const String baseUrl = "http://erp.talemka.com"; // or telemko.com

  /// Check if mobile number already registered
  static Future<bool> isMobileAlreadyRegistered(String mobileNo) async {
    try {
      final url = Uri.parse("$baseUrl/api/resource/Customer");

      // Build query parameters exactly like your example
      final params = {
        'fields': '["name"]',
        'filters': '[["mobile_no","=","$mobileNo"]]'
      };

      final uri = Uri.https(url.authority, url.path, params);

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print("[RegisterApi] Check mobile response: ${response.statusCode}");
      print("[RegisterApi] Check mobile body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if data exists and has entries
        bool exists = data["data"] != null &&
            data["data"] is List &&
            data["data"].isNotEmpty;

        print("[RegisterApi] Mobile $mobileNo exists: $exists");
        return exists;
      }

      return false;
    } catch (e) {
      print("[RegisterApi] Error checking mobile: $e");
      return false;
    }
  }

  /// Send OTP for registration
  static Future<bool> sendRegistrationOtp(String mobileNo) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.register.send_registration_otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile_no": mobileNo}),
      );

      print("[RegisterApi] Send OTP response: ${response.statusCode}");
      print("[RegisterApi] Send OTP body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("[RegisterApi] Error sending OTP: $e");
      return false;
    }
  }

  /// Verify registration OTP
  static Future<Map<String, dynamic>?> verifyRegistrationOtp({
    required String mobileNo
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.register.verify_registration_otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobile_no": mobileNo,
        }),
      );

      print("[RegisterApi] Verify OTP response: ${response.statusCode}");
      print("[RegisterApi] Verify OTP body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["message"];
      }
      return null;
    } catch (e) {
      print("[RegisterApi] Error verifying OTP: $e");
      return null;
    }
  }

  /// Complete registration with optional fields
  static Future<Map<String, dynamic>?> completeRegistration({
    required String mobileNo,
    required String otp,
    required String customerName,
    required String email,
    String? vehicleNumber,
    String? customerPrimaryAddress,
  }) async {
    try {
      Map<String, dynamic> requestBody = {
        "mobile_no": mobileNo,
        "otp": otp,
        "customer_name": customerName,
        "email": email,
      };

      // Add optional fields if provided
      if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
        requestBody["vehicle_number"] = vehicleNumber;
      }

      if (customerPrimaryAddress != null && customerPrimaryAddress.isNotEmpty) {
        requestBody["customer_primary_address"] = customerPrimaryAddress;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/method/telemko_support.api.register.complete_registration"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("[RegisterApi] Registration response: ${response.statusCode}");
      print("[RegisterApi] Registration body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["message"];
      }
      return null;
    } catch (e) {
      print("[RegisterApi] Error completing registration: $e");
      return null;
    }
  }
}