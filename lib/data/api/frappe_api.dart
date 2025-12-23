import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class FrappeApi {
  static const String baseUrl = "http://erp.telemko.com";
  static const String apiToken = "2259d1e51dadce0:e4b7dfc664256d8";

  static Map<String, String> get headers => {
    "Authorization": "token $apiToken",
    "Content-Type": "application/json",
  };

  // POST request
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    print("[FrappeApi] POST request to $endpoint with body: $body");
    final uri = Uri.parse("$baseUrl$endpoint");

    try {
      final res = await http.post(uri, headers: headers, body: jsonEncode(body));
      print("[FrappeApi] Response status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        print("[FrappeApi] Response body: $decoded");
        return decoded;
      }

      print("[FrappeApi] POST failed: ${res.body}");
      throw Exception("POST failed: ${res.body}");
    } catch (e) {
      print("[FrappeApi] Error during POST request: $e");
      rethrow;
    }
  }

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    print("[FrappeApi] GET request to $endpoint");
    final uri = Uri.parse("$baseUrl$endpoint");

    try {
      final res = await http.get(uri, headers: headers);
      print("[FrappeApi] Response status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        print("[FrappeApi] Response body: $decoded");
        return decoded;
      }

      print("[FrappeApi] GET failed: ${res.body}");
      throw Exception("GET failed: ${res.body}");
    } catch (e) {
      print("[FrappeApi] Error during GET request: $e");
      rethrow;
    }
  }

  // Get list of documents
  static Future<List<dynamic>> getList({
    required String doctype,
    List<String>? fields,
    List<dynamic>? filters,
    int limit = 50,
  }) async {
    print("[FrappeApi] getList called for doctype: $doctype, filters: $filters");
    final uri = Uri.parse("$baseUrl/api/method/frappe.client.get_list");

    final body = {
      "doctype": doctype,
      "fields": fields ?? ["*"],
      if (filters != null) "filters": filters,
      "limit": limit,
    };

    try {
      final res = await http.post(uri, headers: headers, body: jsonEncode(body));
      print("[FrappeApi] Response status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final message = jsonDecode(res.body)["message"];
        print("[FrappeApi] getList response: $message");
        return message;
      }

      print("[FrappeApi] getList failed: ${res.body}");
      throw Exception("getList failed: ${res.body}");
    } catch (e) {
      print("[FrappeApi] Error during getList: $e");
      rethrow;
    }
  }

  // Upload file
  static Future<String> uploadFile({
    required File file,
    required String doctype,
    required String docname,
    bool isPrivate = false,
  }) async {
    print("[FrappeApi] Uploading file ${file.path} to $doctype/$docname");

    final uri = Uri.parse("$baseUrl/api/method/upload_file");
    final request = http.MultipartRequest("POST", uri);
    request.headers['Authorization'] = 'token $apiToken';

    request.fields['attached_to_doctype'] = doctype;
    request.fields['attached_to_name'] = docname;
    request.fields['is_private'] = isPrivate ? '1' : '0';

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final parts = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
        contentType: MediaType(parts[0], parts[1]),
      ),
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      print("[FrappeApi] Upload response status: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("[FrappeApi] Upload failed: ${response.body}");
        throw Exception("Upload failed: ${response.body}");
      }

      final body = jsonDecode(response.body);
      final fileUrl = body["message"]["file_url"];
      print("[FrappeApi] File uploaded successfully: $fileUrl");

      return fileUrl;
    } catch (e) {
      print("[FrappeApi] Error during file upload: $e");
      rethrow;
    }
  }
}
