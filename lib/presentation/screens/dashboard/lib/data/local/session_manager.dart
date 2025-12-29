import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../data/api/api_client.dart';

class SessionManager {
  static const _keyCustomerName = "customer_name";
  static const _keyMobileNo = "mobile_no";
  static const _keyEmailId = "email_id";
  static const _keySid = "sid";
  static const _keyLoginType = "login_type";

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

    ApiClient.setSid(sid);

    print("[SessionManager] Session saved: SID=$sid, Name=$customerName, Mobile=$mobileNo");
  }

  static Future<String?> getSid() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString(_keySid);
    if (sid != null && sid.isNotEmpty) {
      ApiClient.setSid(sid);
      print("[SessionManager] SID loaded: $sid");
      return sid;
    }
    print("[SessionManager] No SID found");
    return null;
  }

  static Future<Map<String, dynamic>?> getCustomerSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString(_keySid);
    if (sid == null || sid.isEmpty) {
      print("[SessionManager] getCustomerSession: SID missing");
      return null;
    }

    ApiClient.setSid(sid);
    print("[SessionManager] getCustomerSession: SID=$sid");

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
    ApiClient.setSid(null);
    print("[SessionManager] Session cleared");
  }
}
