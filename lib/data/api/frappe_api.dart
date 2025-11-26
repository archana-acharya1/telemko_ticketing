// lib/core/data/api/frappe_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FrappeApi {
  static const String baseUrl = "http://simtrack.deskgoo.com";
  static const String apiToken = "2259d1e51dadce0:e4b7dfc664256d8";

  static Map<String, String> get headers => {
    "Authorization": "token $apiToken",
    "Content-Type": "application/json",
  };

  /// GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse("$baseUrl$endpoint");
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("GET request failed: ${res.body}");
  }

  /// POST request
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse("$baseUrl$endpoint");
    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("POST request failed: ${res.body}");
  }

  /// Frappe client.get_list
  static Future<List<dynamic>> getList({
    required String doctype,
    List<String>? fields,
    List<dynamic>? filters,
    int limit = 50,
  }) async {
    final uri = Uri.parse("$baseUrl/api/method/frappe.client.get_list");
    final body = {
      "doctype": doctype,
      "fields": fields ?? ["*"],
      if (filters != null) "filters": filters,
      "limit": limit,
    };
    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode == 200) return jsonDecode(res.body)["message"];
    throw Exception("getList failed: ${res.body}");
  }

  /// Upload a file to a ticket or doctype
  static Future<void> uploadFile(File file,
      {required String doctype, required String docname}) async {
    final uri = Uri.parse("$baseUrl/api/method/upload_file");

    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'token $apiToken';

    request.fields['doctype'] = doctype;
    request.fields['docname'] = docname;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: path.basename(file.path),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception("File upload failed: ${response.body}");
    }
  }
}
