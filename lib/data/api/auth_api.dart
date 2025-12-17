import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String baseUrl = "http://erp.telemko.com";

  /// USER LOGIN (email OR username)
  static Future<Map<String, dynamic>> login({
    required String usr,
    required String pwd,
  }) async {
    final uri = Uri.parse("$baseUrl/api/method/login");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
      },
      body: {
        "usr": usr,
        "pwd": pwd,
      },
    );

    if (response.statusCode == 401) {
      throw Exception("Wrong username or password");
    }

    if (response.statusCode != 200) {
      throw Exception("Login failed");
    }

    final body = jsonDecode(response.body);

    // Extract sid cookie
    final rawCookie = response.headers['set-cookie'];
    String? sid;

    if (rawCookie != null) {
      for (final part in rawCookie.split(';')) {
        if (part.trim().startsWith('sid=')) {
          sid = part.trim();
          break;
        }
      }
    }

    return {
      "success": true,
      "full_name": body["full_name"],
      "home_page": body["home_page"],
      "sid": sid,
    };
  }
}
