import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsApi {
  static const baseUrl = "http://erp.telemko.com";

  static Future<bool> sendOtp({required String mobileNo}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/method/telemko_support.api.send_otp.send_otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile_no": mobileNo}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> verifyOtp({
    required String mobileNo,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse(
          "$baseUrl/api/method/telemko_support.api.custom_mobile_login.mobile_login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile_no": mobileNo, "otp": otp}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["message"];
    }
    return null;
  }
}
