import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class LoginService {
  static const String baseUrl = "http://erp.telemko.com";

  static Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            "$baseUrl/api/method/telemko_support.api.custom_mobile_login.mobile_login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": identifier,
          "pwd": password,
        }),
      );

      if (response.statusCode != 200) return false;

      final res = jsonDecode(response.body);

      final message = res["message"];
      if (message != null && message["sid"] != null) {
        // Save session for later use
        await SessionManager.saveCustomerSession(
          customerName: message["customer_name"] ?? "",
          mobileNo: message["mobile_no"] ?? "",
          emailId: message["email_id"] ?? "",
          sid: message["sid"] ?? "",
          loginType: "normal",
        );
        return true;
      }

      return false;
    } catch (e) {
      print("[LoginService] login error: $e");
      return false;
    }
  }
}
