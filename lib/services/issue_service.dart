import 'dart:io';
import '../data/api/frappe_api.dart';

class IssueService {
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

  static Future<Map<String, dynamic>> createIssue(
      Map<String, dynamic> data) async {
    final resp = await FrappeApi.post("/api/resource/Issue", data);
    return resp;
  }

  static Future<Map<String, dynamic>> getIssue(String issueName) async {
    final resp = await FrappeApi.get("/api/resource/Issue/$issueName");
    return resp["data"] ?? {};
  }

  static Future<void> uploadAttachment(String ticketId, File file) async {
    await FrappeApi.uploadFile(file, doctype: "Issue", docname: ticketId);
  }
}
