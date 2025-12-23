import 'frappe_api.dart';

class RegisterApi {
  static Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    print("[RegisterApi] Registering user:");
    print("  First Name: $firstName");
    print("  Last Name: $lastName");
    print("  Email: $email");
    print("  Password length: ${password.length}");

    try {
      final response = await FrappeApi.post("/api/resource/User", {
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "enabled": 1,
        "new_password": password,
      });

      print("[RegisterApi] Registration successful. Response: $response");
    } catch (e) {
      print("[RegisterApi] Registration failed: $e");
      rethrow;
    }
  }
}
