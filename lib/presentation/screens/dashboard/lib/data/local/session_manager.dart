import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyIdentifier = "identifier"; // email / mobile / username
  static const _keyEmail = "email";
  static const _keyMobile = "mobile";
  static const _keySid = "sid";

  /// Save user session (single source of truth)
  static Future<void> saveUser({
    required String identifier,
    String? email,
    String? mobile,
    required String sid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIdentifier, identifier);
    await prefs.setString(_keySid, sid);

    if (email != null) await prefs.setString(_keyEmail, email);
    if (mobile != null) await prefs.setString(_keyMobile, mobile);
  }

  static Future<String?> getIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIdentifier);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobile);
  }

  static Future<String?> getSid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySid);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
