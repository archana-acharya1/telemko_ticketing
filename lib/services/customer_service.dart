// // lib/services/customer_service.dart
// import 'dart:convert';
// import 'dart:io';
//
// class CustomerService {
//   static const String baseUrl = "http://simtrack.deskgoo.com";
//   static const String authToken =
//       "2259d1e51dadce0:e4b7dfc664256d8";
//
//   static Future<List<String>> fetchCustomers() async {
//     try {
//       final url = Uri.parse("$baseUrl/api/resource/Customer");
//
//       final request = await HttpClient().getUrl(url);
//       request.headers.set("Authorization", authToken);
//       request.headers.set("Content-Type", "application/json");
//
//       final response = await request.close();
//       final body = await response.transform(const Utf8Decoder()).join();
//       final data = jsonDecode(body);
//
//       final list = data["data"] as List;
//       return list.map((e) => e["name"].toString()).toList();
//     } catch (e) {
//       print("Customer fetch error: $e");
//       return [];
//     }
//   }
// }


// services/customer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/api/auth_api.dart';

class CustomerService {
  static const String baseUrl = "http://erp.telemko.com";
  static const String apiToken = "2259d1e51dadce0:e4b7dfc664256d8";

  // Fetch all customers
  static Future<List<String>> fetchCustomers() async {
    final url = "$baseUrl/api/resource/Customer";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "token $apiToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List data = jsonResponse["data"];

      return data.map<String>((item) => item["name"].toString()).toList();
    } else {
      throw Exception("Failed to fetch customers");
    }
  }

  // Fetch customer linked to logged-in user
  static Future<String?> fetchCustomerForUser(String username) async {
    final url =
        "$baseUrl/api/resource/Customer?filters=[[\"owner\",\"=\",\"$username\"]]";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "token $apiToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List data = jsonResponse["data"];
      return data.isNotEmpty ? data[0]["name"].toString() : null;
    } else {
      throw Exception("Failed to fetch customer for user");
    }
  }
}
