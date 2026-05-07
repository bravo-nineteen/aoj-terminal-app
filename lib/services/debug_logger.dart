import 'package:flutter/foundation.dart';

enum DebugLogLevel { info, warn, error }

class DebugLogEntry {
  final DebugLogLevel level;
  final String message;
  final DateTime timestamp;

  DebugLogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  String get levelLabel {
    switch (level) {
      case DebugLogLevel.info:
        return 'INFO';
      case DebugLogLevel.warn:
        return 'WARN';
      case DebugLogLevel.error:
        return 'ERROR';
    }
  }
}

class DebugLogger extends ChangeNotifier {
  DebugLogger._();

  static final DebugLogger instance = DebugLogger._();

  static const int _maxEntries = 300;

  final List<DebugLogEntry> entries = [];

  void info(String message) => _add(DebugLogLevel.info, message);
  void warn(String message) => _add(DebugLogLevel.warn, message);
  void error(String message) => _add(DebugLogLevel.error, message);

  void _add(DebugLogLevel level, String message) {
    entries.add(DebugLogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    ));
    if (entries.length > _maxEntries) {
      entries.removeRange(0, entries.length - _maxEntries);
    }
    notifyListeners();
  }

  void clear() {
    entries.clear();
    notifyListeners();
  }
}
