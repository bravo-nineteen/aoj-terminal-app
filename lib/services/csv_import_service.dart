
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/csv_parser.dart';

class CsvImportService {
  static Future<bool> importBookingsCsv(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    final rows = CsvParser.parse(utf8.decode(bytes));
    if (rows.isEmpty) return false;

    final headerIndex = CsvParser.findHeaderIndex(rows, const ['Name', 'Event']);
    final headers = rows[headerIndex];
    final imported = <BookingRecord>[];

    for (final row in rows.skip(headerIndex + 1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      final map = CsvParser.rowToMap(headers, row);

      final name = CsvParser.firstNonEmpty([map['Name']]);
      final firstName = CsvParser.firstNonEmpty([map['First Name'], CsvParser.splitFirstName(name)]);
      final lastName = CsvParser.firstNonEmpty([map['Last Name'], CsvParser.splitLastName(name)]);
      final rawImportedPaid = CsvParser.firstNonEmpty([map['Total Paid']]);
      final importedMethod = CsvParser.firstNonEmpty([
        map['AOJ Payment Method'],
        map['Payment Method'],
        'Cash',
      ]);
      final shouldImportPayment =
          CsvParser.isImportedCardPayment(importedMethod) && _parseMoney(rawImportedPaid) > 0;
      final importedPaid = shouldImportPayment ? rawImportedPaid : '';

      final payments = <PaymentRecord>[];
      if (shouldImportPayment) {
        payments.add(
          PaymentRecord(
            id: '${DateTime.now().microsecondsSinceEpoch}${imported.length}',
            amount: importedPaid,
            method: importedMethod,
            note: 'Imported payment',
            date: CsvParser.firstNonEmpty([map['Booking Date'], map['Date'], '']),
          ),
        );
      }

      imported.add(
        BookingRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString() + imported.length.toString(),
          bookingId: CsvParser.firstNonEmpty([map['Booking ID'], map['ID']]),
          bookingDate: CsvParser.firstNonEmpty([map['Booking Date'], map['Date'], map['Created']]),
          firstName: firstName,
          lastName: lastName,
          email: CsvParser.firstNonEmpty([map['E-mail'], map['Email']]),
          phone: CsvParser.cleanImportedPhone(
            CsvParser.firstNonEmpty([map['Phone'], map['Phone Number'], map['Telephone']]),
          ),
          event: CsvParser.firstNonEmpty([map['Event'], event.name]),
          total: CsvParser.firstNonEmpty([map['Total']]),
          totalPaid: importedPaid,
          transactionId: CsvParser.firstNonEmpty([map['Transaction ID']]),
          paymentMethod: CsvParser.firstNonEmpty([
            map['AOJ Payment Method'],
            map['Payment Method'],
            'Cash',
          ]),
          paymentStatus: CsvParser.firstNonEmpty([
            map['AOJ Manual Paid'],
            map['Manual Payment Status'],
            'Unpaid',
          ]),
          checkInStatus: CsvParser.firstNonEmpty([
            map['AOJ Check In'],
            map['Checked In'],
            'Not Checked In',
          ]),
          notes: CsvParser.firstNonEmpty([
            map['AOJ Notes'],
            map['Internal Notes'],
            map['Booking Comment'],
          ]),
          needsPickup: BookingUtils.looksTrue(CsvParser.firstNonEmpty([
            map['Do you need pickup from the nearest station?'],
            map['Pickup'],
          ])),
          needsTraining: BookingUtils.looksTrue(CsvParser.firstNonEmpty([
            map['Do you need beginners training?'],
            map['Training'],
          ])),
          guestNames: CsvParser.firstNonEmpty([
            map['Guest Name(s) & Gender'],
            map['Guest Names'],
            map['Guests'],
          ]),
          languagePreference: CsvParser.firstNonEmpty([
            map['Language Preference'],
            map['Language'],
          ]),
          ticketIds: [],
          sales: [],
          payments: payments,
        ),
      );
    }

    event.bookings = imported;
    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);
    return true;
  }

  static Future<bool> importTicketsCsv(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    final rows = CsvParser.parse(utf8.decode(bytes));
    if (rows.isEmpty) return false;

    final headerIndex = CsvParser.findHeaderIndex(rows, const ['Name']);
    final headers = rows[headerIndex];
    final imported = <TicketRecord>[];

    for (final row in rows.skip(headerIndex + 1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      final map = CsvParser.rowToMap(headers, row);

      imported.add(
        TicketRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString() + imported.length.toString(),
          bookingId: CsvParser.firstNonEmpty([map['Booking ID'], map['ID']]),
          bookingName: CsvParser.firstNonEmpty([map['Name']]),
          ticketName: CsvParser.firstNonEmpty([map['Ticket Name'], map['Ticket'], map['Item Name']]),
          price: CsvParser.firstNonEmpty(
            [map['Ticket Total'], map['Ticket Price'], map['Price'], map['Amount']],
          ),
          spaces: CsvParser.firstNonEmpty([map['Ticket Spaces'], map['Spaces'], '1']),
          status: CsvParser.firstNonEmpty([map['Status'], 'Active']),
        ),
      );
    }

    event.tickets = imported;
    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);
    return true;
  }

  static Future<bool> importMembersCsv(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    final rows = CsvParser.parse(utf8.decode(bytes));
    if (rows.isEmpty) return false;
    final headers = rows.first;
    final imported = <MemberRecord>[];

    for (final row in rows.skip(1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      final map = CsvParser.rowToMap(headers, row);
      final name = CsvParser.firstNonEmpty([map['Name']]);

      imported.add(
        MemberRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString() + imported.length.toString(),
          firstName: CsvParser.firstNonEmpty([map['First Name'], CsvParser.splitFirstName(name)]),
          lastName: CsvParser.firstNonEmpty([map['Last Name'], CsvParser.splitLastName(name)]),
          dateOfBirth: CsvParser.firstNonEmpty([map['Date of Birth'], map['DOB']]),
          gender: CsvParser.firstNonEmpty([map['Gender']]),
          telephone: CsvParser.firstNonEmpty([map['Telephone'], map['Phone']]),
          email: CsvParser.firstNonEmpty([map['Email'], map['E-mail']]),
          membershipLevel: CsvParser.firstNonEmpty([map['Membership Level'], 'Regular']),
        ),
      );
    }

    event.members = imported;
    return true;
  }

  static Future<bool> importScheduleCsv(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    final rows = CsvParser.parse(utf8.decode(bytes));
    if (rows.isEmpty) return false;
    final headers = rows.first;
    final imported = <ScheduleRecord>[];

    for (final row in rows.skip(1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      imported.add(ScheduleRecord(data: CsvParser.rowToMap(headers, row)));
    }

    event.schedule = imported;
    return true;
  }

  static Future<bool> importGameModesCsv(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    final rows = CsvParser.parse(utf8.decode(bytes));
    if (rows.isEmpty) return false;
    final headers = rows.first;
    final imported = <GameModeRecord>[];

    for (final row in rows.skip(1)) {
      if (row.every((e) => e.trim().isEmpty)) continue;
      imported.add(GameModeRecord(data: CsvParser.rowToMap(headers, row)));
    }

    event.gameModes = imported;
    return true;
  }

  static Future<bool> importFieldMap(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) return false;

    event.fieldMapBase64 = base64Encode(bytes);
    return true;
  }

  static double _parseMoney(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
