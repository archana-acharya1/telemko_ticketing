import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsApi {
  static const String baseUrl = "http://erp.telemko.com";

  static Future<void> sendSms({
    required String mobile,
    required String message,
  }) async {
    final url = Uri.parse(
      "$baseUrl/api/method/telemko_support.api.send_sms.send_sms_api",
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "token 2259d1e51dadce0:e4b7dfc664256d8",
      },
      body: jsonEncode({
        "receiver_list": mobile,
        "message": message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to send SMS");
    }
  }
}
