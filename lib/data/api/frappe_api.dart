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

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse("$baseUrl$endpoint");
    final res =
    await http.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("POST request failed: ${res.body}");
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse("$baseUrl$endpoint");
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("GET request failed: ${res.body}");
  }

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
    final res =
    await http.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode == 200) return jsonDecode(res.body)["message"];
    throw Exception("getList failed: ${res.body}");
  }

  /// Upload a file and return its URL
  static Future<String> uploadFileAndGetUrl(File file,
      {required String doctype, bool isPrivate = false}) async {
    final uri = Uri.parse("$baseUrl/api/method/upload_file");
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'token $apiToken';

    request.fields['attached_to_doctype'] = doctype;
    request.fields['attached_to_name'] = '';
    request.fields['is_private'] = isPrivate ? '1' : '0';

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final split = mimeType.split('/');

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: path.basename(file.path),
      contentType: MediaType(split[0], split[1]),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception("File upload failed: ${response.body}");
    }

    final body = jsonDecode(response.body);
    return body["message"]["file_url"];
  }
}
