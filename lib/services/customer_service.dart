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

  /// Login with OTP
  static Future<Map<String, dynamic>?> loginWithOtp(
    String mobileNo,
    String otp,
  ) async {
    print("[CustomerService] Attempting OTP login for mobile: $mobileNo");
    
    final url = Uri.parse(
      "$baseUrl/api/method/telemko_support.api.custom_mobile_login.mobile_login",
    );
    print("[CustomerService] OTP Login URL: $url");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile_no": mobileNo, "otp": otp}),
    );

    print("[CustomerService] OTP login response status: ${response.statusCode}");
    print("[CustomerService] OTP login response headers: ${response.headers}");
    print("[CustomerService] OTP login response body: ${response.body}");

    if (response.statusCode == 200) {
      String? sid;
      
      try {
        final data = jsonDecode(response.body);
        final message = data["message"];
        
        // Try to get SID from response body first (custom endpoint might return it here)
        if (message is Map<String, dynamic> && message["sid"] != null) {
          sid = message["sid"] as String;
          print("[CustomerService] SID found in response body: $sid");
        }
      } catch (e) {
        print("[CustomerService] Error parsing OTP response body: $e");
      }

      // If SID not in body, try to extract from Set-Cookie header
      if (sid == null || sid.isEmpty) {
        final setCookie = response.headers["set-cookie"] ?? response.headers["Set-Cookie"];
        print("[CustomerService] Set-Cookie header: $setCookie");
        
        if (setCookie != null && setCookie.isNotEmpty) {
          final cookieStrings = setCookie.split(',');
          for (final cookieStr in cookieStrings) {
            final trimmed = cookieStr.trim();
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
      }

      if (sid != null && sid.isNotEmpty && sid != "Logged In") {
        // Parse response body to get user details
        Map<String, dynamic> userDetails = {};
        try {
          final data = jsonDecode(response.body);
          final message = data["message"];
          if (message is Map<String, dynamic>) {
            userDetails = message;
          }
        } catch (e) {
          print("[CustomerService] Error parsing user details: $e");
        }
        
        // Save session
        await SessionManager.saveCustomerSession(
          customerName: userDetails["customer_name"] ?? userDetails["full_name"] ?? "",
          mobileNo: userDetails["mobile_no"] ?? userDetails["mobile"] ?? mobileNo,
          emailId: userDetails["email_id"] ?? userDetails["email"] ?? "",
          sid: sid,
          loginType: "otp",
        );
        
        print("[CustomerService] OTP login successful. SID: $sid");
        return userDetails.isNotEmpty ? userDetails : {"sid": sid};
      } else {
        print("[CustomerService] OTP login failed: No valid SID found in response. SID value: $sid");
      }
    } else {
      print("[CustomerService] OTP login failed with status: ${response.statusCode}");
      print("[CustomerService] Response body: ${response.body}");
    }
    
    return null;
  }
}
