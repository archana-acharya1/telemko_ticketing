import 'dart:convert';
import 'dart:io';
import '../data/api/frappe_api.dart';
import 'package:http/http.dart' as http;

class IssueService {
  /// Create Issue
  static Future<String> createIssue(Map<String, dynamic> data) async {
    final resp = await FrappeApi.post("/api/resource/Issue", data);
    return resp["data"]["name"];
  }

  /// Attach image
  static Future<void> attachImage({required String issueId, required File image}) async {
    await FrappeApi.uploadFile(file: image, doctype: "Issue", docname: issueId);
  }

  /// Fetch issues by email
  static Future<List<dynamic>> fetchIssuesByEmail(String email, {int limit = 50}) async {
    final filters = [
      ["raised_by", "=", email],
    ];
    return await FrappeApi.getList(
      doctype: "Issue",
      fields: ["name", "subject", "status", "customer", "custom_vehical_number", "opening_date"],
      filters: filters,
      limit: limit,
    );
  }

  /// Fetch issues by mobile
  static Future<List<dynamic>> fetchIssuesByMobile(String mobile, {int limit = 50}) async {
    final filters = [
      ["custom_vehical_number", "=", mobile],
    ];
    return await FrappeApi.getList(
      doctype: "Issue",
      fields: ["name", "subject", "status", "customer", "custom_vehical_number", "opening_date"],
      filters: filters,
      limit: limit,
    );
  }
}
