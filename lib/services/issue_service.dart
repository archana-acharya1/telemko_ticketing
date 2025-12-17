import 'dart:io';
import '../data/api/frappe_api.dart';

class IssueService {
  /// Create Issue (NO attachment here)
  static Future<String> createIssue(Map<String, dynamic> data) async {
    final resp =
    await FrappeApi.post("/api/resource/Issue", data);
    return resp["data"]["name"]; // ISS-0001
  }

  /// Attach image AFTER issue exists
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

  static Future<List<dynamic>> fetchIssues({
    String? mobile,
    String? raisedByEmail,
    int limit = 50,
  }) async {
    List<dynamic> filters = [];
    if (mobile != null) {
      filters.add(["custom_mobile_number", "=", mobile]);
    }
    if (raisedByEmail != null) {
      filters.add(["raised_by", "=", raisedByEmail]);
    }

    return await FrappeApi.getList(
      doctype: "Issue",
      fields: [
        "name",
        "subject",
        "status",
        "customer",
        "opening_date"
      ],
      filters: filters.isEmpty ? null : filters,
      limit: limit,
    );
  }
}
