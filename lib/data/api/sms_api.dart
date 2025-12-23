import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsApi {
  static const String baseUrl = "http://erp.telemko.com";

  static Future<void> sendSms({
    required String mobile,
    required String message,
  }) async {
    print("[SmsApi] Sending SMS to: $mobile");
    print("[SmsApi] Message: $message");

    final url = Uri.parse(
      "$baseUrl/api/method/telemko_support.api.send_sms.send_sms_api",
    );

    try {
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

      print("[SmsApi] Response status: ${response.statusCode}");
      print("[SmsApi] Response body: ${response.body}");

      if (response.statusCode != 200) {
        print("[SmsApi] Failed to send SMS");
        throw Exception("Failed to send SMS");
      }

      print("[SmsApi] SMS sent successfully to $mobile");
    } catch (e) {
      print("[SmsApi] Error sending SMS: $e");
      rethrow;
    }
  }
}
