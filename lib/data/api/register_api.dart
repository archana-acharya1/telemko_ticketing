import 'frappe_api.dart';

class RegisterApi {
  static Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await FrappeApi.post("/api/resource/User", {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "enabled": 1,
      "new_password": password,
    });
  }
}
