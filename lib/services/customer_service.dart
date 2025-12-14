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

class CustomerService {
  static Future<List<String>> fetchCustomers() async {
    final url = "http://erp.telemko.com/api/resource/Customer";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "token 2259d1e51dadce0:e4b7dfc664256d8",
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
}
