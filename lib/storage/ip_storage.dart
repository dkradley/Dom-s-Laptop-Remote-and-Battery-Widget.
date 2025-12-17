import 'package:shared_preferences/shared_preferences.dart';

class IpStorage {
  static const _key = 'pc_ip';

  /// Load the saved IP address from SharedPreferences.
  static Future<String?> loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Save the IP address so the app remembers it.
  static Future<void> saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, ip);
  }
}