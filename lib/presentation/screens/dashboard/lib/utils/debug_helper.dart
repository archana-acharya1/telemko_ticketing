// lib/utils/debug_helper.dart
import 'package:http/http.dart' as http;

class DebugHelper {
  static Future<void> testSession(String sid) async {
    try {
      print("🧪 Testing session validity...");

      final response = await http.get(
        Uri.parse("http://erp.telemko.com/api/method/frappe.auth.get_logged_user"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
      );

      if (response.statusCode == 200) {
        print("✅ Session is VALID - User is logged in");
      } else {
        print("❌ Session is INVALID - Status: ${response.statusCode}");
      }
    } catch (e) {
      print("💥 Session test error: $e");
    }
  }

  static Future<void> testApiConnection() async {
    try {
      print("🌐 Testing API connection...");

      // Test a simple API endpoint
      final response = await http.get(
        Uri.parse("http://erp.telemko.com/api/method/frappe.ping"),
      );

      print("📡 API Connection Status: ${response.statusCode}");
      print("📡 Response: ${response.body}");
    } catch (e) {
      print("💥 API Connection Error: $e");
    }
  }
}