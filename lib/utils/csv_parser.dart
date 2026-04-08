
class CsvParser {
  static List<List<String>> parse(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(cell.toString());
        cell.clear();
        rows.add(List<String>.from(row));
        row.clear();
      } else {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(List<String>.from(row));
    }

    return rows;
  }

  static int findHeaderIndex(List<List<String>> rows, List<String> required) {
    for (int i = 0; i < rows.length; i++) {
      final lower = rows[i].map((e) => e.trim().toLowerCase()).toList();
      final ok = required.every((r) => lower.contains(r.toLowerCase()));
      if (ok) return i;
    }
    return 0;
  }

  static Map<String, String> rowToMap(List<String> headers, List<String> row) {
    final map = <String, String>{};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i]] = i < row.length ? row[i] : '';
    }
    return map;
  }

  static String firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final v = value?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static String cleanImportedPhone(String value) {
    var cleaned = value.trim();
    if (cleaned.startsWith("'")) {
      cleaned = cleaned.substring(1);
    }
    return cleaned.trim();
  }

  static bool isImportedCardPayment(String method) {
    final normalized = method.trim().toLowerCase();
    return normalized.contains('credit');
  }

  static String splitFirstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '';
  }

  static String splitLastName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }
}
