import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class IssueService {
  static const String baseUrl = "https://erp.telemko.com";

  /// Fetch issues for the logged-in user.
  ///
  /// Identity rule (important): tickets are matched by `raised_by` (the
  /// email of the account that created them) and `custom_mobile_number`.
  /// We NEVER filter by `customer` because that's a free-text display name
  /// — many users can share it (e.g. "Test") and it would leak tickets.
  static Future<List<dynamic>> fetchMyIssues() async {
    try {
      print("[IssueService] Fetching issues for logged-in user");

      final session = await SessionManager.getCustomerSession();
      if (session == null || session["sid"] == null) {
        print("[IssueService] Error: No active session found");
        throw Exception("Not authenticated. Please login again.");
      }

      final sid = session["sid"] as String;
      final mobileNumber = (session["mobile_no"] ?? "").toString();
      final email = (session["email_id"] ?? session["email"] ?? "").toString();

      print("[IssueService] User session - Mobile: $mobileNumber, Email: $email");

      // Method 1: frappe.client.get_list with full fields (preferred)
      try {
        final issues = await _fetchUsingGetList(sid, mobileNumber, email);
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] get_list failed: $e");
      }

      // Method 2: direct /api/resource/Issue with expanded fields
      try {
        final issues = await _fetchUsingResourceAPI(sid, mobileNumber, email);
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] resource API failed: $e");
      }

      // Method 3: minimal fields fallback (for 417 field-permission cases)
      try {
        final issues = await _fetchWithMinimalFields(sid, mobileNumber, email);
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] fallback failed: $e");
      }

      return [];
    } catch (e) {
      print("[IssueService] Error fetching issues: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // METHOD 1 — frappe.client.get_list
  // ─────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> _fetchUsingGetList(
      String sid, String mobileNumber, String email) async {
    try {
      print("[IssueService] Using get_list API with expanded fields");

      final Map<String, dynamic> body = {
        "doctype": "Issue",
        "fields": [
          "name", "subject", "status", "priority", "description",
          "creation", "modified", "raised_by",
          "customer", "customer_name",
          "custom_mobile_number",
          "custom_vehical_number",
          "issue_type", "resolution_details",
        ],
        "limit_page_length": 100,
        "order_by": "creation desc",
      };

      // Only filters tied to a unique identity: raised_by (email) or
      // the mobile stored on the Issue itself. Never `customer`.
      final List<List<dynamic>> filters = [];

      if (email.isNotEmpty && email.contains("@")) {
        filters.add(["raised_by", "=", email]);
      }

      if (mobileNumber.isNotEmpty) {
        // Some flows create the login email as <mobile>@telemko.com
        filters.add(["raised_by", "=", "${mobileNumber}@telemko.com"]);
        filters.add(["custom_mobile_number", "=", mobileNumber]);
      }

      if (filters.isNotEmpty) {
        // Match ANY of the identity filters
        body["or_filters"] = filters;
      } else {
        print("[IssueService] No identity available — returning empty");
        return [];
      }

      print("[IssueService] get_list request with filters: $filters");

      final response = await http.post(
        Uri.parse("$baseUrl/api/method/frappe.client.get_list"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
        body: jsonEncode(body),
      );

      print("[IssueService] get_list response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> issues = (data["message"] as List?) ?? [];

        issues.sort((a, b) {
          final dateA = (a["creation"] ?? "").toString();
          final dateB = (b["creation"] ?? "").toString();
          return dateB.compareTo(dateA);
        });

        print("[IssueService] get_list fetched ${issues.length} issues");

        if (issues.isNotEmpty) {
          _logFirstTicketFields(issues[0] as Map<String, dynamic>);
        }

        return issues;
      }

      print("[IssueService] get_list failed: ${response.statusCode}");
      return [];
    } catch (e) {
      print("[IssueService] Error in get_list: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // METHOD 2 — /api/resource/Issue with expanded fields
  // ─────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> _fetchUsingResourceAPI(
      String sid, String mobileNumber, String email) async {
    try {
      print("[IssueService] Using direct resource API with expanded fields");

      // NOTE: real field name on the doctype is `custom_mobile_number`
      final List<String> fields = [
        "name", "subject", "status", "priority", "description",
        "creation", "modified", "raised_by",
        "customer", "customer_name",
        "custom_mobile_number",
        "custom_vehical_number",
        "issue_type", "resolution_details",
      ];

      final String url = "$baseUrl/api/resource/Issue";
      final Map<String, String> params = {
        "fields": jsonEncode(fields),
        "order_by": "creation desc",
        "limit_page_length": "100",
      };

      final List<List<dynamic>> filters = [];

      if (email.isNotEmpty && email.contains("@")) {
        filters.add(["raised_by", "=", email]);
      }

      if (mobileNumber.isNotEmpty) {
        filters.add(["raised_by", "=", "${mobileNumber}@telemko.com"]);
        filters.add(["custom_mobile_number", "=", mobileNumber]);
      }

      if (filters.isEmpty) {
        print("[IssueService] No identity available — returning empty");
        return [];
      }

      params["filters"] = jsonEncode(filters);

      final uri = Uri.parse(url).replace(queryParameters: params);
      print("[IssueService] Resource API URL: ${uri.toString()}");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      print("[IssueService] Resource API response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> issues = (data["data"] as List?) ?? [];

        issues.sort((a, b) {
          final dateA = (a["creation"] ?? "").toString();
          final dateB = (b["creation"] ?? "").toString();
          return dateB.compareTo(dateA);
        });

        print("[IssueService] Resource API fetched ${issues.length} issues");

        if (issues.isNotEmpty) {
          _logFirstTicketFields(issues[0] as Map<String, dynamic>);
        }

        return issues;
      }

      print("[IssueService] Resource API failed: ${response.statusCode}");

      // If Frappe rejects one of our fields, drop to minimal set
      if (response.statusCode == 417) {
        return await _fetchWithMinimalFields(sid, mobileNumber, email);
      }

      return [];
    } catch (e) {
      print("[IssueService] Error in resource API: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // METHOD 3 — minimal fields, tried per-identity until one matches
  // ─────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> _fetchWithMinimalFields(
      String sid, String mobileNumber, String email) async {
    try {
      print("[IssueService] Trying with fallback fields");

      final List<String> fields = [
        "name", "subject", "status", "creation",
        "customer", "raised_by", "description",
        "custom_vehical_number",
      ];

      final String url = "$baseUrl/api/resource/Issue";
      final Map<String, String> params = {
        "fields": jsonEncode(fields),
        "order_by": "creation desc",
        "limit_page_length": "100",
      };

      // Ordered, most-specific first.
      final List<String> filterOptions = [];

      if (email.isNotEmpty && email.contains("@")) {
        filterOptions.add('[[\"raised_by\", \"=\", \"$email\"]]');
      }

      if (mobileNumber.isNotEmpty) {
        filterOptions.add('[[\"raised_by\", \"=\", \"${mobileNumber}@telemko.com\"]]');
        filterOptions.add('[[\"custom_mobile_number\", \"=\", \"$mobileNumber\"]]');
      }

      if (filterOptions.isEmpty) {
        print("[IssueService] No unique filter available — returning empty");
        return [];
      }

      for (final filter in filterOptions) {
        try {
          final tempParams = Map<String, String>.from(params);
          tempParams["filters"] = filter;

          final uri = Uri.parse(url).replace(queryParameters: tempParams);
          print("[IssueService] Trying filter: $filter");

          final response = await http.get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Cookie": "sid=$sid",
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List<dynamic> issues = (data["data"] as List?) ?? [];
            if (issues.isNotEmpty) {
              print("[IssueService] Found ${issues.length} issues with filter: $filter");
              return issues;
            }
          }
        } catch (e) {
          print("[IssueService] Filter $filter failed: $e");
        }
      }

      print("[IssueService] No tickets found for user");
      return [];
    } catch (e) {
      print("[IssueService] Error in fallback: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // TEST METHOD — fetch one ticket by ID
  // ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchTicketById(String ticketId) async {
    try {
      final session = await SessionManager.getCustomerSession();
      if (session == null || session["sid"] == null) return null;

      final sid = session["sid"];
      final response = await http.get(
        Uri.parse("$baseUrl/api/resource/Issue/$ticketId"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"];
      }
      return null;
    } catch (e) {
      print("[IssueService] Error fetching ticket by ID: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Debug helper
  // ─────────────────────────────────────────────────────────────────────
  static void _logFirstTicketFields(Map<String, dynamic> firstTicket) {
    print("[IssueService] First ticket fields:");

    if (firstTicket["description"] != null) {
      final desc = firstTicket["description"].toString();
      print("  ✓ description: ${desc.length} chars");
      if (desc.contains("<img")) {
        print("  ✓ Contains images in HTML");
      }
    }

    const customFields = ["custom_mobile_number", "custom_vehical_number"];
    for (final field in customFields) {
      if (firstTicket.containsKey(field)) {
        print("  ✓ $field: ${firstTicket[field]}");
      } else {
        print("  ✗ $field: NOT FOUND");
      }
    }
  }
}