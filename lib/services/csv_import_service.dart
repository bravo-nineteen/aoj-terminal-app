import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';

class CsvImportService {
  static Future<bool> importBookingsCsv(EventRecord event) async {
    final csvText = await _pickCsvText();
    if (csvText == null || csvText.trim().isEmpty) return false;

    final rows = _parseCsvRows(csvText);
    if (rows.isEmpty) return false;

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'Name',
      'Event',
      'Status',
      'Total',
      'Booking Date',
      'Booking ID',
    ]);
    if (headerRowIndex == -1) return false;

    final header = rows[headerRowIndex].map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(headerRowIndex + 1);

    final bookingIdIndex = _findColumnIndex(header, [
      'Booking ID',
      'BookingID',
      'Order ID',
      'OrderID',
      'ID',
    ]);
    final bookingDateIndex = _findColumnIndex(header, [
      'Booking Date',
      'Date',
      'Order Date',
    ]);
    final firstNameIndex = _findColumnIndex(header, [
      'First Name',
      'FirstName',
      'Given Name',
    ]);
    final lastNameIndex = _findColumnIndex(header, [
      'Last Name',
      'LastName',
      'Surname',
      'Family Name',
    ]);
    final emailIndex = _findColumnIndex(header, [
      'Email',
      'Email Address',
      'E-mail',
      'E-mail Address',
    ]);
    final phoneIndex = _findColumnIndex(header, [
      'Phone',
      'Phone Number',
      'Telephone',
      'Telephone No',
      'Mobile',
      'Tel',
    ]);
    final totalIndex = _findColumnIndex(header, [
      'Total',
      'Order Total',
      'Amount',
    ]);
    final totalPaidIndex = _findColumnIndex(header, [
      'Total Paid',
      'Paid',
      'Amount Paid',
      'AOJ Manual Paid',
    ]);
    final transactionIdIndex = _findColumnIndex(header, [
      'Transaction ID',
      'TransactionID',
      'Payment ID',
    ]);
    final paymentMethodIndex = _findColumnIndex(header, [
      'AOJ Payment Method',
      'Payment Method',
      'Method',
      'Gateway Used',
    ]);
    final paymentStatusIndex = _findColumnIndex(header, [
      'AOJ Manual Paid',
      'Payment Status',
      'Status',
    ]);
    final checkInStatusIndex = _findColumnIndex(header, [
      'AOJ Check In',
      'Check In Status',
      'Check-In Status',
      'Check In',
    ]);
    final notesIndex = _findColumnIndex(header, [
      'AOJ Notes',
      'Booking Comment',
      'Notes',
      'Note',
      'Remarks',
      'Comment',
      'Comments',
    ]);
    final pickupIndex = _findColumnIndex(header, [
      'Do you need pickup from the nearest station?',
      'Pickup',
      'Need Pickup',
      'Needs Pickup',
    ]);
    final trainingIndex = _findColumnIndex(header, [
      'Do you need beginners training?',
      'Beginners Training',
      'Training',
      'Need Training',
      'Needs Training',
    ]);
    final guestNamesIndex = _findColumnIndex(header, [
      'Guest Name(s) & Gender',
      'Guest Names',
      'Guests',
      'Guest Name',
    ]);
    final languageIndex = _findColumnIndex(header, [
      'Language Preference',
      'Language',
      'Language Pref',
    ]);
    final eventNameIndex = _findColumnIndex(header, [
      'Event',
    ]);

    final List<BookingRecord> imported = [];

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      final firstName = _cellAt(row, firstNameIndex);
      final lastName = _cellAt(row, lastNameIndex);
      final email = _cellAt(row, emailIndex);
      final phone = _cellAt(row, phoneIndex);
      final bookingId = _cellAt(row, bookingIdIndex);

      final looksEmpty = [
        firstName,
        lastName,
        email,
        phone,
        bookingId,
      ].every((v) => v.trim().isEmpty);

      if (looksEmpty) continue;

      final rawPaymentStatus = _cellAt(row, paymentStatusIndex);
      final rawCheckInStatus = _cellAt(row, checkInStatusIndex);

      imported.add(
        BookingRecord(
          id: _makeId('booking_row', imported.length),
          bookingId: bookingId,
          bookingDate: _cellAt(row, bookingDateIndex),
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          event: _cellAt(row, eventNameIndex).isEmpty
              ? event.name
              : _cellAt(row, eventNameIndex),
          total: _normalizeMoney(_cellAt(row, totalIndex)),
          totalPaid: _normalizeMoney(_cellAt(row, totalPaidIndex)),
          transactionId: _cellAt(row, transactionIdIndex),
          paymentMethod: _cellAt(row, paymentMethodIndex),
          paymentStatus: rawPaymentStatus.isEmpty ? 'Unpaid' : rawPaymentStatus,
          checkInStatus:
              rawCheckInStatus.isEmpty ? 'Not Checked In' : rawCheckInStatus,
          notes: _cellAt(row, notesIndex),
          needsPickup: _looksTrue(_cellAt(row, pickupIndex)),
          needsTraining: _looksTrue(_cellAt(row, trainingIndex)),
          guestNames: _cellAt(row, guestNamesIndex),
          languagePreference: _cellAt(row, languageIndex),
          ticketIds: [],
          sales: [],
          payments: [],
        ),
      );
    }

    event.bookings
      ..clear()
      ..addAll(imported);

    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);

    return true;
  }

  static Future<bool> importTicketsCsv(EventRecord event) async {
    final csvText = await _pickCsvText();
    if (csvText == null || csvText.trim().isEmpty) return false;

    final rows = _parseCsvRows(csvText);
    if (rows.isEmpty) return false;

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'Name',
      'Ticket Name',
      'Status',
      'Ticket Price',
      'Ticket Spaces',
    ]);
    if (headerRowIndex == -1) return false;

    final header = rows[headerRowIndex].map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(headerRowIndex + 1);

    final bookingIdIndex = _findColumnIndex(header, [
      'Booking ID',
      'BookingID',
      'Order ID',
    ]);
    final bookingNameIndex = _findColumnIndex(header, [
      'Name',
      'Booking Name',
      'Customer Name',
      'Full Name',
    ]);
    final ticketNameIndex = _findColumnIndex(header, [
      'Ticket Name',
      'Ticket',
      'Product',
      'Item',
    ]);
    final priceIndex = _findColumnIndex(header, [
      'Ticket Price',
      'Price',
      'Amount',
      'Cost',
    ]);
    final spacesIndex = _findColumnIndex(header, [
      'Ticket Spaces',
      'Spaces',
      'Quantity',
      'Qty',
    ]);
    final statusIndex = _findColumnIndex(header, [
      'Status',
      'Ticket Status',
    ]);

    final List<TicketRecord> imported = [];

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      final ticketName = _cellAt(row, ticketNameIndex);
      final bookingName = _cellAt(row, bookingNameIndex);

      if (ticketName.isEmpty && bookingName.isEmpty) continue;

      imported.add(
        TicketRecord(
          id: _makeId('ticket', imported.length),
          bookingId: _cellAt(row, bookingIdIndex),
          bookingName: bookingName,
          ticketName: ticketName.isEmpty ? 'Ticket' : ticketName,
          price: _normalizeMoney(_cellAt(row, priceIndex)).isEmpty
              ? '0'
              : _normalizeMoney(_cellAt(row, priceIndex)),
          spaces: _cellAt(row, spacesIndex).isEmpty
              ? '1'
              : _cellAt(row, spacesIndex),
          status: _cellAt(row, statusIndex).isEmpty
              ? 'Active'
              : _cellAt(row, statusIndex),
        ),
      );
    }

    event.tickets
      ..clear()
      ..addAll(imported);

    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);

    return true;
  }

  static Future<bool> importMembersCsv(EventRecord event) async {
    final csvText = await _pickCsvText();
    if (csvText == null || csvText.trim().isEmpty) return false;

    final rows = _parseCsvRows(csvText);
    if (rows.isEmpty) return false;

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'First Name',
      'Last Name',
      'Telephone No',
      'Email',
      'Membership Level',
    ]);
    if (headerRowIndex == -1) return false;

    final header = rows[headerRowIndex].map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(headerRowIndex + 1);

    final firstNameIndex = _findColumnIndex(header, [
      'First Name',
      'FirstName',
      'Given Name',
      'GivenName',
    ]);
    final lastNameIndex = _findColumnIndex(header, [
      'Last Name',
      'LastName',
      'Surname',
      'Family Name',
      'FamilyName',
    ]);
    final usernameIndex = _findColumnIndex(header, [
      'Username',
      'User Name',
      'Member Number',
      'Member ID',
    ]);
    final dobIndex = _findColumnIndex(header, [
      'Date of Birth',
      'DOB',
      'Birth Date',
      'Birthday',
    ]);
    final genderIndex = _findColumnIndex(header, [
      'Gender',
      'Sex',
    ]);
    final telephoneIndex = _findColumnIndex(header, [
      'Telephone No',
      'Telephone',
      'Phone',
      'Phone Number',
      'Mobile',
      'Tel',
    ]);
    final emailIndex = _findColumnIndex(header, [
      'Email',
      'Email Address',
      'E-mail',
      'Mail',
    ]);
    final membershipLevelIndex = _findColumnIndex(header, [
      'Membership Level',
      'Membership',
      'Level',
      'Member Type',
      'Type',
    ]);
    final ratingIndex = _findColumnIndex(header, [
      'Rank',
      'Rating',
      'Score',
    ]);

    if (firstNameIndex == -1 &&
        lastNameIndex == -1 &&
        telephoneIndex == -1 &&
        emailIndex == -1) {
      return false;
    }

    final List<MemberRecord> importedMembers = [];
    final Set<String> seenKeys = {};

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      final firstName = _cellAt(row, firstNameIndex);
      final lastName = _cellAt(row, lastNameIndex);
      final username = _cellAt(row, usernameIndex);
      final dateOfBirth = _cellAt(row, dobIndex);
      final gender = _normalizeGender(_cellAt(row, genderIndex));
      final telephone = _cellAt(row, telephoneIndex);
      final email = _cellAt(row, emailIndex);
      final membershipLevel = _normalizeMembershipLevel(
        _cellAt(row, membershipLevelIndex),
      );
      final rating = _parseRating(_cellAt(row, ratingIndex));

      final looksEmpty = [
        firstName,
        lastName,
        dateOfBirth,
        gender,
        telephone,
        email,
      ].every((v) => v.trim().isEmpty);

      if (looksEmpty) continue;

      final dedupeKey = [
        firstName.trim().toLowerCase(),
        lastName.trim().toLowerCase(),
        telephone.replaceAll(' ', '').trim().toLowerCase(),
        email.trim().toLowerCase(),
      ].join('|');

      if (seenKeys.contains(dedupeKey)) continue;
      seenKeys.add(dedupeKey);

      importedMembers.add(
        MemberRecord(
          id: _makeId('member', importedMembers.length),
          firstName: firstName,
          lastName: lastName,
          username: username,
          dateOfBirth: dateOfBirth,
          gender: gender,
          telephone: telephone,
          email: email,
          membershipLevel: membershipLevel,
          rating: rating.clamp(0, 5),
        ),
      );
    }

    event.members
      ..clear()
      ..addAll(importedMembers);

    return true;
  }

  static Future<bool> importScheduleCsv(EventRecord event) async {
    final csvText = await _pickCsvText();
    if (csvText == null || csvText.trim().isEmpty) return false;

    final rows = _parseCsvRows(csvText);
    if (rows.isEmpty) return false;

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'Time',
      'Activity',
    ]);
    if (headerRowIndex == -1) return false;

    final header = rows[headerRowIndex].map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(headerRowIndex + 1);

    final timeIndex = _findColumnIndex(header, [
      'Time',
      'Start Time',
      'Start',
    ]);
    final activityIndex = _findColumnIndex(header, [
      'Activity',
      'Task',
      'Event',
      'Title',
      'Name',
    ]);
    final locationIndex = _findColumnIndex(header, [
      'Location',
      'Place',
      'Area',
      'Venue',
    ]);
    final notesIndex = _findColumnIndex(header, [
      'Notes',
      'Note',
      'Remarks',
      'Comment',
      'Comments',
    ]);

    if (timeIndex == -1 && activityIndex == -1) {
      return false;
    }

    final List<ScheduleRecord> importedSchedule = [];

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      final time = _cellAt(row, timeIndex);
      final activity = _cellAt(row, activityIndex);
      final location = _cellAt(row, locationIndex);
      final notes = _cellAt(row, notesIndex);

      final looksEmpty = [
        time,
        activity,
        location,
        notes,
      ].every((v) => v.trim().isEmpty);

      if (looksEmpty) continue;

      importedSchedule.add(
        ScheduleRecord(
          id: _makeId('schedule', importedSchedule.length),
          time: time,
          activity: activity,
          location: location,
          notes: notes,
        ),
      );
    }

    event.schedule
      ..clear()
      ..addAll(importedSchedule);

    return true;
  }

  static Future<bool> importGameModesCsv(EventRecord event) async {
    final csvText = await _pickCsvText();
    if (csvText == null || csvText.trim().isEmpty) return false;

    final rows = _parseCsvRows(csvText);
    if (rows.isEmpty) return false;

    final headerRowIndex = rows.indexWhere(
      (row) => row.any((cell) => _cleanCell(cell).isNotEmpty),
    );
    if (headerRowIndex == -1) return false;

    final header = rows[headerRowIndex].map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(headerRowIndex + 1);

    final List<GameModeRecord> imported = [];

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      final map = <String, String>{};
      for (int i = 0; i < header.length; i++) {
        final key = header[i];
        if (key.isEmpty) continue;
        map[key] = _cellAt(row, i);
      }

      if (map.values.every((v) => v.trim().isEmpty)) continue;
      imported.add(GameModeRecord(data: map));
    }

    event.gameModes
      ..clear()
      ..addAll(imported);

    return true;
  }

  static Future<bool> importFieldMap(EventRecord event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return false;

    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return false;

    event.fieldMapBase64 = base64Encode(bytes);
    return true;
  }

  static Future<String?> _pickCsvText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return _decodeCsvBytes(bytes);
  }

  static List<List<dynamic>> _parseCsvRows(String csvText) {
    return const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);
  }

  static int _findHeaderRowIndex(
    List<List<dynamic>> rows,
    List<String> requiredColumns,
  ) {
    for (int i = 0; i < rows.length; i++) {
      final header = rows[i].map((e) => _cleanCell(e)).toList();
      int matches = 0;

      for (final column in requiredColumns) {
        if (_findColumnIndex(header, [column]) != -1) {
          matches++;
        }
      }

      if (matches >= 2) {
        return i;
      }
    }

    return -1;
  }

  static String _decodeCsvBytes(Uint8List bytes) {
    String text = utf8.decode(bytes, allowMalformed: true);

    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }

    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  static int _findColumnIndex(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeHeader(candidate);

      final index = header.indexWhere(
        (h) => _normalizeHeader(h) == normalizedCandidate,
      );

      if (index != -1) return index;
    }

    return -1;
  }

  static String _normalizeHeader(String value) {
    return value
        .replaceAll('\ufeff', '')
        .replaceAll(':', '')
        .replaceAll('?', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('&', 'and')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static String _cellAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _cleanCell(row[index]);
  }

  static String _cleanCell(dynamic value) {
    if (value == null) return '';
    return value.toString().replaceAll('\ufeff', '').trim();
  }

  static String _normalizeMoney(String raw) {
    return raw
        .replaceAll('\u00a5', '')
        .replaceAll('¥', '')
        .replaceAll(',', '')
        .trim();
  }

  static String _normalizeMembershipLevel(String raw) {
    final value = raw.trim().toLowerCase();

    if (value.contains('admin')) return 'Admin';
    if (value.contains('support')) return 'Support';
    if (value.contains('elite')) return 'Elite';
    if (value.contains('inactive')) return 'Inactive';
    return 'Regular';
  }

  static String _normalizeGender(String raw) {
    final value = raw.trim().toLowerCase();

    if (value == 'm' || value == 'male') return 'Male';
    if (value == 'f' || value == 'female') return 'Female';
    if (value == 'other') return 'Other';

    return raw.trim();
  }

  static bool _looksTrue(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'yes' ||
        value == 'y' ||
        value == 'true' ||
        value == '1' ||
        value == 'paid' ||
        value == 'checked in';
  }

  static int _parseInt(String raw) {
    return int.tryParse(raw.trim()) ?? 0;
  }

  static int _parseRating(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 0;

    if (trimmed.contains('★')) {
      return '★'.allMatches(trimmed).length;
    }

    return _parseInt(trimmed);
  }

  static String _makeId(String prefix, int index) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$index';
  }
}
