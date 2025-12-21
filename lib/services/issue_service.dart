// lib/services/issue_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/api/frappe_api.dart';
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';


class IssueService {
  /// Create a new issue
  static Future<String> createIssue({
    required String subject,
    required String description,
    required String customer,
    required String raisedBy, // email of logged-in user
    required String customVehicleNumber,
  }) async {
    final body = {
      "subject": subject,
      "description": description,
      "customer": customer,
      "raised_by": raisedBy,
      "custom_vehical_number": customVehicleNumber,
    };

    final res = await FrappeApi.post("/api/resource/Issue", body);
    return res["data"]["name"]; // e.g., ISS-0001
  }

  /// Attach an image to an existing issue
  static Future<void> attachImage({
    required String issueId,
    required File image,
  }) async {
    await FrappeApi.uploadFile(
      file: image,
      doctype: "Issue",
      docname: issueId,
    );
  }

  /// Fetch issues only for the logged-in user (by email)
  static Future<List<dynamic>> fetchMyIssues({int limit = 50}) async {
    final sid = await SessionManager.getSid();
    final email = await SessionManager.getEmail();
    if (sid == null || email == null || email.isEmpty) return [];

    final uri = Uri.parse(
        "${FrappeApi.baseUrl}/api/resource/Issue"
            "?limit_page_length=$limit"
            "&fields=[\"name\",\"subject\",\"status\",\"customer\",\"custom_vehical_number\",\"opening_date\"]"
            "&filters=[[\"raised_by\",\"=\",\"$email\"]]"
    );

    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Cookie": "sid=$sid", // use SID to authenticate
    });

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch issues: ${response.body}");
    }

    final data = json.decode(response.body);
    return data["data"] ?? [];
  }
}
