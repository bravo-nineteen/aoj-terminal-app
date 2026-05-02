import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aoj_models.dart';
import 'messages_service.dart';

const String _kFallbackSupabaseUrl = 'https://uvixlrhcjojezhqmgnxk.supabase.co';
const String _kFallbackSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2aXhscmhjam9qZXpocW1nbnhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMzY5NzIsImV4cCI6MjA5MTkxMjk3Mn0'
    '.1ychTDnuRxtOFY9SquXtg8RkzX0UxvyXENU1ncAaFO4';

class SupabaseService {
  static String? _resolvedSupabaseUrl;
  static const String _kExpectedSchemaVersion = '2026-04-24';

  static const String _tableAppConfig = 'app_config';
  static const String _tableEvents = 'events';
  static const String _tableBookings = 'bookings';
  static const String _tablePayments = 'payments';
  static const String _tableTickets = 'tickets';
  static const String _tableMembers = 'members';
  static const String _tableSchedule = 'schedule';
  static const String _tableExpenses = 'expenses';
  static const String _tableGameModes = 'game_modes';
  static const String _tableSyncLog = 'sync_log';

  static SyncDiagnosticsRecord _syncDiagnostics =
    SyncDiagnosticsRecord.empty();
  static SchemaHealthRecord _schemaHealth =
    SchemaHealthRecord.unchecked(expectedVersion: _kExpectedSchemaVersion);
  static final List<MergeConflictRecord> _recentMergeConflicts =
    <MergeConflictRecord>[];

  static SyncDiagnosticsRecord get syncDiagnostics => _syncDiagnostics;
  static SchemaHealthRecord get schemaHealth => _schemaHealth;
  static List<MergeConflictRecord> get recentMergeConflicts =>
    List<MergeConflictRecord>.unmodifiable(_recentMergeConflicts);

  static String get resolvedSupabaseUrl => _resolvedSupabaseUrl ?? '';

  static String get resolvedSupabaseHost {
    final uri = Uri.tryParse(resolvedSupabaseUrl);
    return uri?.host ?? '';
  }

  static String _stripOuterQuotes(String value) {
    var current = value.trim();
    while (current.length >= 2) {
      final startsWithQuote =
          current.startsWith('"') || current.startsWith("'") || current.startsWith('`');
      final endsWithQuote =
          current.endsWith('"') || current.endsWith("'") || current.endsWith('`');
      if (!startsWithQuote || !endsWithQuote) break;
      current = current.substring(1, current.length - 1).trim();
    }
    return current;
  }

  static String _normalizeSupabaseUrl(String rawUrl) {
    var value = rawUrl.replaceAll('\r', ' ').replaceAll('\n', ' ').trim();

    // Support accidentally pasting a full command and extract first URL token.
    for (final token in value.split(RegExp(r'\s+'))) {
      final lower = token.toLowerCase();
      final httpsIndex = lower.indexOf('https://');
      final httpIndex = lower.indexOf('http://');
      final startIndex = httpsIndex >= 0 ? httpsIndex : httpIndex;
      if (startIndex >= 0) {
        value = token.substring(startIndex);
        break;
      }
    }

    // Support accidentally pasting the full define segment.
    final defineMatch = RegExp(
      r'supabase_url\s*=\s*([^\s]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (defineMatch != null) {
      value = defineMatch.group(1) ?? value;
    }

    value = _stripOuterQuotes(value)
        .replaceAll(RegExp(r'[,;]+$'), '')
        .trim();

    if (value.startsWith('https://https://')) {
      value = value.substring('https://'.length);
    } else if (value.startsWith('http://http://')) {
      value = value.substring('http://'.length);
    }

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.host.isEmpty) {
      throw ArgumentError('Invalid SUPABASE_URL: $rawUrl');
    }

    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
    ).toString();
  }

  static bool _isPlaceholderSupabaseUrl(String value) {
    final normalized = _stripOuterQuotes(value).trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (normalized == '...') return true;
    if (normalized == 'supabase_url') return true;
    if (normalized == 'your_supabase_url') return true;
    if (normalized.contains('your-project-id')) return true;
    if (normalized.contains('your_project_ref')) return true;
    if (normalized.contains('your-project-ref')) return true;
    return false;
  }

  static bool _isPlaceholderSupabaseHost(String host) {
    final normalized = host.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (normalized == 'localhost') return true;
    if (normalized == 'supabase') return true;
    if (normalized == 'supabase_url') return true;
    if (normalized.contains('your-project-id')) return true;
    if (normalized.contains('your_project_ref')) return true;
    if (normalized.contains('your-project-ref')) return true;
    if (!normalized.contains('.')) return true;
    return false;
  }

  static Future<void> initialize() async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    var effectiveUrlInput =
        _isPlaceholderSupabaseUrl(envUrl) ? _kFallbackSupabaseUrl : envUrl;

    if (effectiveUrlInput.isEmpty) {
      effectiveUrlInput = _kFallbackSupabaseUrl;
    }

    var resolvedUrl = _normalizeSupabaseUrl(effectiveUrlInput);
    final resolvedHost = Uri.tryParse(resolvedUrl)?.host ?? '';
    if (_isPlaceholderSupabaseHost(resolvedHost)) {
      resolvedUrl = _kFallbackSupabaseUrl;
    }
    _resolvedSupabaseUrl = resolvedUrl;

    final resolvedAnonKey =
        envAnonKey.isNotEmpty ? envAnonKey : _kFallbackSupabaseAnonKey;

    await Supabase.initialize(
      url: resolvedUrl,
      anonKey: resolvedAnonKey,
    );
  }

  static SupabaseClient get _db => Supabase.instance.client;
  /// Safely convert a field that might be a JSON string or already a list.
  /// If the value is a string, decode it as JSON. Otherwise, treat it as a list.
  static List<dynamic> _safeJsonToList(dynamic value) {
    if (value == null) return [];
    if (value is List<dynamic>) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List<dynamic>) return decoded;
        return [];
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static Map<String, dynamic> _safeJsonToMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        return <String, dynamic>{};
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }


  static bool _isHostLookupError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('name or service not known') ||
        message.contains('temporary failure in name resolution');
  }

  static Future<T> _withHostLookupRetry<T>(Future<T> Function() action) async {
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final isRetryable = _isHostLookupError(e);
        final isLast = attempt == 2;
        if (!isRetryable || isLast) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('Unknown host lookup failure');
  }

  static String _extractErrorCode(Object error) {
    if (error is PostgrestException) {
      return error.code ?? '';
    }
    return '';
  }

  static String _normalizeSyncSchemaError(Object error) {
    if (error is! PostgrestException) return error.toString();
    final code = error.code ?? '';
    final message = error.message.toLowerCase();
    if (code == 'PGRST204' && message.contains('events')) {
      return 'Supabase schema is missing expected fields on public.events. Apply latest migrations/sql (including accounting_notes).';
    }
    return error.toString();
  }

  static void _recordConflict({
    required String entityType,
    required String entityId,
    required String field,
    required String localValue,
    required String cloudValue,
    required String resolvedValue,
  }) {
    if (localValue.trim().isEmpty || cloudValue.trim().isEmpty) return;
    if (localValue.trim() == cloudValue.trim()) return;
    _recentMergeConflicts.add(
      MergeConflictRecord(
        entityType: entityType,
        entityId: entityId,
        field: field,
        localValue: localValue,
        cloudValue: cloudValue,
        resolvedValue: resolvedValue,
        detectedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    if (_recentMergeConflicts.length > 200) {
      _recentMergeConflicts.removeRange(0, _recentMergeConflicts.length - 200);
    }
  }

  static Future<SchemaHealthRecord> checkSchemaHealth() async {
    final issues = <String>[];
    String actualVersion = '';

    Future<void> checkTable(String table) async {
      try {
        await _db.from(table).select().limit(1);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST205') {
          issues.add('Missing table: public.$table');
          return;
        }
        if (e.code == '42501') {
          issues.add('RLS/permission denied: public.$table');
          return;
        }
        issues.add('Table check failed for $table: ${e.message}');
      }
    }

    await checkTable(_tableAppConfig);
    await checkTable(_tableEvents);
    await checkTable(_tableBookings);
    await checkTable(_tableTickets);
    await checkTable(_tableMembers);
    await checkTable(_tableSchedule);
    await checkTable(_tableExpenses);
    await checkTable(_tableGameModes);
    await checkTable('messages');

    try {
      final row = await _db
          .from(_tableAppConfig)
          .select('value')
          .eq('key', 'schema_version')
          .maybeSingle();
      actualVersion = (row?['value'] as String?) ?? '';
      if (actualVersion.isEmpty) {
        issues.add('Missing app_config.schema_version');
      } else if (actualVersion != _kExpectedSchemaVersion) {
        issues.add(
          'Schema version mismatch: expected $_kExpectedSchemaVersion, got $actualVersion',
        );
      }
    } catch (e) {
      issues.add('Schema version check failed: $e');
    }

    _schemaHealth = SchemaHealthRecord(
      healthy: issues.isEmpty,
      expectedVersion: _kExpectedSchemaVersion,
      actualVersion: actualVersion,
      checkedAt: DateTime.now().toUtc().toIso8601String(),
      issues: issues,
    );

    return _schemaHealth;
  }

  // ─── Push ─────────────────────────────────────────────────────────────────

  /// Pushes the full local app state to Supabase with merge-safe upserts.
  ///
  /// This intentionally avoids table pruning to reduce accidental data loss
  /// across multiple devices that sync at different times.
  static Future<void> pushAppState(AppStateData appState) async {
    final db = _db;

    // ── events ──────────────────────────────────────────────────────────────
    final eventRows = appState.events
        .map(
          (e) => <String, dynamic>{
            'id': e.id,
            'name': e.name,
            'venue': e.venue,
            'date': e.date,
            'time': e.time,
            'notes': e.notes,
            'ticket_cost_per_person': e.ticketCostPerPerson,
            'training_trainer': e.trainingTrainer,
            'lunch_options': e.lunchOptions.map((o) => o.toJson()).toList(),
            'field_map_base64': e.fieldMapBase64,
            'game_modes': e.gameModes.map((g) => g.toJson()).toList(),
            'accounting_notes':
                e.accountingNotes.map((n) => n.toJson()).toList(),
          },
        )
        .toList();

    if (eventRows.isNotEmpty) {
      await db.from(_tableEvents).upsert(eventRows);
    }

    // ── Save active event id ─────────────────────────────────────────────────
    await db.from(_tableAppConfig).upsert(<String, dynamic>{
      'key': 'active_event_id',
      'value': appState.activeEventId ?? '',
    });

    // ── Per-event sub-tables ─────────────────────────────────────────────────
    for (final event in appState.events) {
      await _pushBookings(db, event);
      await _pushPaymentsMirror(db, event);
      await _pushTickets(db, event);
      await _pushMembers(db, event);
      await _pushSchedule(db, event);
      await _pushExpenses(db, event);
      await _pushGameModes(db, event);
    }
  }

  static Future<void> _pushGameModes(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = event.gameModes
        .map(
          (g) => <String, dynamic>{
            'id': '${event.id}_${_gameModeSignature(g.data)}',
            'event_id': event.id,
            'data': g.toJson()['data'],
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from(_tableGameModes).upsert(rows);
    }
  }

  static String _gameModeSignature(Map<String, String> data) {
    final keys = data.keys.toList()..sort();
    final signature = keys.map((k) => '$k=${data[k] ?? ''}').join('|');
    return signature.hashCode.toUnsigned(32).toString();
  }

  static Future<void> _pushBookings(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = event.bookings
        .map(
          (b) => <String, dynamic>{
            'id': b.id,
            'event_id': event.id,
            'booking_id': b.bookingId,
            'booking_date': b.bookingDate,
            'first_name': b.firstName,
            'last_name': b.lastName,
            'email': b.email,
            'phone': b.phone,
            'event': b.event,
            'total': b.total,
            'total_paid': b.totalPaid,
            'transaction_id': b.transactionId,
            'payment_method': b.paymentMethod,
            'payment_status': b.paymentStatus,
            'check_in_status': b.checkInStatus,
            'notes': b.notes,
            'needs_pickup': b.needsPickup,
            'needs_training': b.needsTraining,
            'guest_names': b.guestNames,
            'language_preference': b.languagePreference,
            'lunch_order_ids': b.lunchOrderIds,
            'ticket_ids': b.ticketIds,
            'sales': b.sales.map((s) => s.toJson()).toList(),
            'payments': b.payments.map((p) => p.toJson()).toList(),
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from(_tableBookings).upsert(rows);
    }
  }

  static Future<void> _pushTickets(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = event.tickets
        .map(
          (t) => <String, dynamic>{
            'id': t.id,
            'event_id': event.id,
            'booking_id': t.bookingId,
            'booking_name': t.bookingName,
            'ticket_name': t.ticketName,
            'price': t.price,
            'spaces': t.spaces,
            'status': t.status,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from(_tableTickets).upsert(rows);
    }
  }

  static Future<void> _pushPaymentsMirror(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = <Map<String, dynamic>>[];

    for (final booking in event.bookings) {
      for (final payment in booking.payments) {
        rows.add(
          <String, dynamic>{
            'id': '${booking.id}_${payment.id}',
            'event_id': event.id,
            'booking_row_id': booking.id,
            'booking_id': booking.bookingId,
            'payment_id': payment.id,
            'amount': payment.amount,
            'method': payment.method,
            'note': payment.note,
            'date': payment.date,
          },
        );
      }
    }

    if (rows.isEmpty) return;

    // Optional mirror table for external querying. Ignore if schema does not
    // include this table/shape yet.
    try {
      await db.from(_tablePayments).upsert(rows);
    } catch (_) {}
  }

  static Future<void> _pushMembers(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = event.members
        .map(
          (m) => <String, dynamic>{
            'id': m.id,
            'event_id': event.id,
            'first_name': m.firstName,
            'last_name': m.lastName,
            'username': m.username,
            'date_of_birth': m.dateOfBirth,
            'gender': m.gender,
            'telephone': m.telephone,
            'email': m.email,
            'membership_level': m.membershipLevel,
            'rating': m.rating,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from(_tableMembers).upsert(rows);
    }
  }

  static Future<void> _pushSchedule(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = event.schedule
        .map(
          (s) => <String, dynamic>{
            'id': s.id,
            'event_id': event.id,
            'time': s.time,
            'activity': s.activity,
            'location': s.location,
            'notes': s.notes,
            'game_mode_title': s.gameModeTitle,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from(_tableSchedule).upsert(rows);
    }
  }

  static Future<void> _pushExpenses(
    SupabaseClient db,
    EventRecord event,
  ) async {
    final rows = event.expenses
        .map(
          (e) => <String, dynamic>{
            'id': e.id,
            'event_id': event.id,
            'item': e.item,
            'amount': e.amount,
            'note': e.note,
            'date': e.date,
            'category': e.category,
            'notes': e.notes.map((n) => n.toJson()).toList(),
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from(_tableExpenses).upsert(rows);
    }
  }

  /// Pulls, merges, and pushes so each device converges to one merged state.
  static Future<AppStateData> syncMergeAppState(AppStateData localState) async {
    _syncDiagnostics = SyncDiagnosticsRecord(
      operation: 'sync-merge',
      startedAt: DateTime.now().toUtc().toIso8601String(),
      completedAt: '',
      localEvents: localState.events.length,
      cloudEvents: 0,
      mergedEvents: 0,
      conflicts: _recentMergeConflicts.length,
      lastError: '',
      lastErrorCode: '',
    );

    try {
      final health = await _withHostLookupRetry(checkSchemaHealth);
      if (!health.healthy) {
        throw StateError('Schema check failed: ${health.issues.join('; ')}');
      }

      final cloudState = await _withHostLookupRetry(() => pullAppState());
      final merged = _mergeAppState(localState, cloudState);
      await _withHostLookupRetry(() => pushAppState(merged));

      _syncDiagnostics = SyncDiagnosticsRecord(
        operation: 'sync-merge',
        startedAt: _syncDiagnostics.startedAt,
        completedAt: DateTime.now().toUtc().toIso8601String(),
        localEvents: localState.events.length,
        cloudEvents: cloudState.events.length,
        mergedEvents: merged.events.length,
        conflicts: _recentMergeConflicts.length,
        lastError: '',
        lastErrorCode: '',
      );
      await _tryWriteSyncLog(_syncDiagnostics);
      return merged;
    } catch (e) {
      _syncDiagnostics = SyncDiagnosticsRecord(
        operation: 'sync-merge',
        startedAt: _syncDiagnostics.startedAt,
        completedAt: DateTime.now().toUtc().toIso8601String(),
        localEvents: localState.events.length,
        cloudEvents: _syncDiagnostics.cloudEvents,
        mergedEvents: _syncDiagnostics.mergedEvents,
        conflicts: _recentMergeConflicts.length,
        lastError: _normalizeSyncSchemaError(e),
        lastErrorCode: _extractErrorCode(e),
      );
      await _tryWriteSyncLog(_syncDiagnostics);
      rethrow;
    }
  }

  // ─── Pull ─────────────────────────────────────────────────────────────────

  /// Pulls the full app state from Supabase and returns an [AppStateData].
  static Future<AppStateData> pullAppState() async {
    final db = _db;

    // Active event id
    final configRow = await db
        .from(_tableAppConfig)
        .select()
        .eq('key', 'active_event_id')
        .maybeSingle();
    final rawActiveId = configRow?['value'] as String?;
    final activeEventId =
        (rawActiveId == null || rawActiveId.isEmpty) ? null : rawActiveId;

    // Events
    final List<Map<String, dynamic>> eventRows =
        List<Map<String, dynamic>>.from(
      await db.from(_tableEvents).select(),
    );

    final events = <EventRecord>[];

    for (final row in eventRows) {
      final eventId = row['id'] as String;

      final List<Map<String, dynamic>> bookingRows =
          List<Map<String, dynamic>>.from(
        await db.from(_tableBookings).select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> ticketRows =
          List<Map<String, dynamic>>.from(
        await db.from(_tableTickets).select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> memberRows =
          List<Map<String, dynamic>>.from(
        await db.from(_tableMembers).select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> scheduleRows =
          List<Map<String, dynamic>>.from(
        await db.from(_tableSchedule).select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> expenseRows =
          List<Map<String, dynamic>>.from(
        await db.from(_tableExpenses).select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> gameModeRows =
          List<Map<String, dynamic>>.from(
        await db.from(_tableGameModes).select().eq('event_id', eventId),
      );

      final gameModes = gameModeRows.isNotEmpty
          ? gameModeRows
              .map(
                (g) => GameModeRecord.fromJson(
                  <String, dynamic>{'data': _safeJsonToMap(g['data'])},
                ),
              )
              .toList()
          : _safeJsonToList(row['game_modes'])
              .map(
                (g) =>
                    GameModeRecord.fromJson(Map<String, dynamic>.from(g as Map)),
              )
              .toList();

      final accountingNotes =
          _safeJsonToList(row['accounting_notes'])
              .map(
                (n) =>
                    NoteRecord.fromJson(Map<String, dynamic>.from(n as Map)),
              )
              .toList();

      final lunchOptions = _safeJsonToList(row['lunch_options'])
          .map(
            (o) => LunchOptionRecord.fromJson(Map<String, dynamic>.from(o as Map)),
          )
          .toList();

      final bookings = bookingRows.map((b) {
        return BookingRecord(
          id: b['id'] as String? ?? '',
          bookingId: b['booking_id'] as String? ?? '',
          bookingDate: b['booking_date'] as String? ?? '',
          firstName: b['first_name'] as String? ?? '',
          lastName: b['last_name'] as String? ?? '',
          email: b['email'] as String? ?? '',
          phone: b['phone'] as String? ?? '',
          event: b['event'] as String? ?? '',
          total: b['total'] as String? ?? '0',
          totalPaid: b['total_paid'] as String? ?? '0',
          transactionId: b['transaction_id'] as String? ?? '',
          paymentMethod: b['payment_method'] as String? ?? '',
          paymentStatus: b['payment_status'] as String? ?? '',
          checkInStatus: b['check_in_status'] as String? ?? '',
          notes: b['notes'] as String? ?? '',
          needsPickup: b['needs_pickup'] as bool? ?? false,
          needsTraining: b['needs_training'] as bool? ?? false,
          guestNames: b['guest_names'] as String? ?? '',
          languagePreference: b['language_preference'] as String? ?? '',
            lunchOrderIds: _safeJsonToList(b['lunch_order_ids'])
              .map((e) => e.toString())
              .toList(),
          ticketIds: _safeJsonToList(b['ticket_ids'])
              .map((e) => e.toString())
              .toList(),
          sales: _safeJsonToList(b['sales'])
              .map(
                (s) => SaleRecord.fromJson(
                  Map<String, dynamic>.from(s as Map),
                ),
              )
              .toList(),
          payments: _safeJsonToList(b['payments'])
              .map(
                (p) => PaymentRecord.fromJson(
                  Map<String, dynamic>.from(p as Map),
                ),
              )
              .toList(),
        );
      }).toList();

      final tickets = ticketRows
          .map(
            (t) => TicketRecord(
              id: t['id'] as String? ?? '',
              bookingId: t['booking_id'] as String? ?? '',
              bookingName: t['booking_name'] as String? ?? '',
              ticketName: t['ticket_name'] as String? ?? '',
              price: t['price'] as String? ?? '0',
              spaces: t['spaces'] as String? ?? '1',
              status: t['status'] as String? ?? 'Active',
            ),
          )
          .toList();

      final members = memberRows
          .map(
            (m) => MemberRecord(
              id: m['id'] as String? ?? '',
              firstName: m['first_name'] as String? ?? '',
              lastName: m['last_name'] as String? ?? '',
              username: m['username'] as String? ?? '',
              dateOfBirth: m['date_of_birth'] as String? ?? '',
              gender: m['gender'] as String? ?? '',
              telephone: m['telephone'] as String? ?? '',
              email: m['email'] as String? ?? '',
              membershipLevel: m['membership_level'] as String? ?? 'Regular',
              rating: (m['rating'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();

      final schedule = scheduleRows
          .map(
            (s) => ScheduleRecord(
              id: s['id'] as String? ?? '',
              time: s['time'] as String? ?? '',
              activity: s['activity'] as String? ?? '',
              location: s['location'] as String? ?? '',
              notes: s['notes'] as String? ?? '',
              gameModeTitle: s['game_mode_title'] as String? ?? '',
            ),
          )
          .toList();

      final expenses = expenseRows
          .map(
            (e) => ExpenseRecord(
              id: e['id'] as String? ?? '',
              item: e['item'] as String? ?? '',
              amount: e['amount'] as String? ?? '0',
              note: e['note'] as String? ?? '',
              date: e['date'] as String? ?? '',
              category: e['category'] as String? ?? '',
              notes: _safeJsonToList(e['notes'])
                  .map((n) => NoteRecord.fromJson(
                        Map<String, dynamic>.from(n as Map),
                      ))
                  .toList(),
            ),
          )
          .toList();

      events.add(
        EventRecord(
          id: eventId,
          name: row['name'] as String? ?? '',
          venue: row['venue'] as String? ?? '',
          date: row['date'] as String? ?? '',
          time: row['time'] as String? ?? '',
          notes: row['notes'] as String? ?? '',
          ticketCostPerPerson: row['ticket_cost_per_person'] as String? ?? '0',
          trainingTrainer: row['training_trainer'] as String? ?? '',
          lunchOptions: lunchOptions,
          fieldMapBase64: row['field_map_base64'] as String?,
          bookings: bookings,
          tickets: tickets,
          members: members,
          schedule: schedule,
          gameModes: gameModes,
          expenses: expenses,
          accountingNotes: accountingNotes,
        ),
      );
    }

    return AppStateData(events: events, activeEventId: activeEventId);
  }

  static AppStateData _mergeAppState(
    AppStateData local,
    AppStateData cloud,
  ) {
    final mergedEventsById = <String, EventRecord>{};

    for (final event in cloud.events) {
      mergedEventsById[event.id] = event;
    }

    for (final localEvent in local.events) {
      final cloudEvent = mergedEventsById[localEvent.id];
      if (cloudEvent == null) {
        mergedEventsById[localEvent.id] = localEvent;
        continue;
      }

      mergedEventsById[localEvent.id] = _mergeEvent(localEvent, cloudEvent);
    }

    final mergedEvents = mergedEventsById.values.toList();
    final activeEventId = _resolveActiveEventId(local, cloud, mergedEvents);

    return AppStateData(
      events: mergedEvents,
      activeEventId: activeEventId,
    );
  }

  static String? _resolveActiveEventId(
    AppStateData local,
    AppStateData cloud,
    List<EventRecord> mergedEvents,
  ) {
    final mergedIds = mergedEvents.map((e) => e.id).toSet();

    if (local.activeEventId != null &&
        mergedIds.contains(local.activeEventId)) {
      return local.activeEventId;
    }

    if (cloud.activeEventId != null &&
        mergedIds.contains(cloud.activeEventId)) {
      return cloud.activeEventId;
    }

    return mergedEvents.isEmpty ? null : mergedEvents.first.id;
  }

  static EventRecord _mergeEvent(EventRecord local, EventRecord cloud) {
    final name = _preferString(local.name, cloud.name);
    final venue = _preferString(local.venue, cloud.venue);
    final notes = _preferString(local.notes, cloud.notes);
    final trainingTrainer =
        _preferString(local.trainingTrainer, cloud.trainingTrainer);
    _recordConflict(
      entityType: 'event',
      entityId: local.id,
      field: 'name',
      localValue: local.name,
      cloudValue: cloud.name,
      resolvedValue: name,
    );
    _recordConflict(
      entityType: 'event',
      entityId: local.id,
      field: 'venue',
      localValue: local.venue,
      cloudValue: cloud.venue,
      resolvedValue: venue,
    );
    _recordConflict(
      entityType: 'event',
      entityId: local.id,
      field: 'notes',
      localValue: local.notes,
      cloudValue: cloud.notes,
      resolvedValue: notes,
    );
    _recordConflict(
      entityType: 'event',
      entityId: local.id,
      field: 'training_trainer',
      localValue: local.trainingTrainer,
      cloudValue: cloud.trainingTrainer,
      resolvedValue: trainingTrainer,
    );

    return EventRecord(
      id: local.id,
      name: name,
      venue: venue,
      date: _preferString(local.date, cloud.date),
      time: _preferString(local.time, cloud.time),
      notes: notes,
      ticketCostPerPerson: _preferString(
        local.ticketCostPerPerson,
        cloud.ticketCostPerPerson,
      ),
      trainingTrainer: trainingTrainer,
      lunchOptions: _mergeById(
        local.lunchOptions,
        cloud.lunchOptions,
        (x) => x.id,
        _mergeLunchOption,
      ),
      fieldMapBase64:
          _preferStringNullable(local.fieldMapBase64, cloud.fieldMapBase64),
      bookings: _mergeById(
        local.bookings,
        cloud.bookings,
        (x) => x.id,
        _mergeBooking,
      ),
      tickets: _mergeById(
        local.tickets,
        cloud.tickets,
        (x) => x.id,
        _mergeTicket,
      ),
      members: _mergeById(
        local.members,
        cloud.members,
        (x) => x.id,
        _mergeMember,
      ),
      schedule: _mergeById(
        local.schedule,
        cloud.schedule,
        (x) => x.id,
        _mergeSchedule,
      ),
      gameModes: _mergeGameModes(local.gameModes, cloud.gameModes),
      expenses: _mergeById(
        local.expenses,
        cloud.expenses,
        (x) => x.id,
        _mergeExpense,
      ),
      accountingNotes: _mergeNotes(
        local.accountingNotes,
        cloud.accountingNotes,
      ),
    );
  }

  static BookingRecord _mergeBooking(BookingRecord local, BookingRecord cloud) {
    final paymentStatus = _preferString(local.paymentStatus, cloud.paymentStatus);
    final checkInStatus = _preferString(local.checkInStatus, cloud.checkInStatus);
    final notes = _preferString(local.notes, cloud.notes);
    _recordConflict(
      entityType: 'booking',
      entityId: local.id,
      field: 'payment_status',
      localValue: local.paymentStatus,
      cloudValue: cloud.paymentStatus,
      resolvedValue: paymentStatus,
    );
    _recordConflict(
      entityType: 'booking',
      entityId: local.id,
      field: 'check_in_status',
      localValue: local.checkInStatus,
      cloudValue: cloud.checkInStatus,
      resolvedValue: checkInStatus,
    );
    _recordConflict(
      entityType: 'booking',
      entityId: local.id,
      field: 'notes',
      localValue: local.notes,
      cloudValue: cloud.notes,
      resolvedValue: notes,
    );

    return BookingRecord(
      id: local.id,
      bookingId: _preferString(local.bookingId, cloud.bookingId),
      bookingDate: _preferString(local.bookingDate, cloud.bookingDate),
      firstName: _preferString(local.firstName, cloud.firstName),
      lastName: _preferString(local.lastName, cloud.lastName),
      email: _preferString(local.email, cloud.email),
      phone: _preferString(local.phone, cloud.phone),
      event: _preferString(local.event, cloud.event),
      total: _preferString(local.total, cloud.total),
      totalPaid: _preferString(local.totalPaid, cloud.totalPaid),
      transactionId: _preferString(local.transactionId, cloud.transactionId),
      paymentMethod: _preferString(local.paymentMethod, cloud.paymentMethod),
      paymentStatus: paymentStatus,
      checkInStatus: checkInStatus,
      notes: notes,
      needsPickup: local.needsPickup || cloud.needsPickup,
      needsTraining: local.needsTraining || cloud.needsTraining,
      guestNames: _preferString(local.guestNames, cloud.guestNames),
      languagePreference: _preferString(
        local.languagePreference,
        cloud.languagePreference,
      ),
      lunchOrderIds: _mergeUniqueStrings(local.lunchOrderIds, cloud.lunchOrderIds),
      ticketIds: _mergeUniqueStrings(local.ticketIds, cloud.ticketIds),
      sales: _mergeById(local.sales, cloud.sales, (x) => x.id, _mergeSale),
      payments: _dedupePayments(
        _mergeById(
          local.payments,
          cloud.payments,
          (x) => x.id,
          _mergePayment,
        ),
      ),
    );
  }

  static TicketRecord _mergeTicket(TicketRecord local, TicketRecord cloud) {
    return TicketRecord(
      id: local.id,
      bookingId: _preferString(local.bookingId, cloud.bookingId),
      bookingName: _preferString(local.bookingName, cloud.bookingName),
      ticketName: _preferString(local.ticketName, cloud.ticketName),
      price: _preferString(local.price, cloud.price),
      spaces: _preferString(local.spaces, cloud.spaces),
      status: _preferString(local.status, cloud.status),
    );
  }

  static LunchOptionRecord _mergeLunchOption(
      LunchOptionRecord local, LunchOptionRecord cloud) {
    return LunchOptionRecord(
      id: local.id,
      name: _preferString(local.name, cloud.name),
      fee: _preferString(local.fee, cloud.fee),
    );
  }

  static MemberRecord _mergeMember(MemberRecord local, MemberRecord cloud) {
    final membershipLevel =
        _preferString(local.membershipLevel, cloud.membershipLevel);
    _recordConflict(
      entityType: 'member',
      entityId: local.id,
      field: 'membership_level',
      localValue: local.membershipLevel,
      cloudValue: cloud.membershipLevel,
      resolvedValue: membershipLevel,
    );

    return MemberRecord(
      id: local.id,
      firstName: _preferString(local.firstName, cloud.firstName),
      lastName: _preferString(local.lastName, cloud.lastName),
      username: _preferString(local.username, cloud.username),
      dateOfBirth: _preferString(local.dateOfBirth, cloud.dateOfBirth),
      gender: _preferString(local.gender, cloud.gender),
      telephone: _preferString(local.telephone, cloud.telephone),
      email: _preferString(local.email, cloud.email),
      membershipLevel: membershipLevel,
      rating: local.rating >= cloud.rating ? local.rating : cloud.rating,
    );
  }

  static ScheduleRecord _mergeSchedule(
      ScheduleRecord local, ScheduleRecord cloud) {
    return ScheduleRecord(
      id: local.id,
      time: _preferString(local.time, cloud.time),
      activity: _preferString(local.activity, cloud.activity),
      location: _preferString(local.location, cloud.location),
      notes: _preferString(local.notes, cloud.notes),
    );
  }

  static ExpenseRecord _mergeExpense(ExpenseRecord local, ExpenseRecord cloud) {
    final amount = _preferString(local.amount, cloud.amount);
    _recordConflict(
      entityType: 'expense',
      entityId: local.id,
      field: 'amount',
      localValue: local.amount,
      cloudValue: cloud.amount,
      resolvedValue: amount,
    );

    return ExpenseRecord(
      id: local.id,
      item: _preferString(local.item, cloud.item),
      amount: amount,
      note: _preferString(local.note, cloud.note),
      date: _preferString(local.date, cloud.date),
      category: _preferString(local.category, cloud.category),
      notes: _mergeNotes(local.notes, cloud.notes),
    );
  }

  static SaleRecord _mergeSale(SaleRecord local, SaleRecord cloud) {
    return SaleRecord(
      id: local.id,
      product: _preferString(local.product, cloud.product),
      price: _preferString(local.price, cloud.price),
    );
  }

  static PaymentRecord _mergePayment(PaymentRecord local, PaymentRecord cloud) {
    return PaymentRecord(
      id: local.id,
      amount: _preferString(local.amount, cloud.amount),
      method: _preferString(local.method, cloud.method),
      note: _preferString(local.note, cloud.note),
      date: _preferString(local.date, cloud.date),
    );
  }

  static List<GameModeRecord> _mergeGameModes(
    List<GameModeRecord> local,
    List<GameModeRecord> cloud,
  ) {
    final merged = <GameModeRecord>[];
    final seenSignatures = <String>{};

    for (final mode in [...cloud, ...local]) {
      final keys = mode.data.keys.toList()..sort();
      final signature = keys.map((k) => '$k=${mode.data[k] ?? ''}').join('|');
      if (seenSignatures.contains(signature)) continue;
      seenSignatures.add(signature);
      merged.add(mode);
    }

    return merged;
  }

  static List<T> _mergeById<T>(
    List<T> local,
    List<T> cloud,
    String Function(T value) idOf,
    T Function(T localValue, T cloudValue) merge,
  ) {
    final mergedById = <String, T>{};

    for (final value in cloud) {
      mergedById[idOf(value)] = value;
    }

    for (final value in local) {
      final id = idOf(value);
      final existing = mergedById[id];
      if (existing == null) {
        mergedById[id] = value;
      } else {
        mergedById[id] = merge(value, existing);
      }
    }

    return mergedById.values.toList();
  }

  static List<PaymentRecord> _dedupePayments(List<PaymentRecord> payments) {
    final deduped = <PaymentRecord>[];
    final seenExact = <String>{};
    final seenImportedSeed = <String>{};

    for (final payment in payments) {
      final method = payment.method.trim().toLowerCase();
      final note = payment.note.trim().toLowerCase();
      final amount =
          (double.tryParse(payment.amount.replaceAll(RegExp(r'[^\\d.\\-]'), '')) ??
                  0)
              .toStringAsFixed(2);
      final date = payment.date.trim();
      final exact = '$method|$note|$amount|$date';
      if (seenExact.contains(exact)) continue;

      if (note == 'imported from booking file') {
        final importedKey = 'imported|$method|$amount';
        if (seenImportedSeed.contains(importedKey)) continue;
        seenImportedSeed.add(importedKey);
      }

      seenExact.add(exact);
      deduped.add(payment);
    }

    return deduped;
  }

  static List<String> _mergeUniqueStrings(
      List<String> local, List<String> cloud) {
    final seen = <String>{};
    final merged = <String>[];
    for (final value in [...cloud, ...local]) {
      if (seen.contains(value)) continue;
      seen.add(value);
      merged.add(value);
    }
    return merged;
  }

  static String _preferString(String local, String cloud) {
    final l = local.trim();
    final c = cloud.trim();

    if (l.isEmpty && c.isEmpty) return '';
    if (l.isEmpty) return cloud;
    if (c.isEmpty) return local;

    return l.length >= c.length ? local : cloud;
  }

  static Future<void> _tryWriteSyncLog(SyncDiagnosticsRecord diagnostics) async {
    try {
      await _db.from(_tableSyncLog).insert(<String, dynamic>{
        'operation': diagnostics.operation,
        'started_at': diagnostics.startedAt,
        'completed_at': diagnostics.completedAt,
        'local_events': diagnostics.localEvents,
        'cloud_events': diagnostics.cloudEvents,
        'merged_events': diagnostics.mergedEvents,
        'conflicts': diagnostics.conflicts,
        'last_error': diagnostics.lastError,
        'last_error_code': diagnostics.lastErrorCode,
      });
    } catch (_) {
      // Keep sync resilient on schemas that do not have sync_log yet.
    }
  }

  static String? _preferStringNullable(String? local, String? cloud) {
    final l = (local ?? '').trim();
    final c = (cloud ?? '').trim();

    if (l.isEmpty && c.isEmpty) return null;
    if (l.isEmpty) return cloud;
    if (c.isEmpty) return local;

    return l.length >= c.length ? local : cloud;
  }

  /// Merge two note lists by id, preserving all unique notes from both.
  static List<NoteRecord> _mergeNotes(
    List<NoteRecord> local,
    List<NoteRecord> cloud,
  ) {
    final byId = <String, NoteRecord>{};
    for (final n in [...cloud, ...local]) {
      byId[n.id] = n;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  /// Fetch all messages, optionally filtered to an event. Ordered oldest first.
  static Future<List<MessageRecord>> fetchMessages({String? eventId}) async {
    return MessagesService.fetchMessages(eventId: eventId);
  }

  /// Send a new message to the shared messages table.
  static Future<void> sendMessage({
    required String sender,
    required String body,
    String? eventId,
  }) async {
    return MessagesService.sendMessage(
      sender: sender,
      body: body,
      eventId: eventId,
    );
  }
}
