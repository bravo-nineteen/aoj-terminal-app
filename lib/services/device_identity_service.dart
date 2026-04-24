import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  static const String _keyUsername = 'device_username';

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username.trim());
  }
}
