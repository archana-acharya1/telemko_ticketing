import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class AuthApi {
  static const String baseUrl = "http://erp.telemko.com";

  //Login using email / username / mobile
  static Future<void> login({
    required String identifier,
    required String password,
  }) async {
    print("[AuthApi] Login attempt started for identifier: $identifier");

    final uri = Uri.parse("$baseUrl/api/method/login");

    try {
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

      print("[AuthApi] HTTP POST response status: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("[AuthApi] Login failed with status code: ${response.statusCode}");
        throw Exception("Login failed");
      }

      final cookie = response.headers['set-cookie'];
      if (cookie == null) {
        print("[AuthApi] No session cookie received");
        throw Exception("No session cookie received");
      }

      final sid = cookie
          .split(';')
          .firstWhere((e) => e.startsWith('sid='))
          .replaceFirst('sid=', '');

      print("[AuthApi] Session ID (sid) received: $sid");

      final isEmail = identifier.contains('@');
      final isMobile = RegExp(r'^\d+$').hasMatch(identifier);

      print("[AuthApi] Identifier type - isEmail: $isEmail, isMobile: $isMobile");

      await SessionManager.saveUser(
        identifier: identifier,
        email: isEmail ? identifier : null,
        mobile: isMobile ? identifier : null,
        sid: sid,
      );

      print("[AuthApi] User session saved successfully for identifier: $identifier");

    } catch (e) {
      print("[AuthApi] Error during login: $e");
      rethrow;
    }
  }

  //Logout
  static Future<void> logout() async {
    print("[AuthApi] Logout started");

    try {
      final response = await http.get(Uri.parse("$baseUrl/api/method/logout"));
      print("[AuthApi] Logout HTTP GET status: ${response.statusCode}");

      await SessionManager.clearSession();
      print("[AuthApi] Session cleared successfully");
    } catch (e) {
      print("[AuthApi] Error during logout: $e");
      rethrow;
    }
  }
}
