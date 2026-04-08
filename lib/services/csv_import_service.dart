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

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    if (rows.isEmpty) return false;

    final header = rows.first.map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(1);

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
    ]);
    final transactionIdIndex = _findColumnIndex(header, [
      'Transaction ID',
      'TransactionID',
      'Payment ID',
    ]);
    final paymentMethodIndex = _findColumnIndex(header, [
      'Payment Method',
      'Method',
    ]);
    final paymentStatusIndex = _findColumnIndex(header, [
      'Payment Status',
      'Status',
    ]);
    final checkInStatusIndex = _findColumnIndex(header, [
      'Check In Status',
      'Check-In Status',
      'Check In',
    ]);
    final notesIndex = _findColumnIndex(header, [
      'Notes',
      'Note',
      'Remarks',
      'Comment',
    ]);
    final pickupIndex = _findColumnIndex(header, [
      'Pickup',
      'Need Pickup',
      'Needs Pickup',
    ]);
    final trainingIndex = _findColumnIndex(header, [
      'Beginners Training',
      'Training',
      'Need Training',
      'Needs Training',
    ]);
    final guestNamesIndex = _findColumnIndex(header, [
      'Guest Names',
      'Guests',
      'Guest Name',
    ]);
    final languageIndex = _findColumnIndex(header, [
      'Language',
      'Language Preference',
      'Language Pref',
    ]);

    final List<BookingRecord> imported = [];

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      final firstName = _cellAt(row, firstNameIndex);
      final lastName = _cellAt(row, lastNameIndex);
      final email = _cellAt(row, emailIndex);
      final phone = _cellAt(row, phoneIndex);

      final looksEmpty = [
        firstName,
        lastName,
        email,
        phone,
      ].every((v) => v.trim().isEmpty);

      if (looksEmpty) continue;

      imported.add(
        BookingRecord(
          id: _makeId('booking_row', imported.length),
          bookingId: _cellAt(row, bookingIdIndex),
          bookingDate: _cellAt(row, bookingDateIndex),
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          event: event.name,
          total: _cellAt(row, totalIndex),
          totalPaid: _cellAt(row, totalPaidIndex),
          transactionId: _cellAt(row, transactionIdIndex),
          paymentMethod: _cellAt(row, paymentMethodIndex),
          paymentStatus: _cellAt(row, paymentStatusIndex).isEmpty
              ? 'Unpaid'
              : _cellAt(row, paymentStatusIndex),
          checkInStatus: _cellAt(row, checkInStatusIndex).isEmpty
              ? 'Not Checked In'
              : _cellAt(row, checkInStatusIndex),
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

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    if (rows.isEmpty) return false;

    final header = rows.first.map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(1);

    final bookingIdIndex = _findColumnIndex(header, [
      'Booking ID',
      'BookingID',
      'Order ID',
    ]);
    final bookingNameIndex = _findColumnIndex(header, [
      'Booking Name',
      'Name',
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
      'Price',
      'Amount',
      'Cost',
    ]);
    final spacesIndex = _findColumnIndex(header, [
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
          price: _cellAt(row, priceIndex).isEmpty ? '0' : _cellAt(row, priceIndex),
          spaces: _cellAt(row, spacesIndex).isEmpty ? '1' : _cellAt(row, spacesIndex),
          status: _cellAt(row, statusIndex).isEmpty ? 'Active' : _cellAt(row, statusIndex),
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

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    if (rows.isEmpty) return false;

    final header = rows.first.map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(1);

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
      'Rating',
      'Rank',
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
      final rating = _parseInt(_cellAt(row, ratingIndex));

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

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    if (rows.isEmpty) return false;

    final header = rows.first.map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(1);

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

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    if (rows.isEmpty) return false;

    final header = rows.first.map((e) => _cleanCell(e)).toList();
    final dataRows = rows.skip(1);

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

  static String _decodeCsvBytes(Uint8List bytes) {
    String text = utf8.decode(bytes, allowMalformed: true);

    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }

    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  static int _findColumnIndex(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final normalizedCandidate = candidate.trim().toLowerCase();

      final index = header.indexWhere(
        (h) => h.trim().toLowerCase() == normalizedCandidate,
      );

      if (index != -1) return index;
    }

    return -1;
  }

  static String _cellAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _cleanCell(row[index]);
  }

  static String _cleanCell(dynamic value) {
    if (value == null) return '';
    return value.toString().replaceAll('\ufeff', '').trim();
  }

  static String _normalizeMembershipLevel(String raw) {
    final value = raw.trim().toLowerCase();

    if (value.contains('admin')) return 'Admin';
    if (value.contains('support')) return 'Support';
    if (value.contains('elite')) return 'Elite';
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
        value == '1';
  }

  static int _parseInt(String raw) {
    return int.tryParse(raw.trim()) ?? 0;
  }

  static String _makeId(String prefix, int index) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$index';
  }
}