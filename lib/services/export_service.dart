
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aoj_models.dart';

class ExportService {
  static Future<String> exportActiveEventJson(EventRecord event) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${event.name.replaceAll(' ', '_')}_export.json');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(event.toJson()),
      flush: true,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'AOJ event export: ${event.name}',
    );

    return 'EXPORTED ${event.name}';
  }
}
