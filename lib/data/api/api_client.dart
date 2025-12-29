import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static String? _sid;
  static const String baseUrl = "http://erp.telemko.com";

  /// Set SID for session
  static void setSid(String? sid) {
    _sid = sid;
    print("[ApiClient] SID set: $_sid");
  }

  /// Getter for SID
  static String? get sid => _sid;

  /// Prepare headers
  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers["Content-Type"] = "application/json";
    if (_sid != null) headers["Cookie"] = "sid=$_sid";
    print("[ApiClient] Headers: $headers");
    return headers;
  }

  /// POST request
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    if (_sid == null) throw Exception("Not authenticated. SID is missing.");
    print("[ApiClient] POST $path with body: $body");

    final response = await http.post(
      Uri.parse("$baseUrl$path"),
      headers: _headers(),
      body: jsonEncode(body),
    );

    print("[ApiClient] Response status: ${response.statusCode}, body: ${response.body}");
    if (response.statusCode != 200) throw Exception("POST failed: ${response.body}");
    return jsonDecode(response.body);
  }

  /// GET request
  static Future<Map<String, dynamic>> get(String path) async {
    if (_sid == null) throw Exception("Not authenticated. SID is missing.");
    print("[ApiClient] GET $path");

    final response = await http.get(
      Uri.parse("$baseUrl$path"),
      headers: _headers(json: false),
    );

    print("[ApiClient] Response status: ${response.statusCode}, body: ${response.body}");
    if (response.statusCode != 200) throw Exception("GET failed: ${response.body}");
    return jsonDecode(response.body);
  }
}
