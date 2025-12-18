import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class AuthApi {
  static const String baseUrl = "http://erp.telemko.com";

  /// Login using email, username, or mobile
  static Future<Map<String, dynamic>> login({
    required String identifier, // email / username / mobile
    required String password,
  }) async {
    final uri = Uri.parse("$baseUrl/api/method/login");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
      },
      body: {
        "usr": identifier,
        "pwd": password,
      },
    );

    print("Login response status: ${response.statusCode}");
    print("Login response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Login failed: ${response.body}");
    }

    // Extract SID from cookies
    final sid = response.headers['set-cookie']
        ?.split(';')
        .firstWhere((c) => c.startsWith('sid='), orElse: () => '')
        .replaceFirst('sid=', '');

    print("Extracted SID: $sid");

    if (sid == null || sid.isEmpty) {
      throw Exception("Failed to get session ID");
    }

    // Save session
    await SessionManager.saveUser(
      email: identifier,
      mobile: identifier,
      sid: sid,
    );

    // Return user data
    return {
      "email": identifier,
      "mobile": identifier,
      "sid": sid,
    };
  }

  /// Logout
  static Future<void> logout() async {
    final uri = Uri.parse("$baseUrl/api/method/logout");
    await http.get(uri);
    await SessionManager.clearSession();
  }

  /// Get SID
  static Future<String?> getSid() async {
    return await SessionManager.getSid();
  }
}
