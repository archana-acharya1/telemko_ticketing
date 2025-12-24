import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsApi {
  static const String baseUrl = "http://erp.telemko.com";
  static String? sessionCookie;

  static Future<void> sendOtp({required String mobile}) async {
    print("[SmsApi] Sending OTP to $mobile...");
    final url = Uri.parse("$baseUrl/api/method/telemko_support.api.send_otp.send_otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile_no": mobile}),
    );

    print("[SmsApi] Status: ${response.statusCode}");
    print("[SmsApi] Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to send OTP");
    }

    final rawCookie = response.headers['set-cookie'];
    if (rawCookie == null) {
      throw Exception("No session cookie returned");
    }

    sessionCookie = rawCookie;
    print("[SmsApi] Session cookie saved: $sessionCookie");
  }
}
