import 'package:flutter/material.dart';

/// =========================
/// BASIC UI MODELS
/// =========================

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

/// =========================
/// APP STATE
/// =========================

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
      events: (json['events'] as List? ?? [])
          .map((e) => EventRecord.fromJson(e))
          .toList(),
      activeEventId: json['activeEventId'],
    );
  }
}

/// =========================
/// CORE EVENT
/// =========================

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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      venue: json['venue'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      notes: json['notes'] ?? '',
      ticketCostPerPerson: json['ticketCostPerPerson'] ?? '0',
      fieldMapBase64: json['fieldMapBase64'],
      bookings: (json['bookings'] as List? ?? [])
          .map((e) => BookingRecord.fromJson(e))
          .toList(),
      tickets: (json['tickets'] as List? ?? [])
          .map((e) => TicketRecord.fromJson(e))
          .toList(),
      members: (json['members'] as List? ?? [])
          .map((e) => MemberRecord.fromJson(e))
          .toList(),
      schedule: (json['schedule'] as List? ?? [])
          .map((e) => ScheduleRecord.fromJson(e))
          .toList(),
      gameModes: (json['gameModes'] as List? ?? [])
          .map((e) => GameModeRecord.fromJson(e))
          .toList(),
      expenses: (json['expenses'] as List? ?? [])
          .map((e) => ExpenseRecord.fromJson(e))
          .toList(),
    );
  }
}

/// =========================
/// CORE RECORDS
/// =========================

class TicketRecord {
  String id;
  String bookingId;
  String bookingName;
  String ticketName;
  String price;
  int quantity;
  String status;

  TicketRecord({
    required this.id,
    required this.bookingId,
    required this.bookingName,
    required this.ticketName,
    required this.price,
    required this.quantity,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'bookingName': bookingName,
        'ticketName': ticketName,
        'price': price,
        'quantity': quantity,
        'status': status,
      };

  factory TicketRecord.fromJson(Map<String, dynamic> json) {
    return TicketRecord(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      bookingName: json['bookingName'] ?? '',
      ticketName: json['ticketName'] ?? '',
      price: json['price'] ?? '0',
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'Active',
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
    required this.rating,
  });

  String get fullName => '$firstName $lastName'.trim();

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
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      membershipLevel: json['membershipLevel'] ?? '',
      rating: json['rating'] ?? 0,
    );
  }
}

class ScheduleRecord {
  Map<String, dynamic> data;

  ScheduleRecord({required this.data});

  Map<String, dynamic> toJson() => data;

  factory ScheduleRecord.fromJson(Map<String, dynamic> json) {
    return ScheduleRecord(data: json);
  }
}

class GameModeRecord {
  Map<String, dynamic> data;

  GameModeRecord({required this.data});

  Map<String, dynamic> toJson() => data;

  factory GameModeRecord.fromJson(Map<String, dynamic> json) {
    return GameModeRecord(data: json);
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
      id: json['id'] ?? '',
      product: json['product'] ?? '',
      price: json['price'] ?? '0',
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
      id: json['id'] ?? '',
      amount: json['amount'] ?? '0',
      method: json['method'] ?? '',
      note: json['note'] ?? '',
      date: json['date'] ?? '',
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
      id: json['id'] ?? '',
      item: json['item'] ?? '',
      amount: json['amount'] ?? '0',
      note: json['note'] ?? '',
      date: json['date'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
