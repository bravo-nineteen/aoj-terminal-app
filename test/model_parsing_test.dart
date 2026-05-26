// Tests that verify robust JSON / Supabase-response parsing in aoj_models.dart.
//
// The primary regression being guarded is the runtime cast error:
//   "String is not a subtype of Map<dynamic, dynamic>"
//
// This happens when a Supabase JSONB column (or a local-storage field) is
// returned / stored as a JSON-encoded *String* rather than an already-decoded
// *Map*.  The _safeToMap() helper and the updated fromJson() factories must
// survive both representations without throwing.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:aoj_terminal_app/models/aoj_models.dart';

void main() {
  // ── AppStateData ────────────────────────────────────────────────────────────

  group('AppStateData.fromJson', () {
    test('parses events that are already Map objects', () {
      final json = {
        'events': [
          {
            'id': 'e1',
            'name': 'Test Event',
            'venue': '',
            'date': '',
            'time': '',
            'notes': '',
            'ticketCostPerPerson': '0',
            'ticketCostType': 'perPerson',
            'ticketCountOverride': '',
            'trainingTrainer': '',
            'lunchOptions': [],
            'bookings': [],
            'tickets': [],
            'members': [],
            'schedule': [],
            'gameModes': [],
            'expenses': [],
            'accountingNotes': [],
          }
        ],
        'activeEventId': 'e1',
      };

      final state = AppStateData.fromJson(json);
      expect(state.events.length, 1);
      expect(state.events.first.id, 'e1');
    });

    test('does not throw when an event entry is a JSON-encoded string', () {
      final eventMap = {
        'id': 'e2',
        'name': 'Encoded Event',
        'venue': '',
        'date': '',
        'time': '',
        'notes': '',
        'ticketCostPerPerson': '0',
        'ticketCostType': 'perPerson',
        'ticketCountOverride': '',
        'trainingTrainer': '',
        'lunchOptions': [],
        'bookings': [],
        'tickets': [],
        'members': [],
        'schedule': [],
        'gameModes': [],
        'expenses': [],
        'accountingNotes': [],
      };

      // Simulate double-encoding: event stored as a JSON string instead of a Map.
      final json = {
        'events': [jsonEncode(eventMap)],
        'activeEventId': null,
      };

      final state = AppStateData.fromJson(json);
      expect(state.events.length, 1);
      expect(state.events.first.id, 'e2');
      expect(state.events.first.name, 'Encoded Event');
    });
  });

  // ── EventRecord ─────────────────────────────────────────────────────────────

  group('EventRecord.fromJson', () {
    test('parses lunchOptions when items are already Maps', () {
      final json = {
        'id': 'e1',
        'name': '',
        'venue': '',
        'date': '',
        'time': '',
        'notes': '',
        'ticketCostPerPerson': '0',
        'ticketCostType': 'perPerson',
        'ticketCountOverride': '',
        'trainingTrainer': '',
        'lunchOptions': [
          {'id': 'lo1', 'name': 'Vegan', 'fee': '5'},
        ],
        'bookings': [],
        'tickets': [],
        'members': [],
        'schedule': [],
        'gameModes': [],
        'expenses': [],
        'accountingNotes': [],
      };
      final record = EventRecord.fromJson(json);
      expect(record.lunchOptions.length, 1);
      expect(record.lunchOptions.first.name, 'Vegan');
    });

    test('parses lunchOptions when items are JSON-encoded strings', () {
      final json = {
        'id': 'e1',
        'name': '',
        'venue': '',
        'date': '',
        'time': '',
        'notes': '',
        'ticketCostPerPerson': '0',
        'ticketCostType': 'perPerson',
        'ticketCountOverride': '',
        'trainingTrainer': '',
        'lunchOptions': [
          jsonEncode({'id': 'lo2', 'name': 'Standard', 'fee': '0'}),
        ],
        'bookings': [],
        'tickets': [],
        'members': [],
        'schedule': [],
        'gameModes': [],
        'expenses': [],
        'accountingNotes': [],
      };
      final record = EventRecord.fromJson(json);
      expect(record.lunchOptions.length, 1);
      expect(record.lunchOptions.first.name, 'Standard');
    });

    test('parses accountingNotes when items are JSON-encoded strings', () {
      final json = {
        'id': 'e1',
        'name': '',
        'venue': '',
        'date': '',
        'time': '',
        'notes': '',
        'ticketCostPerPerson': '0',
        'ticketCostType': 'perPerson',
        'ticketCountOverride': '',
        'trainingTrainer': '',
        'lunchOptions': [],
        'bookings': [],
        'tickets': [],
        'members': [],
        'schedule': [],
        'gameModes': [],
        'expenses': [],
        'accountingNotes': [
          jsonEncode({
            'id': 'n1',
            'author': 'Alice',
            'body': 'Hello',
            'createdAt': '2024-01-01'
          }),
        ],
      };
      final record = EventRecord.fromJson(json);
      expect(record.accountingNotes.length, 1);
      expect(record.accountingNotes.first.author, 'Alice');
    });
  });

  // ── BookingRecord ───────────────────────────────────────────────────────────

  group('BookingRecord.fromJson', () {
    Map<String, dynamic> baseBooking() => {
          'id': 'b1',
          'bookingId': 'BK001',
          'bookingDate': '2024-01-01',
          'firstName': 'Jane',
          'lastName': 'Doe',
          'email': 'jane@example.com',
          'phone': '',
          'event': 'e1',
          'total': '100',
          'totalPaid': '50',
          'transactionId': '',
          'paymentMethod': '',
          'paymentStatus': '',
          'checkInStatus': '',
          'notes': '',
          'needsPickup': false,
          'needsTraining': false,
          'guestNames': '',
          'languagePreference': '',
          'lunchOrderIds': [],
          'ticketIds': [],
          'sales': [],
          'payments': [],
        };

    test('parses sales when items are already Maps', () {
      final json = baseBooking()
        ..['sales'] = [
          {'id': 's1', 'product': 'Widget', 'price': '10'},
        ];
      final booking = BookingRecord.fromJson(json);
      expect(booking.sales.length, 1);
      expect(booking.sales.first.product, 'Widget');
    });

    test('does not throw when sales items are JSON-encoded strings', () {
      final json = baseBooking()
        ..['sales'] = [
          jsonEncode({'id': 's2', 'product': 'Gadget', 'price': '20'}),
        ];
      final booking = BookingRecord.fromJson(json);
      expect(booking.sales.length, 1);
      expect(booking.sales.first.product, 'Gadget');
    });

    test('does not throw when payments items are JSON-encoded strings', () {
      final json = baseBooking()
        ..['payments'] = [
          jsonEncode({
            'id': 'p1',
            'amount': '50',
            'method': 'cash',
            'note': '',
            'date': '2024-01-01'
          }),
        ];
      final booking = BookingRecord.fromJson(json);
      expect(booking.payments.length, 1);
      expect(booking.payments.first.method, 'cash');
    });
  });

  // ── ExpenseRecord ───────────────────────────────────────────────────────────

  group('ExpenseRecord.fromJson', () {
    test('does not throw when notes items are JSON-encoded strings', () {
      final json = {
        'id': 'exp1',
        'item': 'Catering',
        'amount': '200',
        'note': '',
        'date': '2024-01-01',
        'category': 'Food',
        'notes': [
          jsonEncode({
            'id': 'n1',
            'author': 'Bob',
            'body': 'Paid in full',
            'createdAt': '2024-01-02'
          }),
        ],
      };
      final expense = ExpenseRecord.fromJson(json);
      expect(expense.notes.length, 1);
      expect(expense.notes.first.body, 'Paid in full');
    });
  });

  // ── GameModeRecord ──────────────────────────────────────────────────────────

  group('GameModeRecord.fromJson', () {
    test('parses data when it is already a Map', () {
      final json = {
        'data': {'Name': 'Capture the Flag', 'Duration': '30 min'},
        'updatedAt': '',
      };
      final gm = GameModeRecord.fromJson(json);
      expect(gm.title, 'Capture the Flag');
    });

    test('does not throw when data is a JSON-encoded string', () {
      final json = {
        'data': jsonEncode({'Name': 'Team Deathmatch', 'Duration': '20 min'}),
        'updatedAt': '',
      };
      final gm = GameModeRecord.fromJson(json);
      expect(gm.title, 'Team Deathmatch');
    });

    test('returns empty data gracefully when data is null', () {
      final json = <String, dynamic>{'data': null, 'updatedAt': ''};
      final gm = GameModeRecord.fromJson(json);
      expect(gm.data, isEmpty);
    });
  });

  // ── ScheduleRecord ──────────────────────────────────────────────────────────

  group('ScheduleRecord.fromJson (data-keyed path)', () {
    test('parses data when it is already a Map', () {
      final json = {
        'data': {
          'ID': 's1',
          'Time': '09:00',
          'Activity': 'Opening',
          'Location': 'Hall A',
          'Notes': '',
          'GameModeTitle': '',
        },
        'updatedAt': '',
      };
      final s = ScheduleRecord.fromJson(json);
      expect(s.id, 's1');
      expect(s.activity, 'Opening');
    });

    test('does not throw when data is a JSON-encoded string', () {
      final json = {
        'data': jsonEncode({
          'ID': 's2',
          'Time': '10:00',
          'Activity': 'Briefing',
          'Location': 'Hall B',
          'Notes': '',
          'GameModeTitle': 'CTF',
        }),
        'updatedAt': '',
      };
      final s = ScheduleRecord.fromJson(json);
      expect(s.id, 's2');
      expect(s.gameModeTitle, 'CTF');
    });
  });
}
