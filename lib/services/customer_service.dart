import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class CustomerService {
  static const String baseUrl = "http://erp.telemko.com";

  /// Login with username/password
  /// Uses standard Frappe login endpoint: /api/method/login
  static Future<Map<String, dynamic>?> loginUser({
    required String usr,
    required String pwd,
  }) async {
    print("[CustomerService] Attempting username/password login for: $usr");
    
    final url = Uri.parse("$baseUrl/api/method/login");
    print("[CustomerService] Login URL: $url");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usr": usr, "pwd": pwd}),
    );

    print("[CustomerService] Login response status: ${response.statusCode}");
    print("[CustomerService] Login response headers: ${response.headers}");
    print("[CustomerService] Login response body: ${response.body}");

    if (response.statusCode == 200) {
      String? sid;
      
      // Standard Frappe login returns SID in Set-Cookie header
      // Try to extract from Set-Cookie header first (this is the standard way)
      // HTTP headers are case-insensitive, but http package stores them lowercase
      final setCookie = response.headers["set-cookie"] ?? response.headers["Set-Cookie"];
      print("[CustomerService] Set-Cookie header: $setCookie");
      print("[CustomerService] All response headers: ${response.headers}");
      
      if (setCookie != null && setCookie.isNotEmpty) {
        // Cookie header format: "sid=abc123; Path=/; HttpOnly" 
        // Handle multiple cookies separated by comma or semicolon
        // First try splitting by comma (multiple Set-Cookie headers combined)
        final cookieStrings = setCookie.split(',');
        for (final cookieStr in cookieStrings) {
          final trimmed = cookieStr.trim();
          // Look for sid=value pattern (value can contain alphanumeric, -, _, etc)
          final match = RegExp(r"sid=([^;\s,]+)").firstMatch(trimmed);
          if (match != null) {
            final extractedSid = match.group(1)?.trim();
            if (extractedSid != null && extractedSid.isNotEmpty && extractedSid != "Logged In") {
              sid = extractedSid;
              print("[CustomerService] SID extracted from cookie: $sid");
              break;
            }
          }
        }
      }

      // Also check response body (in case custom endpoint returns it there)
      try {
        final data = jsonDecode(response.body);
        final message = data["message"];
        
        // If message is a Map with sid, use it (takes precedence)
        if (message is Map<String, dynamic> && message["sid"] != null) {
          sid = message["sid"] as String;
          print("[CustomerService] SID found in response body: $sid");
          
          // Save session with user details from response
          if (sid.isNotEmpty) {
            await SessionManager.saveCustomerSession(
              customerName: message["customer_name"] ?? message["full_name"] ?? usr,
              mobileNo: message["mobile_no"] ?? message["mobile"] ?? "",
              emailId: message["email_id"] ?? message["email"] ?? message["email_id"] ?? "",
              sid: sid,
              loginType: "normal",
            );
            
            print("[CustomerService] Username/password login successful with user details");
            return message;
          }
        }
      } catch (e) {
        print("[CustomerService] Error parsing response body: $e");
      }

      // If we have SID from cookie but no user details in body, save session anyway
      if (sid != null && sid.isNotEmpty && sid != "Logged In") {
        await SessionManager.saveCustomerSession(
          customerName: usr, // Use username as fallback
          mobileNo: "",
          emailId: "",
          sid: sid,
          loginType: "normal",
        );
        
        print("[CustomerService] Username/password login successful (SID from cookie): $sid");
        return {"sid": sid, "message": "Logged In"};
      } else {
        print("[CustomerService] Login failed: No valid SID found in response. SID value: $sid");
      }
    } else {
      print("[CustomerService] Login failed with status: ${response.statusCode}");
      print("[CustomerService] Response body: ${response.body}");
    }
    
    return null;
  }

  /// Send OTP
  static Future<bool> sendOtp(String mobileNo) async {
    final url = Uri.parse(
      "$baseUrl/api/method/telemko_support.api.send_otp.send_otp",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile_no": mobileNo}),
    );
    return response.statusCode == 200;
  }


  static Future<Map<String, dynamic>?> loginWithOtp(
      String mobileNo,
      String otp,
      ) async {
    print("[CustomerService] ===== OTP LOGIN START =====");
    print("[CustomerService] Mobile: $mobileNo");

    final url = Uri.parse(
      "$baseUrl/api/method/telemko_support.api.custom_mobile_login.mobile_login",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile_no": mobileNo, "otp": otp}),
      );

      print("[CustomerService] Response Status: ${response.statusCode}");
      print("[CustomerService] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? {};

        // Debug: Print all available fields
        print("[CustomerService] Available fields in response:");
        message.forEach((key, value) {
          print("  $key: $value");
        });

        String? sid;

        // Get SID from message
        if (message["sid"] != null) {
          sid = message["sid"].toString();
          print("[CustomerService] ✅ SID from message field: $sid");
        }

        // Also check cookie header as backup
        if (sid == null || sid.isEmpty) {
          final cookies = response.headers["set-cookie"] ?? "";
          print("[CustomerService] Cookie header: $cookies");

          final match = RegExp(r"sid=([^;]+)").firstMatch(cookies);
          if (match != null) {
            sid = match.group(1);
            print("[CustomerService] ✅ SID from cookie: $sid");
          }
        }

        if (sid != null && sid.isNotEmpty && sid != "Logged In" && sid.length > 10) {
          // Extract user details with fallbacks
          String customerName = message["customer_name"]?.toString() ??
              message["full_name"]?.toString() ??
              message["user"]?.toString() ??
              "Customer ($mobileNo)";

          String mobile = message["mobile_no"]?.toString() ??
              message["mobile"]?.toString() ??
              mobileNo;

          String email = message["email_id"]?.toString() ??
              message["email"]?.toString() ??
              "$mobileNo@telemko.com";

          print("[CustomerService] 📝 Extracted user info:");
          print("  - Name: $customerName");
          print("  - Mobile: $mobile");
          print("  - Email: $email");

          // IMPORTANT: Save session to SharedPreferences
          await SessionManager.saveCustomerSession(
            customerName: customerName,
            mobileNo: mobile,
            emailId: email,
            sid: sid,
            loginType: "otp",
          );

          // Verify session was saved
          final savedSid = await SessionManager.getSid();
          if (savedSid == sid) {
            print("[CustomerService] ✅ Session saved successfully to SharedPreferences");
          } else {
            print("[CustomerService] ⚠️ Session might not be saved properly");
          }

          print("[CustomerService] ===== OTP LOGIN SUCCESS =====");
          return {
            "sid": sid,
            "customer_name": customerName,
            "mobile_no": mobile,
            "email_id": email,
            ...message,
          };
        } else {
          print("[CustomerService] ❌ Invalid SID: '$sid'");
          print("[CustomerService] ===== OTP LOGIN FAILED =====");
          return null;
        }
      } else {
        print("[CustomerService] ❌ API Error: ${response.statusCode}");
        print("[CustomerService] ===== OTP LOGIN FAILED =====");
        return null;
      }
    } catch (e) {
      print("[CustomerService] ❌ Exception: $e");
      print("[CustomerService] ===== OTP LOGIN FAILED =====");
      return null;
    }
  }
}
