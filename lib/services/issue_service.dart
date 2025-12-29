import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class IssueService {
  static const String baseUrl = "http://erp.telemko.com/api/resource/Issue";

  // Fetch all tickets for logged-in user
  static Future<List<dynamic>> fetchIssues() async {
    final session = await SessionManager.getCustomerSession();
    if (session == null || session["sid"] == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=${session["sid"]}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to fetch tickets: ${response.statusCode}");
      }
    } catch (e) {
      print("[IssueService] Error fetching issues: $e");
      return [];
    }
  }

  // Create new ticket
  static Future<String?> createIssue(Map<String, dynamic> ticketData) async {
    final session = await SessionManager.getCustomerSession();
    if (session == null || session["sid"] == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=${session["sid"]}",
        },
        body: jsonEncode(ticketData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["data"]["name"];
      }
      return null;
    } catch (e) {
      print("[IssueService] Error creating issue: $e");
      return null;
    }
  }

  // Attach image to ticket
  static Future<bool> attachImage({
    required String issueId,
    required File image,
  }) async {
    final session = await SessionManager.getCustomerSession();
    if (session == null || session["sid"] == null) {
      throw Exception("User not logged in");
    }

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/$issueId/attach"),
      );
      request.files.add(await http.MultipartFile.fromPath("file", image.path));
      request.headers["Cookie"] = "sid=${session["sid"]}";

      final res = await request.send();
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("[IssueService] Error attaching image: $e");
      return false;
    }
  }
}
