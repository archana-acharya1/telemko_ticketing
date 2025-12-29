import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerApi {
  static const String baseUrl = "http://erp.telemko.com";
  static const String authToken = "token 2259d1e51dadce0:e4b7dfc664256d8";

  /// Verify if customer exists by mobile number
  /// Returns customer details if exists, otherwise null
  static Future<Map<String, dynamic>?> getCustomerByMobile(String mobile) async {
    print("[CustomerApi] Fetching customer info for mobile: $mobile");

    final url = Uri.parse(
      "$baseUrl/api/resource/Customer"
          "?fields=[\"name\",\"customer_name\",\"mobile_no\",\"email_id\"]"
          "&filters=[[\"mobile_no\",\"=\",\"$mobile\"]]",
    );

    print("[CustomerApi] Request URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": authToken,
        },
      );

      print("[CustomerApi] HTTP GET status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"];

        if (data.isNotEmpty) {
          final customer = data[0] as Map<String, dynamic>;
          print("[CustomerApi] Customer found: $customer");
          return customer;
        } else {
          print("[CustomerApi] Customer not found for mobile: $mobile");
          return null;
        }
      } else {
        print("[CustomerApi] Failed to fetch customer. Status: ${response.statusCode}");
        throw Exception("Failed to fetch customer");
      }
    } catch (e) {
      print("[CustomerApi] Error during customer fetch: $e");
      rethrow;
    }
  }

  /// Simple helper to check existence
  static Future<bool> verifyCustomerByMobile(String mobile) async {
    final customer = await getCustomerByMobile(mobile);
    return customer != null;
  }
}
