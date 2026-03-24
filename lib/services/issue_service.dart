import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/dashboard/lib/data/local/session_manager.dart';

class IssueService {
  static const String baseUrl = "http://erp.telemko.com";

  /// Fetch issues for logged-in user with ALL customer details
  static Future<List<dynamic>> fetchMyIssues() async {
    try {
      print("[IssueService] Fetching issues for logged-in user");

      // Get session
      final session = await SessionManager.getCustomerSession();
      if (session == null || session["sid"] == null) {
        print("[IssueService] Error: No active session found");
        throw Exception("Not authenticated. Please login again.");
      }

      final sid = session["sid"];
      final customerName = session["customer_name"] ?? "";
      final mobileNumber = session["mobile_no"] ?? "";
      final email = session["email_id"] ?? session["email"] ?? "";

      print("[IssueService] User session - Name: $customerName, Mobile: $mobileNumber, Email: $email");

      // Try multiple methods in sequence
      List<dynamic> issues = [];

      // METHOD 1: Try get_list with expanded fields
      try {
        issues = await _fetchUsingGetList(sid, customerName, mobileNumber, email);
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] get_list failed: $e");
      }

      // METHOD 2: Try direct resource API
      try {
        issues = await _fetchUsingResourceAPI(sid, customerName, mobileNumber, email);
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] resource API failed: $e");
      }

      // METHOD 3: Try fallback with minimal fields
      try {
        issues = await _fetchWithMinimalFields(sid, customerName, mobileNumber, email);
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] fallback failed: $e");
      }

      // If all methods fail, return empty
      return [];
    } catch (e) {
      print("[IssueService] Error fetching issues: $e");
      rethrow;
    }
  }

  /// METHOD 1: Use frappe.client.get_list API with ALL fields
  static Future<List<dynamic>> _fetchUsingGetList(String sid, String customerName, String mobileNumber, String email) async {
    try {
      print("[IssueService] Using get_list API with expanded fields");

      // Build request body with ALL fields you need - KEEPING description for images
      final Map<String, dynamic> body = {
        "doctype": "Issue",
        "fields": [
          "name", "subject", "status", "priority", "description",
          "creation", "modified", "raised_by",
          "customer", "customer_name",
          "custom_mobile_number",
          "issue_type", "resolution_details"
        ],
        "limit_page_length": 100,
        "order_by": "creation desc"
      };

      // Try multiple filters to catch all tickets
      List<List<dynamic>> filters = [];

      // Add multiple possible filter combinations
      if (customerName.isNotEmpty) {
        filters.add(["customer", "=", customerName]);
        filters.add(["raised_by", "=", customerName]);
        filters.add(["customer_name", "=", customerName]);
      }

      if (mobileNumber.isNotEmpty) {
        // Try with custom_mobile_no field
        filters.add(["custom_mobile_no", "=", mobileNumber]);
      }

      if (email.isNotEmpty && email.contains("@")) {
        filters.add(["raised_by", "=", email]);
      }

      // If we have filters, use them
      if (filters.isNotEmpty) {
        // Use OR condition between different filters
        body["or_filters"] = filters;
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
        List<dynamic> issues = data["message"] ?? [];

        // Sort by creation date (newest first)
        issues.sort((a, b) {
          final dateA = a["creation"] ?? "";
          final dateB = b["creation"] ?? "";
          return dateB.compareTo(dateA);
        });

        print("[IssueService] get_list fetched ${issues.length} issues");

        // Debug: Print fields of first ticket
        if (issues.isNotEmpty) {
          print("[IssueService] First ticket fields:");
          final firstTicket = issues[0] as Map<String, dynamic>;

          // Check for description (for images)
          if (firstTicket.containsKey("description") && firstTicket["description"] != null) {
            final desc = firstTicket["description"].toString();
            print("  ✓ description: ${desc.length} chars");
            // Check if it contains images
            if (desc.contains("<img")) {
              print("  ✓ Contains images in HTML");
            }
          }

          // Check for our custom fields
          final customFields = ["custom_mobile_no", "custom_vehical_number"];
          for (final field in customFields) {
            if (firstTicket.containsKey(field)) {
              print("  ✓ $field: ${firstTicket[field]}");
            } else {
              print("  ✗ $field: NOT FOUND");
            }
          }
        }

        return issues;
      } else {
        print("[IssueService] get_list failed: ${response.statusCode}");
        // Don't throw, return empty and try next method
        return [];
      }
    } catch (e) {
      print("[IssueService] Error in get_list: $e");
      return [];
    }
  }

  /// METHOD 2: Direct resource API with expanded fields
  static Future<List<dynamic>> _fetchUsingResourceAPI(String sid, String customerName, String mobileNumber, String email) async {
    try {
      print("[IssueService] Using direct resource API with expanded fields");


      final fields = [
        "name", "subject", "status", "priority", "description",
        "creation", "modified", "raised_by",
        "customer", "customer_name",
        "custom_mobile_no",
        "custom_vehical_number",
        "issue_type", "resolution_details"
      ];

      String url = "$baseUrl/api/resource/Issue";

      // Build query parameters
      final params = {
        "fields": jsonEncode(fields),
        "order_by": "creation desc",
        "limit_page_length": "100",
      };

      // Build filters
      List<List<dynamic>> filters = [];

      if (customerName.isNotEmpty) {
        filters.add(["customer", "=", customerName]);
        filters.add(["raised_by", "=", customerName]);
      }

      if (mobileNumber.isNotEmpty) {
        filters.add(["custom_mobile_no", "=", mobileNumber]);
      }

      if (email.isNotEmpty && email.contains("@")) {
        filters.add(["raised_by", "=", email]);
      }

      // Add filters if we have any
      if (filters.isNotEmpty) {
        params["filters"] = jsonEncode(filters);
      }

      // Build URL with parameters
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
        List<dynamic> issues = data["data"] ?? [];

        // Sort by creation date (newest first)
        issues.sort((a, b) {
          final dateA = a["creation"] ?? "";
          final dateB = b["creation"] ?? "";
          return dateB.compareTo(dateA);
        });

        print("[IssueService] Resource API fetched ${issues.length} issues");

        // Debug: Print first issue fields
        if (issues.isNotEmpty) {
          print("[IssueService] Checking for fields:");
          final firstTicket = issues[0] as Map<String, dynamic>;

          // Check description
          if (firstTicket.containsKey("description") && firstTicket["description"] != null) {
            final desc = firstTicket["description"].toString();
            print("  ✓ description: ${desc.length} chars");
          }

          // Check custom fields
          final customFields = ["custom_mobile_no", "custom_vehical_number"];
          for (final field in customFields) {
            if (firstTicket.containsKey(field)) {
              print("  ✓ $field: ${firstTicket[field]}");
            } else {
              print("  ✗ $field: NOT FOUND");
            }
          }
        }

        return issues;
      } else {
        print("[IssueService] Resource API failed: ${response.statusCode}");

        // If 417 error (field permission), try with fewer fields
        if (response.statusCode == 417) {
          return await _fetchWithMinimalFields(sid, customerName, mobileNumber, email);
        }

        return [];
      }
    } catch (e) {
      print("[IssueService] Error in resource API: $e");
      return [];
    }
  }

  /// METHOD 3: Fallback with minimal fields - KEEPING description for images
  static Future<List<dynamic>> _fetchWithMinimalFields(String sid, String customerName, String mobileNumber, String email) async {
    try {
      print("[IssueService] Trying with fallback fields");

      final fields = [
        "name", "subject", "status", "creation",
        "customer", "raised_by", "description",
        "custom_vehical_number"
      ];

      String url = "$baseUrl/api/resource/Issue";
      final params = {
        "fields": jsonEncode(fields),
        "order_by": "creation desc",
        "limit_page_length": "100",
      };

      // Try to filter
      List<String> filterOptions = [];

      if (customerName.isNotEmpty) {
        filterOptions.add("[[\"customer\", \"=\", \"$customerName\"]]");
        filterOptions.add("[[\"raised_by\", \"=\", \"$customerName\"]]");
      }

      if (filterOptions.isNotEmpty) {
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
              List<dynamic> issues = data["data"] ?? [];

              if (issues.isNotEmpty) {
                print("[IssueService] Found ${issues.length} issues with filter: $filter");

                if (issues.isNotEmpty) {
                  final firstTicket = issues[0] as Map<String, dynamic>;

                  if (firstTicket.containsKey("description") && firstTicket["description"] != null) {
                    print("[IssueService] ✓ description found in fallback: ${firstTicket["description"].toString().length} chars");
                  }

                  if (firstTicket.containsKey("custom_vehical_number")) {
                    print("[IssueService] ✓ custom_vehical_number found in fallback: ${firstTicket["custom_vehical_number"]}");
                  }
                }

                return issues;
              }
            }
          } catch (e) {
            print("[IssueService] Filter $filter failed: $e");
          }
        }
      }

      // All filters returned empty (user has no tickets) or no filters available.
      // Return empty list - do NOT make an unfiltered request (that would show all users' tickets).
      print("[IssueService] No tickets found for user");
      return [];
    } catch (e) {
      print("[IssueService] Error in fallback: $e");
      return [];
    }
  }

  /// TEST METHOD: Fetch a single ticket by ID to debug fields
  static Future<Map<String, dynamic>?> fetchTicketById(String ticketId) async {
    try {
      final session = await SessionManager.getCustomerSession();
      if (session == null || session["sid"] == null) {
        return null;
      }

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
}