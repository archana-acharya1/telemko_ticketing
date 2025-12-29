import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const loginUrl = "http://erp.telemko.com/api/method/login";
  static const mobileLoginUrl = "http://erp.telemko.com/api/method/telemko_support.api.custom_mobile_login.mobile_login";

  static Future<Map<String, dynamic>?> login({
    required String usr,
    required String pwd,
  }) async {
    final url = Uri.parse(loginUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"usr": usr, "pwd": pwd}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> mobileLogin({
    required String mobile_no,
    required String otp,
  }) async {
    final url = Uri.parse(mobileLoginUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"mobile_no": mobile_no, "otp": otp}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
