import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aoj_terminal.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT,
            record_id TEXT,
            payload TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE bookings (
            id TEXT PRIMARY KEY,
            event_id TEXT,
            name TEXT,
            check_in INTEGER,
            payment_status TEXT,
            notes TEXT,
            updated_at TEXT,
            updated_by TEXT,
            version INTEGER,
            is_deleted INTEGER
          )
        ''');
      },
    );

    return _db!;
  }
}