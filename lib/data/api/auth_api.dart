import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class AuthApi {
  static const String baseUrl = "http://erp.telemko.com";

  /// Login using email / username / mobile
  static Future<void> login({
    required String identifier,
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

    if (response.statusCode != 200) {
      throw Exception("Login failed");
    }

    final cookie = response.headers['set-cookie'];
    if (cookie == null) {
      throw Exception("No session cookie received");
    }

    final sid = cookie
        .split(';')
        .firstWhere((e) => e.startsWith('sid='))
        .replaceFirst('sid=', '');

    final isEmail = identifier.contains('@');
    final isMobile = RegExp(r'^\d+$').hasMatch(identifier);

    await SessionManager.saveUser(
      identifier: identifier,
      email: isEmail ? identifier : null,
      mobile: isMobile ? identifier : null,
      sid: sid,
    );
  }

  static Future<void> logout() async {
    await http.get(Uri.parse("$baseUrl/api/method/logout"));
    await SessionManager.clearSession();
  }
}
