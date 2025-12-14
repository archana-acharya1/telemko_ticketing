import 'dart:io';
import '../data/api/frappe_api.dart';

class IssueService {
  /// Create a new Issue (ticket)
  static Future<Map<String, dynamic>> createIssue(
      Map<String, dynamic> data) async {
    final resp = await FrappeApi.post("/api/resource/Issue", data);
    return resp;
  }

  /// Upload an image and get URL (used before creating Issue)
  static Future<String> uploadImageAndGetUrl(File file) async {
    return await FrappeApi.uploadFileAndGetUrl(file, doctype: 'Issue');
  }

  /// Fetch list of issues (optional filters: mobile or email)
  static Future<List<dynamic>> fetchIssues({
    String? mobile,
    String? raisedByEmail,
    int limit = 50,
  }) async {
    List<dynamic> filters = [];
    if (mobile != null) filters.add(["custom_mobile_number", "=", mobile]);
    if (raisedByEmail != null) filters.add(["raised_by", "=", raisedByEmail]);

    return await FrappeApi.getList(
      doctype: "Issue",
      fields: [
        "name",
        "subject",
        "status",
        "customer",
        "custom_mobile_number",
        "custom_vehical_number",
        "opening_date"
      ],
      filters: filters.isEmpty ? null : filters,
      limit: limit,
    );
  }

  /// Get a single Issue details by name
  static Future<Map<String, dynamic>> getIssue(String issueName) async {
    final resp = await FrappeApi.get("/api/resource/Issue/$issueName");
    return resp["data"] ?? {};
  }
}
