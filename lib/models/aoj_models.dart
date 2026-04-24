import 'package:flutter/material.dart';

class DesktopAppItem {
  final String id;
  final String title;
  final IconData icon;
  final Color accent;
  final String subtitle;

  const DesktopAppItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.subtitle,
  });
}

class DesktopWindowData {
  final String id;
  String title;
  final IconData icon;
  final Color accent;
  bool isOpen;
  bool isMinimized;
  bool isMaximized;
  Offset position;
  Size size;
  Offset restorePosition;
  Size restoreSize;
  int zIndex;

  DesktopWindowData({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.isOpen,
    required this.isMinimized,
    required this.isMaximized,
    required this.position,
    required this.size,
    required this.restorePosition,
    required this.restoreSize,
    required this.zIndex,
  });
}

class AppStateData {
  List<EventRecord> events;
  String? activeEventId;

  AppStateData({
    required this.events,
    required this.activeEventId,
  });

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
        'activeEventId': activeEventId,
      };

  factory AppStateData.fromJson(Map<String, dynamic> json) {
    return AppStateData(
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => EventRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      activeEventId: json['activeEventId']?.toString(),
    );
  }
}

class EventRecord {
  String id;
  String name;
  String venue;
  String date;
  String time;
  String notes;
  String ticketCostPerPerson;
  String trainingTrainer;
  List<LunchOptionRecord> lunchOptions;
  String? fieldMapBase64;
  List<BookingRecord> bookings;
  List<TicketRecord> tickets;
  List<MemberRecord> members;
  List<ScheduleRecord> schedule;
  List<GameModeRecord> gameModes;
  List<ExpenseRecord> expenses;
  List<NoteRecord> accountingNotes;

  EventRecord({
    required this.id,
    required this.name,
    required this.venue,
    required this.date,
    required this.time,
    required this.notes,
    required this.ticketCostPerPerson,
    required this.trainingTrainer,
    required this.lunchOptions,
    required this.fieldMapBase64,
    required this.bookings,
    required this.tickets,
    required this.members,
    required this.schedule,
    required this.gameModes,
    required this.expenses,
    List<NoteRecord>? accountingNotes,
  }) : accountingNotes = accountingNotes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'venue': venue,
        'date': date,
        'time': time,
        'notes': notes,
        'ticketCostPerPerson': ticketCostPerPerson,
        'trainingTrainer': trainingTrainer,
        'lunchOptions': lunchOptions.map((e) => e.toJson()).toList(),
        'fieldMapBase64': fieldMapBase64,
        'bookings': bookings.map((e) => e.toJson()).toList(),
        'tickets': tickets.map((e) => e.toJson()).toList(),
        'members': members.map((e) => e.toJson()).toList(),
        'schedule': schedule.map((e) => e.toJson()).toList(),
        'gameModes': gameModes.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'accountingNotes': accountingNotes.map((e) => e.toJson()).toList(),
      };

  factory EventRecord.fromJson(Map<String, dynamic> json) {
    return EventRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      ticketCostPerPerson: json['ticketCostPerPerson']?.toString() ?? '0',
      trainingTrainer: json['trainingTrainer']?.toString() ?? '',
        lunchOptions: (json['lunchOptions'] as List<dynamic>? ?? [])
          .map((e) => LunchOptionRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      fieldMapBase64: json['fieldMapBase64']?.toString(),
      bookings: (json['bookings'] as List<dynamic>? ?? [])
          .map((e) => BookingRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((e) => TicketRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) => MemberRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      schedule: (json['schedule'] as List<dynamic>? ?? [])
          .map((e) => ScheduleRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      gameModes: (json['gameModes'] as List<dynamic>? ?? [])
          .map((e) => GameModeRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => ExpenseRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      accountingNotes: (json['accountingNotes'] as List<dynamic>? ?? [])
          .map((e) => NoteRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BookingRecord {
  String id;
  String bookingId;
  String bookingDate;
  String firstName;
  String lastName;
  String email;
  String phone;
  String event;
  String total;
  String totalPaid;
  String transactionId;
  String paymentMethod;
  String paymentStatus;
  String checkInStatus;
  String notes;
  bool needsPickup;
  bool needsTraining;
  String guestNames;
  String languagePreference;
  List<String> lunchOrderIds;
  List<String> ticketIds;
  List<SaleRecord> sales;
  List<PaymentRecord> payments;

  BookingRecord({
    required this.id,
    required this.bookingId,
    required this.bookingDate,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.event,
    required this.total,
    required this.totalPaid,
    required this.transactionId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.checkInStatus,
    required this.notes,
    required this.needsPickup,
    required this.needsTraining,
    required this.guestNames,
    required this.languagePreference,
    required this.lunchOrderIds,
    required this.ticketIds,
    required this.sales,
    required this.payments,
  });

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'bookingDate': bookingDate,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'event': event,
        'total': total,
        'totalPaid': totalPaid,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'checkInStatus': checkInStatus,
        'notes': notes,
        'needsPickup': needsPickup,
        'needsTraining': needsTraining,
        'guestNames': guestNames,
        'languagePreference': languagePreference,
        'lunchOrderIds': lunchOrderIds,
        'ticketIds': ticketIds,
        'sales': sales.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
      };

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    return BookingRecord(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      bookingDate: json['bookingDate']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      total: json['total']?.toString() ?? '0',
      totalPaid: json['totalPaid']?.toString() ?? '0',
      transactionId: json['transactionId']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      checkInStatus: json['checkInStatus']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      needsPickup: json['needsPickup'] == true,
      needsTraining: json['needsTraining'] == true,
      guestNames: json['guestNames']?.toString() ?? '',
      languagePreference: json['languagePreference']?.toString() ?? '',
        lunchOrderIds: (json['lunchOrderIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      ticketIds: (json['ticketIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      sales: (json['sales'] as List<dynamic>? ?? [])
          .map((e) => SaleRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class TicketRecord {
  String id;
  String bookingId;
  String bookingName;
  String ticketName;
  String price;
  String spaces;
  String status;

  TicketRecord({
    required this.id,
    required this.bookingId,
    required this.bookingName,
    required this.ticketName,
    required this.price,
    required this.spaces,
    required this.status,
  });

  int get quantity {
    final cleaned = spaces.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? 1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'bookingName': bookingName,
        'ticketName': ticketName,
        'price': price,
        'spaces': spaces,
        'status': status,
      };

  factory TicketRecord.fromJson(Map<String, dynamic> json) {
    return TicketRecord(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      bookingName: json['bookingName']?.toString() ?? '',
      ticketName: json['ticketName']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      spaces: json['spaces']?.toString() ??
          json['quantity']?.toString() ??
          '1',
      status: json['status']?.toString() ?? 'Active',
    );
  }
}

class SaleRecord {
  String id;
  String product;
  String price;

  SaleRecord({
    required this.id,
    required this.product,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product,
        'price': price,
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id']?.toString() ?? '',
      product: json['product']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
    );
  }
}

class PaymentRecord {
  String id;
  String amount;
  String method;
  String note;
  String date;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.method,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'method': method,
        'note': note,
        'date': date,
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      method: json['method']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

class ExpenseRecord {
  String id;
  String item;
  String amount;
  String note;
  String date;
  String category;
  List<NoteRecord> notes;

  ExpenseRecord({
    required this.id,
    required this.item,
    required this.amount,
    required this.note,
    required this.date,
    required this.category,
    List<NoteRecord>? notes,
  }) : notes = notes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item,
        'amount': amount,
        'note': note,
        'date': date,
        'category': category,
        'notes': notes.map((n) => n.toJson()).toList(),
      };

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['id']?.toString() ?? '',
      item: json['item']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      note: json['note']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => NoteRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class MemberRecord {
  String id;
  String firstName;
  String lastName;
  String username;
  String dateOfBirth;
  String gender;
  String telephone;
  String email;
  String membershipLevel;
  int rating;

  MemberRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.dateOfBirth,
    required this.gender,
    required this.telephone,
    required this.email,
    required this.membershipLevel,
    this.rating = 0,
  });

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'telephone': telephone,
        'email': email,
        'membershipLevel': membershipLevel,
        'rating': rating,
      };

  factory MemberRecord.fromJson(Map<String, dynamic> json) {
    return MemberRecord(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      membershipLevel: json['membershipLevel']?.toString() ?? 'Regular',
      rating: _parseInt(json['rating'], fallback: 0),
    );
  }
}

class ScheduleRecord {
  String id;
  String time;
  String activity;
  String location;
  String notes;

  ScheduleRecord({
    required this.id,
    required this.time,
    required this.activity,
    required this.location,
    required this.notes,
  });

  Map<String, String> get data => {
        'ID': id,
        'Time': time,
        'Activity': activity,
        'Location': location,
        'Notes': notes,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'activity': activity,
        'location': location,
        'notes': notes,
      };

  factory ScheduleRecord.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data')) {
      final data = Map<String, String>.from(json['data'] as Map? ?? {});
      return ScheduleRecord(
        id: data['ID']?.toString() ?? '',
        time: data['Time']?.toString() ?? '',
        activity: data['Activity']?.toString() ?? '',
        location: data['Location']?.toString() ?? '',
        notes: data['Notes']?.toString() ?? '',
      );
    }

    return ScheduleRecord(
      id: json['id']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class GameModeRecord {
  Map<String, String> data;

  GameModeRecord({
    required this.data,
  });

  String get title {
    return data['Name']?.trim().isNotEmpty == true
        ? data['Name']!.trim()
        : data['Title']?.trim().isNotEmpty == true
            ? data['Title']!.trim()
            : data['Game Mode']?.trim().isNotEmpty == true
                ? data['Game Mode']!.trim()
                : 'Unnamed Game Mode';
  }

  String get description {
    return data['Description']?.trim() ??
        data['Notes']?.trim() ??
        data['Objective']?.trim() ??
        '';
  }

  Map<String, dynamic> toJson() => {'data': data};

  factory GameModeRecord.fromJson(Map<String, dynamic> json) {
    return GameModeRecord(
      data: Map<String, String>.from(json['data'] as Map? ?? {}),
    );
  }
}

class LunchOptionRecord {
  String id;
  String name;
  String fee;

  LunchOptionRecord({
    required this.id,
    required this.name,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fee': fee,
      };

  factory LunchOptionRecord.fromJson(Map<String, dynamic> json) {
    return LunchOptionRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fee: json['fee']?.toString() ?? '0',
    );
  }
}

class BookingGroup {
  final String key;
  final BookingRecord primary;
  final List<BookingRecord> rows;
  final List<TicketRecord> tickets;

  BookingGroup({
    required this.key,
    required this.primary,
    required this.rows,
    required this.tickets,
  });

  String get displayName {
    final name = primary.fullName.trim();
    if (name.isNotEmpty) return name;
    if (primary.email.trim().isNotEmpty) return primary.email.trim();
    return 'Unnamed Booking';
  }

  String get bookingId => primary.bookingId.trim();
  String get email => primary.email.trim();
  String get phone => primary.phone.trim();
  bool get needsPickup => rows.any((r) => r.needsPickup);
  bool get needsTraining => rows.any((r) => r.needsTraining);

  String get guestNames {
    final values = <String>{};
    for (final row in rows) {
      for (final guest in row.guestNames.split(RegExp(r'[\n;,]+'))) {
        final cleaned = guest.trim();
        if (cleaned.isNotEmpty) values.add(cleaned);
      }
    }
    return values.join(', ');
  }

  String get languagePreference {
    for (final row in rows) {
      if (row.languagePreference.trim().isNotEmpty) {
        return row.languagePreference.trim();
      }
    }
    return '';
  }
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

// ── NoteRecord ────────────────────────────────────────────────────────────────
/// A timestamped note authored by a named device user.
class NoteRecord {
  String id;
  String author;
  String body;
  String createdAt;

  NoteRecord({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'body': body,
        'createdAt': createdAt,
      };

  factory NoteRecord.fromJson(Map<String, dynamic> json) => NoteRecord(
        id: json['id']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

// ── MessageRecord ─────────────────────────────────────────────────────────────
/// A cross-device message sent via the shared messages table.
class MessageRecord {
  String id;
  String sender;
  String body;
  String createdAt;
  String? eventId;

  MessageRecord({
    required this.id,
    required this.sender,
    required this.body,
    required this.createdAt,
    this.eventId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'body': body,
        'createdAt': createdAt,
        if (eventId != null) 'eventId': eventId,
      };

  factory MessageRecord.fromJson(Map<String, dynamic> json) => MessageRecord(
        id: json['id']?.toString() ?? '',
        sender: json['sender']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        eventId: json['eventId']?.toString(),
      );
}

class MergeConflictRecord {
  String entityType;
  String entityId;
  String field;
  String localValue;
  String cloudValue;
  String resolvedValue;
  String detectedAt;

  MergeConflictRecord({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.localValue,
    required this.cloudValue,
    required this.resolvedValue,
    required this.detectedAt,
  });
}

class SyncDiagnosticsRecord {
  String operation;
  String startedAt;
  String completedAt;
  int localEvents;
  int cloudEvents;
  int mergedEvents;
  int conflicts;
  String lastError;
  String lastErrorCode;

  SyncDiagnosticsRecord({
    required this.operation,
    required this.startedAt,
    required this.completedAt,
    required this.localEvents,
    required this.cloudEvents,
    required this.mergedEvents,
    required this.conflicts,
    required this.lastError,
    required this.lastErrorCode,
  });

  factory SyncDiagnosticsRecord.empty() => SyncDiagnosticsRecord(
        operation: 'idle',
        startedAt: '',
        completedAt: '',
        localEvents: 0,
        cloudEvents: 0,
        mergedEvents: 0,
        conflicts: 0,
        lastError: '',
        lastErrorCode: '',
      );
}

class SchemaHealthRecord {
  bool healthy;
  String expectedVersion;
  String actualVersion;
  String checkedAt;
  List<String> issues;

  SchemaHealthRecord({
    required this.healthy,
    required this.expectedVersion,
    required this.actualVersion,
    required this.checkedAt,
    required this.issues,
  });

  factory SchemaHealthRecord.unchecked({required String expectedVersion}) =>
      SchemaHealthRecord(
        healthy: false,
        expectedVersion: expectedVersion,
        actualVersion: '',
        checkedAt: '',
        issues: <String>['Not checked yet'],
      );
}
