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
  String? fieldMapBase64;
  List<BookingRecord> bookings;
  List<TicketRecord> tickets;
  List<MemberRecord> members;
  List<ScheduleRecord> schedule;
  List<GameModeRecord> gameModes;
  List<ExpenseRecord> expenses;

  EventRecord({
    required this.id,
    required this.name,
    required this.venue,
    required this.date,
    required this.time,
    required this.notes,
    required this.ticketCostPerPerson,
    required this.fieldMapBase64,
    required this.bookings,
    required this.tickets,
    required this.members,
    required this.schedule,
    required this.gameModes,
    required this.expenses,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'venue': venue,
        'date': date,
        'time': time,
        'notes': notes,
        'ticketCostPerPerson': ticketCostPerPerson,
        'fieldMapBase64': fieldMapBase64,
        'bookings': bookings.map((e) => e.toJson()).toList(),
        'tickets': tickets.map((e) => e.toJson()).toList(),
        'members': members.map((e) => e.toJson()).toList(),
        'schedule': schedule.map((e) => e.toJson()).toList(),
        'gameModes': gameModes.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
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
      total: json['total']?.toString() ?? '',
      totalPaid: json['totalPaid']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      checkInStatus: json['checkInStatus']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      needsPickup: json['needsPickup'] == true,
      needsTraining: json['needsTraining'] == true,
      guestNames: json['guestNames']?.toString() ?? '',
      languagePreference: json['languagePreference']?.toString() ?? '',
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

class ExpenseRecord {
  String id;
  String item;
  String amount;
  String note;
  String date;
  String category;

  ExpenseRecord({
    required this.id,
    required this.item,
    required this.amount,
    required this.note,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item,
        'amount': amount,
        'note': note,
        'date': date,
        'category': category,
      };

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['id']?.toString() ?? '',
      item: json['item']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
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
}
