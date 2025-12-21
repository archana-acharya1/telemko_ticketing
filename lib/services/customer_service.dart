import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/api/auth_api.dart';

class CustomerService {
  static const String baseUrl = "http://erp.telemko.com";
  static const String apiToken = "2259d1e51dadce0:e4b7dfc664256d8";

  /// Fetch mobile for email
  static Future<String?> fetchMobileByEmail(String email) async {
    final url = "$baseUrl/api/resource/Customer?filters=[[\"email\",\"=\",\"$email\"]]";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "token $apiToken",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)["data"];
      return data.isNotEmpty ? data[0]["mobile_no"].toString() : null;
    }
    return null;
  }

  /// Fetch customer name for email
  static Future<String?> fetchCustomerByEmail(String email) async {
    final url = "$baseUrl/api/resource/Customer?filters=[[\"email\",\"=\",\"$email\"]]";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "token $apiToken",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)["data"];
      return data.isNotEmpty ? data[0]["name"].toString() : null;
    }
    return null;
  }
}
