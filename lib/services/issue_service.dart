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
      final email = session["email"] ?? "";

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

      // METHOD 3: Try custom endpoint
      try {
        issues = await fetchUsingCustomEndpoint();
        if (issues.isNotEmpty) return issues;
      } catch (e) {
        print("[IssueService] custom endpoint failed: $e");
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

      // Build request body with ALL fields you need
      final Map<String, dynamic> body = {
        "doctype": "Issue",
        "fields": [
          "name", "subject", "status", "priority", "description",
          "creation", "modified", "raised_by",
          "customer", "customer_name", "contact_mobile", "mobile_no",
          "vehicle_number", "issue_type", "resolution_details",
          "assigned_to", "opened_by", "contact_email"
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
        filters.add(["contact_mobile", "=", mobileNumber]);
        filters.add(["mobile_no", "=", mobileNumber]);
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
          issues[0].forEach((key, value) {
            if (value != null) {
              print("  $key: $value");
            }
          });
        }

        return issues;
      } else {
        print("[IssueService] get_list failed: ${response.body}");
        throw Exception("get_list failed: ${response.statusCode}");
      }
    } catch (e) {
      print("[IssueService] Error in get_list: $e");
      rethrow;
    }
  }

  /// METHOD 2: Direct resource API with expanded fields
  static Future<List<dynamic>> _fetchUsingResourceAPI(String sid, String customerName, String mobileNumber, String email) async {
    try {
      print("[IssueService] Using direct resource API with expanded fields");

      // Use ALL fields you need
      final fields = [
        "name", "subject", "status", "priority", "description",
        "creation", "modified", "raised_by",
        "customer", "customer_name", "contact_mobile", "mobile_no",
        "vehicle_number", "issue_type", "resolution_details",
        "assigned_to", "opened_by", "contact_email"
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
        filters.add(["contact_mobile", "=", mobileNumber]);
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
          print("[IssueService] First issue fields:");
          issues[0].forEach((key, value) {
            if (value != null) {
              print("  $key: $value");
            }
          });
        }

        return issues;
      } else {
        print("[IssueService] Resource API failed: ${response.body}");

        // If 417 error (field permission), try with fewer fields
        if (response.statusCode == 417) {
          return await _fetchWithMinimalFields(sid, customerName, mobileNumber, email);
        }

        throw Exception("Failed to fetch issues: ${response.statusCode}");
      }
    } catch (e) {
      print("[IssueService] Error in resource API: $e");
      rethrow;
    }
  }

  /// METHOD 3: Fallback with minimal fields
  static Future<List<dynamic>> _fetchWithMinimalFields(String sid, String customerName, String mobileNumber, String email) async {
    try {
      print("[IssueService] Trying with fallback fields");

      // Try with just essential fields
      final fields = ["name", "subject", "status", "creation", "customer", "raised_by"];

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
        // Try each filter option
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
                return issues;
              }
            }
          } catch (e) {
            print("[IssueService] Filter $filter failed: $e");
          }
        }
      }

      // If no filters worked or no filters, try without filter
      final uri = Uri.parse(url).replace(queryParameters: params);
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
        print("[IssueService] Found ${issues.length} issues without filter");
        return issues;
      }

      return [];
    } catch (e) {
      print("[IssueService] Error in fallback: $e");
      return [];
    }
  }

  /// METHOD 4: Try your custom endpoint
  static Future<List<dynamic>> fetchUsingCustomEndpoint() async {
    try {
      print("[IssueService] Trying custom get_tickets endpoint");

      final session = await SessionManager.getCustomerSession();
      if (session == null || session["sid"] == null) {
        throw Exception("Not authenticated");
      }

      final sid = session["sid"];

      final response = await http.get(
        Uri.parse("$baseUrl/api/method/telemko_support.api.get_tickets"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      print("[IssueService] Custom endpoint response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data["message"];

        if (message is List) {
          print("[IssueService] Custom endpoint returned ${message.length} tickets");

          // Ensure all tickets have the required fields
          final processedTickets = message.map((ticket) {
            // Convert to Map if it's not already
            if (ticket is Map) {
              return ticket;
            } else {
              // Create a basic ticket structure
              return {
                "name": ticket.toString(),
                "subject": "Ticket",
                "status": "Open",
                "creation": DateTime.now().toIso8601String(),
              };
            }
          }).toList();

          return processedTickets;
        } else {
          print("[IssueService] Custom endpoint returned non-list: $message");
          return [];
        }
      } else {
        print("[IssueService] Custom endpoint failed: ${response.body}");
        return [];
      }
    } catch (e) {
      print("[IssueService] Error in custom endpoint: $e");
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