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

  static Future<String> exportActiveEventFullCsv(EventRecord event) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = _safeFileName(event.name);
      final file = File('${dir.path}/${safeName}_full_event_export.csv');

      final groups = BookingUtils.groupedBookingsForEvent(event);

      final rows = <List<dynamic>>[
        ['Event', event.name],
        ['Venue', event.venue],
        ['Date', event.date],
        ['Time', event.time],
        [],
        ['ATTENDANCE'],
        [
          'Booking ID',
          'Name',
          'Email',
          'Phone',
          'Check In Status',
          'Payment Status',
          'Needs Pickup',
          'Needs Training',
          'Guest Names',
          'Language',
          'Ticket Value',
          'Sales Value',
          'Grand Total',
          'Payments Recorded',
          'Balance',
        ],
      ];

      double totalCardFees = 0;
      double totalManualExpenses = 0;

      for (final group in groups) {
        final ticketValue = _toDouble(BookingUtils.ticketsTotal(group).toString());
        final salesValue = _toDouble(BookingUtils.salesTotal(group).toString());
        final grandTotal = _toDouble(BookingUtils.grandTotal(group).toString());
        final paymentsRecorded =
            _toDouble(BookingUtils.paymentsTotal(group).toString());
        final balance = _toDouble(BookingUtils.balance(group).toString());

        rows.add([
          group.bookingId,
          group.displayName,
          group.email,
          group.phone,
          group.primary.checkInStatus,
          group.primary.paymentStatus,
          group.needsPickup ? 'Yes' : 'No',
          group.needsTraining ? 'Yes' : 'No',
          group.guestNames,
          group.languagePreference,
          ticketValue.toStringAsFixed(0),
          salesValue.toStringAsFixed(0),
          grandTotal.toStringAsFixed(0),
          paymentsRecorded.toStringAsFixed(0),
          balance.toStringAsFixed(0),
        ]);
      }

      rows.add([]);
      rows.add(['PAYMENTS']);
      rows.add([
        'Booking ID',
        'Name',
        'Method',
        'Note',
        'Date',
        'Amount',
        'Card Fee 4%',
      ]);

      for (final group in groups) {
        for (final payment in group.primary.payments) {
          final amount = _toDouble(payment.amount);
          final fee = _isCardMethod(payment.method) ? amount * 0.04 : 0;
          totalCardFees += fee;

          rows.add([
            group.bookingId,
            group.displayName,
            payment.method,
            payment.note,
            payment.date,
            amount.toStringAsFixed(0),
            fee.toStringAsFixed(0),
          ]);
        }
      }

      rows.add([]);
      rows.add(['SALES']);
      rows.add([
        'Booking ID',
        'Name',
        'Product',
        'Price',
      ]);

      for (final group in groups) {
        for (final sale in group.primary.sales) {
          rows.add([
            group.bookingId,
            group.displayName,
            sale.product,
            _toDouble(sale.price).toStringAsFixed(0),
          ]);
        }
      }

      rows.add([]);
      rows.add(['EXPENSES']);
      rows.add([
        'Item',
        'Category',
        'Note',
        'Date',
        'Amount',
      ]);

      for (final expense in event.expenses) {
        final amount = _toDouble(expense.amount);
        totalManualExpenses += amount;

        rows.add([
          expense.item,
          expense.category,
          expense.note,
          expense.date,
          amount.toStringAsFixed(0),
        ]);
      }

      final totalTicketValue = groups.fold<double>(
        0,
        (sum, group) =>
            sum + _toDouble(BookingUtils.ticketsTotal(group).toString()),
      );
      final totalSalesValue = groups.fold<double>(
        0,
        (sum, group) =>
            sum + _toDouble(BookingUtils.salesTotal(group).toString()),
      );
      final totalGrandValue = groups.fold<double>(
        0,
        (sum, group) =>
            sum + _toDouble(BookingUtils.grandTotal(group).toString()),
      );
      final totalPaymentsRecorded = groups.fold<double>(
        0,
        (sum, group) =>
            sum + _toDouble(BookingUtils.paymentsTotal(group).toString()),
      );
      final totalOutstandingBalance = groups.fold<double>(
        0,
        (sum, group) =>
            sum + _toDouble(BookingUtils.balance(group).toString()),
      );
      final checkedInCount = groups
          .where((g) => g.primary.checkInStatus.trim() == 'Checked In')
          .length;

      final totalDeductions = totalCardFees + totalManualExpenses;
      final netAfterDeductions = totalPaymentsRecorded - totalDeductions;

      rows.add([]);
      rows.add(['SUMMARY']);
      rows.add(['Bookings', groups.length]);
      rows.add(['Checked In', checkedInCount]);
      rows.add(['Ticket Value', totalTicketValue.toStringAsFixed(0)]);
      rows.add(['Sales Value', totalSalesValue.toStringAsFixed(0)]);
      rows.add(['Gross Event Value', totalGrandValue.toStringAsFixed(0)]);
      rows.add(['Payments Recorded', totalPaymentsRecorded.toStringAsFixed(0)]);
      rows.add(['Card Fees 4%', totalCardFees.toStringAsFixed(0)]);
      rows.add(['Manual Expenses', totalManualExpenses.toStringAsFixed(0)]);
      rows.add(['Total Deductions', totalDeductions.toStringAsFixed(0)]);
      rows.add(['Net After Deductions', netAfterDeductions.toStringAsFixed(0)]);
      rows.add([
        'Outstanding Balance',
        totalOutstandingBalance.toStringAsFixed(0),
      ]);

      final csv = const ListToCsvConverter().convert(rows);
      await file.writeAsString(csv, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AOJ full event export: ${event.name}',
      );

      return 'EXPORTED ${event.name} FULL EVENT CSV';
    } catch (_) {
      return 'FULL EVENT CSV EXPORT FAILED';
    }
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

      final emailMatch = memberEmail.isNotEmpty &&
          groupEmail.isNotEmpty &&
          memberEmail == groupEmail;

      final phoneMatch = memberPhone.isNotEmpty &&
          groupPhone.isNotEmpty &&
          memberPhone == groupPhone;

      final nameMatch =
          memberName.isNotEmpty && groupName.isNotEmpty && memberName == groupName;

      if (emailMatch || phoneMatch || nameMatch) {
        return member.membershipLevel;
      }
    }

    return '';
  }

  static bool _isCardMethod(String raw) {
    final value = raw.trim().toLowerCase();
    return value.contains('credit') ||
        value.contains('card') ||
        value.contains('stripe') ||
        value.contains('visa') ||
        value.contains('mastercard') ||
        value.contains('amex') ||
        value.contains('クレジット');
  }

  static double _toDouble(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
