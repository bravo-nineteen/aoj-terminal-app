
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/aoj_models.dart';

class AppStateService {
  static Future<File> stateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/aoj_app_state.json');
  }

  static Future<AppStateData?> load() async {
    final file = await stateFile();
    if (!await file.exists()) return null;
    final jsonText = await file.readAsString();
    final map = jsonDecode(jsonText) as Map<String, dynamic>;
    return AppStateData.fromJson(map);
  }

  static Future<void> save(AppStateData appState) async {
    final file = await stateFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(appState.toJson()),
      flush: true,
    );
  }
}
