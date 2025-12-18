import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyEmail = "user_email";
  static const _keyMobile = "user_mobile";
  static const _keySid = "user_sid";

  /// Save user session
  static Future<void> saveUser({
    required String email,
    required String mobile,
    required String sid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyMobile, mobile);
    await prefs.setString(_keySid, sid);
  }

  /// Save email only
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  /// Save mobile only
  static Future<void> saveUserMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMobile, mobile);
  }

  /// Save SID only
  static Future<void> saveSid(String sid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySid, sid);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Get user mobile
  static Future<String?> getUserMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobile);
  }

  /// Get SID
  static Future<String?> getSid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySid);
  }

  /// Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyMobile);
    await prefs.remove(_keySid);
  }
}
