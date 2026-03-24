import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../data/api/api_client.dart';

class SessionManager {

  static const _keyCustomerName = "customer_name";
  static const _keyMobileNo = "mobile_no";
  static const _keyEmailId = "email_id";
  static const _keySid = "sid";
  static const _keyLoginType = "login_type";

  static String? _cachedSid;

  static Future<void> saveCustomerSession({
    required String customerName,
    required String mobileNo,
    required String emailId,
    required String sid,
    required String loginType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomerName, customerName);
    await prefs.setString(_keyMobileNo, mobileNo);
    await prefs.setString(_keyEmailId, emailId);
    await prefs.setString(_keySid, sid);
    await prefs.setString(_keyLoginType, loginType);

    _cachedSid = sid;
    ApiClient.setSid(sid);

    print("[SessionManager] Session saved: SID=$sid, Name=$customerName, Mobile=$mobileNo");
  }



  static Future<String?> getSid() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString(_keySid);

    if (sid != null && sid.isNotEmpty) {
      _cachedSid = sid;
      ApiClient.setSid(sid);
      print("[SessionManager] SID loaded: $sid");
      return sid;
    }

    _cachedSid = null;
    print("[SessionManager] No SID found");
    return null;
  }

  static bool isLoggedIn() {
    return _cachedSid != null && _cachedSid!.isNotEmpty;
  }


  static Future<Map<String, dynamic>?> getCustomerSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Ensure SID is loaded from storage (e.g. after app restart or when _cachedSid was never set)
    String? sid = _cachedSid ?? prefs.getString(_keySid);
    if (sid != null && sid.isNotEmpty) {
      _cachedSid = sid;
      ApiClient.setSid(sid);
    }
    if (sid == null || sid.isEmpty) {
      print("[SessionManager] getCustomerSession: No SID in memory or prefs");
      return null;
    }
    return {
      "customer_name": prefs.getString(_keyCustomerName) ?? "",
      "mobile_no": prefs.getString(_keyMobileNo) ?? "",
      "email_id": prefs.getString(_keyEmailId) ?? "",
      "sid": sid,
      "login_type": prefs.getString(_keyLoginType) ?? "",
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _cachedSid = null;
    ApiClient.setSid(null);
    print("[SessionManager] Session cleared");
  }
  // Add this method to SessionManager class
  static Future<void> debugSession() async {
    final prefs = await SharedPreferences.getInstance();

    print("🔍 === SESSION DEBUG ===");
    print("customer_name: ${prefs.getString(_keyCustomerName)}");
    print("mobile_no: ${prefs.getString(_keyMobileNo)}");
    print("email_id: ${prefs.getString(_keyEmailId)}");
    final sid = prefs.getString(_keySid);
    print("sid: ${sid != null ? '${sid.substring(0, 20)}... (length: ${sid.length})' : 'null'}");
    print("login_type: ${prefs.getString(_keyLoginType)}");
    print("========================");
  }

  static Future<void> printSessionDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();

    print("🔍 === SESSION DEBUG INFO ===");
    print("SharedPreferences keys:");
    final keys = prefs.getKeys();
    keys.forEach((key) {
      final value = prefs.get(key);
      print("  $key: ${value.toString().substring(0, min(50, value.toString().length))}...");
    });

    final sid = prefs.getString(_keySid);
    print("\nSID Analysis:");
    print("  - Exists: ${sid != null}");
    print("  - Length: ${sid?.length ?? 0}");
    print("  - Value preview: ${sid?.substring(0, min(30, sid?.length ?? 0))}...");
    print("  - Looks valid: ${sid != null && sid.length > 10 && sid != "Logged In"}");

    print("=============================");
  }
}