import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';


class AuthService {
  static const otpLoginUrl = "http://erp.telemko.com/api/method/telemko_support.api.custom_mobile_login.mobile_login";
  static const sendOtpUrl = "http://erp.telemko.com/api/method/telemko_support.api.send_otp.send_otp";
  static const passwordLoginUrl = "http://erp.telemko.com/api/method/login";

  static Future<bool> sendOtp(String mobile) async {
    final res = await http.post(Uri.parse(sendOtpUrl), body: {"mobile": mobile});
    print("[AuthService] sendOtp response: ${res.statusCode}, body: ${res.body}");
    return res.statusCode == 200;
  }

  static Future<bool> loginWithOtp(String mobile, String otp) async {
    final res = await http.post(Uri.parse(otpLoginUrl), body: {"identifier": mobile, "otp": otp});
    print("[AuthService] loginWithOtp response: ${res.statusCode}, body: ${res.body}");
    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body)["message"];
    if (data == null || data["sid"] == null) {
      print("[AuthService] loginWithOtp failed: SID missing");
      return false;
    }

    await SessionManager.saveCustomerSession(
      customerName: data["customer_name"] ?? "",
      mobileNo: data["mobile_no"] ?? "",
      emailId: data["email_id"] ?? "",
      sid: data["sid"],
      loginType: "otp",
    );
    print("[AuthService] loginWithOtp successful: SID=${data['sid']}");
    return true;
  }

  static Future<bool> loginWithPassword(String username, String password) async {
    final res = await http.post(
      Uri.parse(passwordLoginUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usr": username, "pwd": password}),
    );

    print("[AuthService] loginWithPassword response: ${res.statusCode}, body: ${res.body}");
    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body)["message"];
    if (data == null || data["sid"] == null) {
      print("[AuthService] loginWithPassword failed: SID missing");
      return false;
    }

    await SessionManager.saveCustomerSession(
      customerName: data["customer_name"] ?? "",
      mobileNo: data["mobile_no"] ?? "",
      emailId: data["email_id"] ?? "",
      sid: data["sid"],
      loginType: "password",
    );
    print("[AuthService] loginWithPassword successful: SID=${data['sid']}");
    return true;
  }
}
