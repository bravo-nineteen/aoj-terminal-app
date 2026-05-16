import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  static const String _keyUsername = 'device_username';
  static const String _keyThemeDark = 'theme_is_dark';
  static const String _keyMessagesReadCursorPrefix = 'messages_last_read_';

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

  static String _messagesReadCursorKey(String scope) {
    final normalized = scope.trim().isEmpty ? 'default' : scope.trim();
    return '$_keyMessagesReadCursorPrefix$normalized';
  }

  static Future<DateTime?> getMessagesLastReadAt(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesReadCursorKey(scope));
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static Future<void> setMessagesLastReadAt(String scope, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _messagesReadCursorKey(scope),
      timestamp.toUtc().toIso8601String(),
    );
  }
}
