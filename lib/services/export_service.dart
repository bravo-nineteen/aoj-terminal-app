import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';

class ExportService {
  static Future<String> exportActiveEventJson(EventRecord event) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = _safeFileName(event.name);
    final file = File('${dir.path}/${safeName}_export.json');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(event.toJson()),
      flush: true,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'AOJ event export: ${event.name}',
    );

    return 'EXPORTED ${event.name} JSON';
  }

  static Future<String> exportBookingsCsv(EventRecord event) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = _safeFileName(event.name);
    final file = File('${dir.path}/${safeName}_bookings_export.csv');

    final groups = BookingUtils.groupedBookingsForEvent(event);

    final rows = <List<dynamic>>[
      [
        'Event Name',
        'Venue',
        'Date',
        'Time',
        'Booking ID',
        'Booking Date',
        'First Name',
        'Last Name',
        'Full Name',
        'Email',
        'Phone',
        'Membership Level',
        'Check In Status',
        'Payment Status',
        'Payment Method',
        'Transaction ID',
        'Pickup',
        'Beginners Training',
        'Guest Names',
        'Language Preference',
        'Rental Gun Sets',
        'Ticket Lines',
        'Ticket Quantity Total',
        'Ticket Total',
        'Payment Lines',
        'Payments Total',
        'Sales Lines',
        'Sales Total',
        'Grand Total',
        'Balance',
        'Notes',
      ],
    ];

    for (final group in groups) {
      final membershipLevel = _membershipLevelForGroup(event, group);

      final ticketLines = group.tickets
          .map(
            (t) =>
                '${t.ticketName} [qty:${t.quantity}, price:${t.price}, status:${t.status}]',
          )
          .join(' | ');

      final paymentLines = group.primary.payments
          .map(
            (p) =>
                '${p.amount} ${p.method}${p.note.trim().isNotEmpty ? ' (${p.note.trim()})' : ''}',
          )
          .join(' | ');

      final salesLines = group.primary.sales
          .map((s) => '${s.product} (${s.price})')
          .join(' | ');

      final ticketQuantityTotal = group.tickets.fold<int>(
        0,
        (sum, ticket) => sum + ticket.quantity,
      );

      rows.add([
        event.name,
        event.venue,
        event.date,
        event.time,
        group.bookingId,
        group.primary.bookingDate,
        group.primary.firstName,
        group.primary.lastName,
        group.displayName,
        group.primary.email,
        group.primary.phone,
        membershipLevel,
        group.primary.checkInStatus,
        group.primary.paymentStatus,
        group.primary.paymentMethod,
        group.primary.transactionId,
        group.needsPickup ? 'Yes' : 'No',
        group.needsTraining ? 'Yes' : 'No',
        group.guestNames,
        group.languagePreference,
        BookingUtils.groupRentalCount(group),
        ticketLines,
        ticketQuantityTotal,
        BookingUtils.ticketsTotal(group).toStringAsFixed(0),
        paymentLines,
        BookingUtils.paymentsTotal(group).toStringAsFixed(0),
        salesLines,
        BookingUtils.salesTotal(group).toStringAsFixed(0),
        BookingUtils.grandTotal(group).toStringAsFixed(0),
        BookingUtils.balance(group).toStringAsFixed(0),
        group.primary.notes,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'AOJ bookings export: ${event.name}',
    );

    return 'EXPORTED ${event.name} BOOKINGS CSV';
  }

  static String _safeFileName(String input) {
    final trimmed = input.trim().isEmpty ? 'aoj_event' : input.trim();
    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static String _membershipLevelForGroup(EventRecord event, BookingGroup group) {
    for (final member in event.members) {
      final memberEmail = member.email.trim().toLowerCase();
      final memberPhone = member.telephone.trim().toLowerCase();
      final memberName = member.fullName.trim().toLowerCase();

      final groupEmail = group.email.trim().toLowerCase();
      final groupPhone = group.phone.trim().toLowerCase();
      final groupName = group.displayName.trim().toLowerCase();

      final emailMatch =
          memberEmail.isNotEmpty &&
          groupEmail.isNotEmpty &&
          memberEmail == groupEmail;

      final phoneMatch =
          memberPhone.isNotEmpty &&
          groupPhone.isNotEmpty &&
          memberPhone == groupPhone;

      final nameMatch =
          memberName.isNotEmpty &&
          groupName.isNotEmpty &&
          memberName == groupName;

      if (emailMatch || phoneMatch || nameMatch) {
        return member.membershipLevel;
      }
    }

    return '';
  }
}
