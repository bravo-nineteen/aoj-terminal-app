import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aoj_models.dart';

const String _kFallbackSupabaseUrl = 'https://uvixlrhcjojezhqmgnxk.supabase.co';
const String _kFallbackSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2aXhscmhjam9qZXpocW1nbnhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMzY5NzIsImV4cCI6MjA5MTkxMjk3Mn0'
    '.1ychTDnuRxtOFY9SquXtg8RkzX0UxvyXENU1ncAaFO4';

class SupabaseService {
  static String? _resolvedSupabaseUrl;

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

    // Support accidentally pasting the full define segment.
    final defineMatch = RegExp(r'(?i)supabase_url\s*=\s*([^\s]+)')
        .firstMatch(value);
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

  static Future<void> initialize() async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final resolvedUrl = _normalizeSupabaseUrl(
      envUrl.isNotEmpty ? envUrl : _kFallbackSupabaseUrl,
    );
    _resolvedSupabaseUrl = resolvedUrl;

    final resolvedAnonKey =
        envAnonKey.isNotEmpty ? envAnonKey : _kFallbackSupabaseAnonKey;

    await Supabase.initialize(
      url: resolvedUrl,
      anonKey: resolvedAnonKey,
    );
  }

  static SupabaseClient get _db => Supabase.instance.client;

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
          },
        )
        .toList();

    if (eventRows.isNotEmpty) {
      await db.from('events').upsert(eventRows);
    }

    // ── Save active event id ─────────────────────────────────────────────────
    await db.from('app_config').upsert(<String, dynamic>{
      'key': 'active_event_id',
      'value': appState.activeEventId ?? '',
    });

    // ── Per-event sub-tables ─────────────────────────────────────────────────
    for (final event in appState.events) {
      await _pushBookings(db, event);
      await _pushTickets(db, event);
      await _pushMembers(db, event);
      await _pushSchedule(db, event);
      await _pushExpenses(db, event);
    }
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
      await db.from('bookings').upsert(rows);
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
      await db.from('tickets').upsert(rows);
    }
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
      await db.from('members').upsert(rows);
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
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from('schedule').upsert(rows);
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
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from('expenses').upsert(rows);
    }
  }

  /// Pulls, merges, and pushes so each device converges to one merged state.
  static Future<AppStateData> syncMergeAppState(AppStateData localState) async {
    final cloudState = await _withHostLookupRetry(() => pullAppState());
    final merged = _mergeAppState(localState, cloudState);
    await _withHostLookupRetry(() => pushAppState(merged));
    return merged;
  }

  // ─── Pull ─────────────────────────────────────────────────────────────────

  /// Pulls the full app state from Supabase and returns an [AppStateData].
  static Future<AppStateData> pullAppState() async {
    final db = _db;

    // Active event id
    final configRow = await db
        .from('app_config')
        .select()
        .eq('key', 'active_event_id')
        .maybeSingle();
    final rawActiveId = configRow?['value'] as String?;
    final activeEventId =
        (rawActiveId == null || rawActiveId.isEmpty) ? null : rawActiveId;

    // Events
    final List<Map<String, dynamic>> eventRows =
        List<Map<String, dynamic>>.from(
      await db.from('events').select(),
    );

    final events = <EventRecord>[];

    for (final row in eventRows) {
      final eventId = row['id'] as String;

      final List<Map<String, dynamic>> bookingRows =
          List<Map<String, dynamic>>.from(
        await db.from('bookings').select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> ticketRows =
          List<Map<String, dynamic>>.from(
        await db.from('tickets').select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> memberRows =
          List<Map<String, dynamic>>.from(
        await db.from('members').select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> scheduleRows =
          List<Map<String, dynamic>>.from(
        await db.from('schedule').select().eq('event_id', eventId),
      );
      final List<Map<String, dynamic>> expenseRows =
          List<Map<String, dynamic>>.from(
        await db.from('expenses').select().eq('event_id', eventId),
      );

      final gameModes = (row['game_modes'] as List<dynamic>? ?? [])
          .map(
            (g) => GameModeRecord.fromJson(Map<String, dynamic>.from(g as Map)),
          )
          .toList();

      final lunchOptions = (row['lunch_options'] as List<dynamic>? ?? [])
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
            lunchOrderIds: (b['lunch_order_ids'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
          ticketIds: (b['ticket_ids'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
          sales: (b['sales'] as List<dynamic>? ?? [])
              .map(
                (s) => SaleRecord.fromJson(
                  Map<String, dynamic>.from(s as Map),
                ),
              )
              .toList(),
          payments: (b['payments'] as List<dynamic>? ?? [])
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
    return EventRecord(
      id: local.id,
      name: _preferString(local.name, cloud.name),
      venue: _preferString(local.venue, cloud.venue),
      date: _preferString(local.date, cloud.date),
      time: _preferString(local.time, cloud.time),
      notes: _preferString(local.notes, cloud.notes),
      ticketCostPerPerson: _preferString(
        local.ticketCostPerPerson,
        cloud.ticketCostPerPerson,
      ),
      trainingTrainer:
          _preferString(local.trainingTrainer, cloud.trainingTrainer),
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
    );
  }

  static BookingRecord _mergeBooking(BookingRecord local, BookingRecord cloud) {
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
      paymentStatus: _preferString(local.paymentStatus, cloud.paymentStatus),
      checkInStatus: _preferString(local.checkInStatus, cloud.checkInStatus),
      notes: _preferString(local.notes, cloud.notes),
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
      payments: _mergeById(
        local.payments,
        cloud.payments,
        (x) => x.id,
        _mergePayment,
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
    return MemberRecord(
      id: local.id,
      firstName: _preferString(local.firstName, cloud.firstName),
      lastName: _preferString(local.lastName, cloud.lastName),
      username: _preferString(local.username, cloud.username),
      dateOfBirth: _preferString(local.dateOfBirth, cloud.dateOfBirth),
      gender: _preferString(local.gender, cloud.gender),
      telephone: _preferString(local.telephone, cloud.telephone),
      email: _preferString(local.email, cloud.email),
      membershipLevel:
          _preferString(local.membershipLevel, cloud.membershipLevel),
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
    return ExpenseRecord(
      id: local.id,
      item: _preferString(local.item, cloud.item),
      amount: _preferString(local.amount, cloud.amount),
      note: _preferString(local.note, cloud.note),
      date: _preferString(local.date, cloud.date),
      category: _preferString(local.category, cloud.category),
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

  static String? _preferStringNullable(String? local, String? cloud) {
    final l = (local ?? '').trim();
    final c = (cloud ?? '').trim();

    if (l.isEmpty && c.isEmpty) return null;
    if (l.isEmpty) return cloud;
    if (c.isEmpty) return local;

    return l.length >= c.length ? local : cloud;
  }
}
