import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerApi {
  static const String baseUrl = "http://erp.telemko.com";

  static Future<bool> verifyCustomerByMobile(String mobile) async {
    final url = Uri.parse(
      "$baseUrl/api/resource/Customer"
          "?fields=[\"name\"]"
          "&filters=[[\"mobile_no\",\"=\",\"$mobile\"]]",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "token 2259d1e51dadce0:e4b7dfc664256d8",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded["data"];
      return data.isNotEmpty;
    } else {
      throw Exception("Customer verification failed");
    }
  }
}
