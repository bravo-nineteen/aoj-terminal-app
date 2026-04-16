import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'local_database_service.dart';

class SyncService {
  SyncService({
    required this.endpoint,
  });

  final String endpoint;

  Future<void> queueChange({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    final Database db = await LocalDatabaseService.database;

    await db.insert(
      'sync_outbox',
      <String, Object?>{
        'table_name': tableName,
        'record_id': recordId,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> pushPendingChanges() async {
    final Database db = await LocalDatabaseService.database;

    final List<Map<String, Object?>> rows = await db.query(
      'sync_outbox',
      orderBy: 'id ASC',
    );

    for (final Map<String, Object?> row in rows) {
      try {
        final http.Response response = await http.post(
          Uri.parse(endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: row['payload'] as String,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await db.delete(
            'sync_outbox',
            where: 'id = ?',
            whereArgs: <Object?>[row['id']],
          );
        }
      } catch (_) {
        // Keep the row in outbox for retry later.
      }
    }
  }
}