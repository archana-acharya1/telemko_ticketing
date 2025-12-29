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
    if (_sid != null && _sid!.isNotEmpty) {
      headers["Cookie"] = "sid=$_sid";
    }
    return headers;
  }

  /// POST request
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    if (_sid == null || _sid!.isEmpty) {
      print("[ApiClient] ERROR: SID is null or empty. Cannot make POST request to $path");
      throw Exception("Not authenticated. SID is missing. Please login again.");
    }
    
    final headers = _headers();
    print("[ApiClient] POST $path with body: $body");
    print("[ApiClient] Using SID: $_sid");
    print("[ApiClient] Request headers: $headers");

    final response = await http.post(
      Uri.parse("$baseUrl$path"),
      headers: headers,
      body: jsonEncode(body),
    );

    print("[ApiClient] Response status: ${response.statusCode}");
    print("[ApiClient] Response headers: ${response.headers}");
    print("[ApiClient] Response body: ${response.body}");
    
    if (response.statusCode != 200) {
      print("[ApiClient] POST request failed with status ${response.statusCode}");
      throw Exception("POST failed (${response.statusCode}): ${response.body}");
    }
    
    return jsonDecode(response.body);
  }

  /// GET request
  static Future<Map<String, dynamic>> get(String path) async {
    if (_sid == null || _sid!.isEmpty) {
      print("[ApiClient] ERROR: SID is null or empty. Cannot make GET request to $path");
      throw Exception("Not authenticated. SID is missing. Please login again.");
    }
    
    final headers = _headers(json: false);
    print("[ApiClient] GET $path");
    print("[ApiClient] Using SID: $_sid");
    print("[ApiClient] Request headers: $headers");

    final response = await http.get(
      Uri.parse("$baseUrl$path"),
      headers: headers,
    );

    print("[ApiClient] Response status: ${response.statusCode}");
    print("[ApiClient] Response headers: ${response.headers}");
    print("[ApiClient] Response body: ${response.body}");
    
    if (response.statusCode != 200) {
      print("[ApiClient] GET request failed with status ${response.statusCode}");
      throw Exception("GET failed (${response.statusCode}): ${response.body}");
    }
    
    return jsonDecode(response.body);
  }
}
