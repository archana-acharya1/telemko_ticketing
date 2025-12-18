import 'dart:io';
import 'dart:convert';
import '../data/api/frappe_api.dart';
import 'package:http/http.dart' as http;
import 'package:telemko_support/presentation/screens/dashboard/lib/data/local/session_manager.dart';

class IssueService {
  /// Create Issue (NO attachment here)
  static Future<String> createIssue(Map<String, dynamic> data) async {
    final resp = await FrappeApi.post("/api/resource/Issue", data);
    print("Created issue response: $resp");
    return resp["data"]["name"]; // e.g., ISS-0001
  }

  //Attach image AFTER issue exists
  static Future<void> attachImage({
    required String issueId,
    required File image,
  }) async {
    await FrappeApi.uploadFile(
      file: image,
      doctype: "Issue",
      docname: issueId,
    );
    print("Attached image to issue $issueId");
  }

  //Fetch issues only for the logged-in user using SID
  static Future<List<dynamic>> fetchMyIssues({int limit = 50}) async {
    final sid = await SessionManager.getSid();
    if (sid == null || sid.isEmpty) {
      print("No SID found. User might not be logged in.");
      return [];
    }

    final uri = Uri.parse("${FrappeApi.baseUrl}/api/resource/Issue?limit_page_length=$limit&fields=[\"name\",\"subject\",\"status\",\"customer\",\"custom_vehical_number\",\"opening_date\"]");
    print("Fetching issues with SID: $sid");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Cookie": "sid=$sid", // key part: send SID
      },
    );

    print("Fetch issues status: ${response.statusCode}");
    print("Fetch issues body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch issues: ${response.body}");
    }

    final data = json.decode(response.body);
    return data["data"] ?? [];
  }

  // fetch issues by email
  static Future<List<dynamic>> fetchIssuesByEmail(String email, {int limit = 50}) async {
    List<dynamic> filters = [
      ["raised_by", "=", email],
    ];

    print("Fetching issues for email: $email");

    return await FrappeApi.getList(
      doctype: "Issue",
      fields: ["name", "subject", "status", "customer", "custom_vehical_number", "opening_date"],
      filters: filters,
      limit: limit,
    );
  }

  // fetch issues by mobile
  static Future<List<dynamic>> fetchIssuesByMobile(String mobile, {int limit = 50}) async {
    List<dynamic> filters = [
      ["custom_mobile_number", "=", mobile],
    ];

    print("Fetching issues for mobile: $mobile");

    return await FrappeApi.getList(
      doctype: "Issue",
      fields: ["name", "subject", "status", "customer", "custom_vehical_number", "opening_date"],
      filters: filters,
      limit: limit,
    );
  }
}
