import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sms_api.dart';

class AuthApi {
  static const String baseUrl = "http://erp.telemko.com";

  static Future<void> login({
    required String identifier,
    required String password,
  }) async {
    print("[AuthApi] Starting login for: $identifier");
    final response = await http.post(
      Uri.parse("$baseUrl/api/method/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"usr": identifier, "pwd": password},
    );

    print("[AuthApi] Response status: ${response.statusCode}");
    print("[AuthApi] Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Login failed");
    }
  }

  static Future<void> mobileLogin({
    required String mobile,
    required String otp,
  }) async {
    print("[AuthApi] OTP login for $mobile");
    if (SmsApi.sessionCookie == null) {
      print("[AuthApi] OTP session missing!");
      throw Exception("OTP session missing");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/api/method/telemko_support.api.custom_mobile_login.mobile_login"),
      headers: {
        "Content-Type": "application/json",
        "Cookie": SmsApi.sessionCookie!,
      },
      body: jsonEncode({"mobile_no": mobile, "otp": otp}),
    );

    print("[AuthApi] Status: ${response.statusCode}");
    print("[AuthApi] Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Mobile login failed");
    }

    print("[AuthApi] Mobile login successful for $mobile");
  }
}
