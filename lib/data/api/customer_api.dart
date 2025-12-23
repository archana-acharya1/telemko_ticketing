import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerApi {
  static const String baseUrl = "http://erp.telemko.com";

  // Verify if customer exists by mobile number
  static Future<bool> verifyCustomerByMobile(String mobile) async {
    print("[CustomerApi] Verifying customer with mobile: $mobile");

    final url = Uri.parse(
      "$baseUrl/api/resource/Customer"
          "?fields=[\"name\"]"
          "&filters=[[\"mobile_no\",\"=\",\"$mobile\"]]",
    );

    print("[CustomerApi] Request URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "token 2259d1e51dadce0:e4b7dfc664256d8",
        },
      );

      print("[CustomerApi] HTTP GET status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"];
        final exists = data.isNotEmpty;

        print("[CustomerApi] Customer exists: $exists");

        return exists;
      } else {
        print("[CustomerApi] Customer verification failed with status: ${response.statusCode}");
        throw Exception("Customer verification failed");
      }
    } catch (e) {
      print("[CustomerApi] Error during customer verification: $e");
      rethrow;
    }
  }
}
