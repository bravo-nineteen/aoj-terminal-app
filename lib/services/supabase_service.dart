import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aoj_models.dart';

/// Supabase project credentials.
const String _kSupabaseUrl = 'https://uvixlrhcjojezhqmgnxk.supabase.co';
const String _kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2aXhscmhjam9qZXpocW1nbnhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMzY5NzIsImV4cCI6MjA5MTkxMjk3Mn0'
    '.1ychTDnuRxtOFY9SquXtg8RkzX0UxvyXENU1ncAaFO4';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _kSupabaseUrl,
      anonKey: _kSupabaseAnonKey,
    );
  }

  static SupabaseClient get _db => Supabase.instance.client;

  // ─── Push ─────────────────────────────────────────────────────────────────

  /// Pushes the full local app state to Supabase, upsert-then-prune.
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
            'field_map_base64': e.fieldMapBase64,
            'game_modes': e.gameModes.map((g) => g.toJson()).toList(),
          },
        )
        .toList();

    if (eventRows.isNotEmpty) {
      await db.from('events').upsert(eventRows);
    }

    // Prune deleted events
    final eventIds = appState.events.map((e) => e.id).toList();
    if (eventIds.isEmpty) {
      await db.from('events').delete().neq('id', '');
    } else {
      await db
          .from('events')
          .delete()
          .not('id', 'in', '(${eventIds.join(',')})');
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
            'ticket_ids': b.ticketIds,
            'sales': b.sales.map((s) => s.toJson()).toList(),
            'payments': b.payments.map((p) => p.toJson()).toList(),
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await db.from('bookings').upsert(rows);
    }

    final ids = event.bookings.map((b) => b.id).toList();
    if (ids.isEmpty) {
      await db.from('bookings').delete().eq('event_id', event.id);
    } else {
      await db
          .from('bookings')
          .delete()
          .eq('event_id', event.id)
          .not('id', 'in', '(${ids.join(',')})');
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

    final ids = event.tickets.map((t) => t.id).toList();
    if (ids.isEmpty) {
      await db.from('tickets').delete().eq('event_id', event.id);
    } else {
      await db
          .from('tickets')
          .delete()
          .eq('event_id', event.id)
          .not('id', 'in', '(${ids.join(',')})');
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

    final ids = event.members.map((m) => m.id).toList();
    if (ids.isEmpty) {
      await db.from('members').delete().eq('event_id', event.id);
    } else {
      await db
          .from('members')
          .delete()
          .eq('event_id', event.id)
          .not('id', 'in', '(${ids.join(',')})');
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

    final ids = event.schedule.map((s) => s.id).toList();
    if (ids.isEmpty) {
      await db.from('schedule').delete().eq('event_id', event.id);
    } else {
      await db
          .from('schedule')
          .delete()
          .eq('event_id', event.id)
          .not('id', 'in', '(${ids.join(',')})');
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

    final ids = event.expenses.map((e) => e.id).toList();
    if (ids.isEmpty) {
      await db.from('expenses').delete().eq('event_id', event.id);
    } else {
      await db
          .from('expenses')
          .delete()
          .eq('event_id', event.id)
          .not('id', 'in', '(${ids.join(',')})');
    }
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
              membershipLevel:
                  m['membership_level'] as String? ?? 'Regular',
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
          ticketCostPerPerson:
              row['ticket_cost_per_person'] as String? ?? '0',
          trainingTrainer: row['training_trainer'] as String? ?? '',
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
}
