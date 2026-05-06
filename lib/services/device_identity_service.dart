import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  static const String _keyUsername = 'device_username';
  static const String _keyThemeDark = 'theme_is_dark';

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username.trim());
  }

  /// Returns true for dark mode, false for light mode.
  /// Defaults to dark if never saved.
  static Future<bool> getIsDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThemeDark) ?? true;
  }

  static Future<void> setIsDarkTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeDark, isDark);
  }
}
