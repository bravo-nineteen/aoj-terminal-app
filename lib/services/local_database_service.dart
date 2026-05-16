import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _db;
  static const int _schemaVersion = 2;

  static Future<void> _createBaseSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT,
        record_id TEXT,
        payload TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
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
  }

  static Future<void> _applyMigrationV2(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_created_at ON sync_outbox(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_table_record ON sync_outbox(table_name, record_id)',
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createBaseSchema(db);
      await _applyMigrationV2(db);
    }
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aoj_terminal.db');

    _db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, version) async {
        await _createBaseSchema(db);
        if (version >= 2) {
          await _applyMigrationV2(db);
        }
      },
      onUpgrade: _onUpgrade,
    );

    return _db!;
  }
}