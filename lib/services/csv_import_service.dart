import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';

class WorkbookImportResult {
  final bool success;
  final int bookingsImported;
  final int ticketsImported;
  final int membersImported;
  final int scheduleImported;
  final int gameModesImported;
  final List<String> missingSheets;
  final List<String> importedSheets;
  final List<String> notes;

  const WorkbookImportResult({
    required this.success,
    required this.bookingsImported,
    required this.ticketsImported,
    required this.membersImported,
    required this.scheduleImported,
    required this.gameModesImported,
    required this.missingSheets,
    required this.importedSheets,
    required this.notes,
  });

  int get totalImported =>
      bookingsImported +
      ticketsImported +
      membersImported +
      scheduleImported +
      gameModesImported;
}

class CsvImportService {
  static Future<WorkbookImportResult> importWorkbookXlsx(
    EventRecord event,
  ) async {
    final bytes = await _pickFileBytes(['xlsx', 'xls']);
    if (bytes == null || bytes.isEmpty) {
      return const WorkbookImportResult(
        success: false,
        bookingsImported: 0,
        ticketsImported: 0,
        membersImported: 0,
        scheduleImported: 0,
        gameModesImported: 0,
        missingSheets: [],
        importedSheets: [],
        notes: ['No workbook selected or workbook was empty.'],
      );
    }

    final excel = Excel.decodeBytes(bytes);

    final missingSheets = <String>[];
    final importedSheets = <String>[];
    final notes = <String>[];

    int bookingsImported = 0;
    int ticketsImported = 0;
    int membersImported = 0;
    int scheduleImported = 0;
    int gameModesImported = 0;

    final bookingsRows = _sheetRowsByCandidateNames(excel, const [
      'Bookings',
      'Booking',
      'bookings',
      'booking',
    ]);
    if (bookingsRows != null && bookingsRows.isNotEmpty) {
      final imported = _parseBookingsRows(bookingsRows, event.name);
      event.bookings
        ..clear()
        ..addAll(imported);
      bookingsImported = imported.length;
      importedSheets.add('Bookings');
      notes.add('Bookings sheet imported.');
    } else {
      missingSheets.add('Bookings');
    }

    final ticketsRows = _sheetRowsByCandidateNames(excel, const [
      'Tickets',
      'Ticket',
      'tickets',
      'ticket',
    ]);
    if (ticketsRows != null && ticketsRows.isNotEmpty) {
      final imported = _parseTicketsRows(ticketsRows);
      event.tickets
        ..clear()
        ..addAll(imported);
      ticketsImported = imported.length;
      importedSheets.add('Tickets');
      notes.add('Tickets sheet imported.');
    } else {
      missingSheets.add('Tickets');
    }

    final membersRows = _sheetRowsByCandidateNames(excel, const [
      'Members',
      'Member',
      'members',
      'member',
    ]);
    if (membersRows != null && membersRows.isNotEmpty) {
      final imported = _parseMembersRows(membersRows);
      event.members
        ..clear()
        ..addAll(imported);
      membersImported = imported.length;
      importedSheets.add('Members');
      notes.add('Members sheet imported.');
    } else {
      missingSheets.add('Members');
    }

    final scheduleRows = _sheetRowsByCandidateNames(excel, const [
      'Schedule',
      'Run Sheet',
      'Timeline',
      'schedule',
      'runsheet',
      'timeline',
    ]);
    if (scheduleRows != null && scheduleRows.isNotEmpty) {
      final imported = _parseScheduleRows(scheduleRows);
      event.schedule
        ..clear()
        ..addAll(imported);
      scheduleImported = imported.length;
      importedSheets.add('Schedule');
      notes.add('Schedule sheet imported.');
    } else {
      missingSheets.add('Schedule');
    }

    final gameModesRows = _sheetRowsByCandidateNames(excel, const [
      'GameModes',
      'Game Modes',
      'Modes',
      'game modes',
      'gamemodes',
      'modes',
    ]);
    if (gameModesRows != null && gameModesRows.isNotEmpty) {
      final imported = _parseGameModesRows(gameModesRows);
      event.gameModes
        ..clear()
        ..addAll(imported);
      gameModesImported = imported.length;
      importedSheets.add('GameModes');
      notes.add('GameModes sheet imported.');
    } else {
      missingSheets.add('GameModes');
    }

    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);

    final success = importedSheets.isNotEmpty;

    if (!success) {
      notes.add('No supported sheets were found in the workbook.');
    }

    return WorkbookImportResult(
      success: success,
      bookingsImported: bookingsImported,
      ticketsImported: ticketsImported,
      membersImported: membersImported,
      scheduleImported: scheduleImported,
      gameModesImported: gameModesImported,
      missingSheets: missingSheets,
      importedSheets: importedSheets,
      notes: notes,
    );
  }

  static Future<bool> importBookingsCsv(EventRecord event) async {
    final rows = await _pickTabularRows(
      candidateSheetNames: const ['Bookings', 'Booking'],
      requiredColumns: const [
        'Booking ID',
        'Booking Date',
        'Name',
        'First Name',
        'Last Name',
        'E-mail',
        'Total',
      ],
    );
    if (rows.isEmpty) return false;

    final imported = _parseBookingsRows(rows, event.name);

    event.bookings
      ..clear()
      ..addAll(imported);

    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);

    return imported.isNotEmpty;
  }

  static Future<bool> importTicketsCsv(EventRecord event) async {
    final rows = await _pickTabularRows(
      candidateSheetNames: const ['Tickets', 'Ticket'],
      requiredColumns: const [
        'Name',
        'Ticket Name',
        'Status',
        'Ticket Price',
        'Ticket Spaces',
        'Ticket Total',
      ],
    );
    if (rows.isEmpty) return false;

    final imported = _parseTicketsRows(rows);

    event.tickets
      ..clear()
      ..addAll(imported);

    BookingUtils.linkTicketsToBookings(event);
    BookingUtils.recalculateAllTotals(event);

    return imported.isNotEmpty;
  }

  static Future<bool> importMembersCsv(EventRecord event) async {
    final rows = await _pickTabularRows(
      candidateSheetNames: const ['Members', 'Member'],
      requiredColumns: const [
        'First Name',
        'Last Name',
        'Telephone No',
        'Email',
        'Membership Level',
      ],
    );
    if (rows.isEmpty) return false;

    final imported = _parseMembersRows(rows);

    event.members
      ..clear()
      ..addAll(imported);

    return imported.isNotEmpty;
  }

  static Future<bool> importScheduleCsv(EventRecord event) async {
    final rows = await _pickTabularRows(
      candidateSheetNames: const ['Schedule', 'Run Sheet', 'Timeline'],
      requiredColumns: const [
        'Time',
        'Activity',
      ],
    );
    if (rows.isEmpty) return false;

    final imported = _parseScheduleRows(rows);

    event.schedule
      ..clear()
      ..addAll(imported);

    return imported.isNotEmpty;
  }

  static Future<bool> importGameModesCsv(EventRecord event) async {
    final rows = await _pickTabularRows(
      candidateSheetNames: const ['GameModes', 'Game Modes', 'Modes'],
      requiredColumns: const [
        'Mode',
      ],
    );
    if (rows.isEmpty) return false;

    final imported = _parseGameModesRows(rows);

    event.gameModes
      ..clear()
      ..addAll(imported);

    return imported.isNotEmpty;
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

  static List<BookingRecord> _parseBookingsRows(
    List<List<dynamic>> rows,
    String fallbackEventName,
  ) {
    if (rows.isEmpty) return [];

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'Booking ID',
      'Booking Date',
      'Name',
      'First Name',
      'Last Name',
      'E-mail',
      'Total',
    ]);
    if (headerRowIndex == -1) return [];

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
    final fullNameIndex = _findColumnIndex(header, [
      'Name',
      'Full Name',
      'Booking Name',
      'Customer Name',
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
      'Transaction',
      'Transaction No',
      'Payment ID',
    ]);
    final paymentMethodIndex = _findColumnIndex(header, [
      'AOJ Payment Method',
      'Payment Method',
      'Method',
      'Gateway Used',
      'Gateway',
    ]);
    final paymentStatusIndex = _findColumnIndex(header, [
      'Payment Status',
      'Status',
      'AOJ Manual Paid',
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

      final fullName = _cellAt(row, fullNameIndex);
      final splitName = _splitFullName(fullName);
      final firstName = _cellAt(row, firstNameIndex).isEmpty
        ? splitName.$1
        : _cellAt(row, firstNameIndex);
      final lastName = _cellAt(row, lastNameIndex).isEmpty
        ? splitName.$2
        : _cellAt(row, lastNameIndex);
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

      final rawTotal = _normalizeMoney(_cellAt(row, totalIndex));
      final rawTotalPaid = _normalizeMoney(_cellAt(row, totalPaidIndex));
      final rawPaymentMethod = _cellAt(row, paymentMethodIndex);
      final rawPaymentStatus = _cellAt(row, paymentStatusIndex);
      final rawCheckInStatus = _cellAt(row, checkInStatusIndex);

      final resolvedPaymentStatus = _resolvePaymentStatus(
        paymentMethod: rawPaymentMethod,
        paymentStatus: rawPaymentStatus,
        total: rawTotal,
        totalPaid: rawTotalPaid,
      );

      final resolvedTotalPaid = _resolveTotalPaid(
        paymentMethod: rawPaymentMethod,
        paymentStatus: rawPaymentStatus,
        total: rawTotal,
        totalPaid: rawTotalPaid,
      );

      final importedPayments = <PaymentRecord>[];
      final totalPaidValue = double.tryParse(resolvedTotalPaid) ?? 0;
      if (totalPaidValue > 0) {
        importedPayments.add(
          PaymentRecord(
            id: _makeId('payment', imported.length),
            amount: resolvedTotalPaid,
            method: rawPaymentMethod.isEmpty ? 'Imported' : rawPaymentMethod,
            note: 'Imported from booking file',
            date: _cellAt(row, bookingDateIndex).isEmpty
                ? DateTime.now().toIso8601String()
                : _cellAt(row, bookingDateIndex),
          ),
        );
      }

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
              ? fallbackEventName
              : _cellAt(row, eventNameIndex),
          total: rawTotal,
          totalPaid: resolvedTotalPaid,
          transactionId: _cellAt(row, transactionIdIndex),
          paymentMethod: rawPaymentMethod,
          paymentStatus: resolvedPaymentStatus,
          checkInStatus:
              rawCheckInStatus.isEmpty ? 'Not Checked In' : rawCheckInStatus,
          notes: _cellAt(row, notesIndex),
          needsPickup: _looksTrue(_cellAt(row, pickupIndex)),
          needsTraining: _looksTrue(_cellAt(row, trainingIndex)),
          guestNames: _cellAt(row, guestNamesIndex),
          languagePreference: _cellAt(row, languageIndex),
          lunchOrderIds: [],
          ticketIds: [],
          sales: [],
          payments: importedPayments,
        ),
      );
    }

    return imported;
  }

  static List<TicketRecord> _parseTicketsRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'Name',
      'Ticket Name',
      'Status',
      'Ticket Price',
      'Ticket Spaces',
      'Ticket Total',
    ]);
    if (headerRowIndex == -1) return [];

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
      'Ticket Total',
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

      final cleanedPrice = _normalizeMoney(_cellAt(row, priceIndex));

      imported.add(
        TicketRecord(
          id: _makeId('ticket', imported.length),
          bookingId: _cellAt(row, bookingIdIndex),
          bookingName: bookingName,
          ticketName: ticketName.isEmpty ? 'Ticket' : ticketName,
          price: cleanedPrice.isEmpty ? '0' : cleanedPrice,
          spaces: _cellAt(row, spacesIndex).isEmpty
              ? '1'
              : _cellAt(row, spacesIndex),
          status: _cellAt(row, statusIndex).isEmpty
              ? 'Active'
              : _cellAt(row, statusIndex),
        ),
      );
    }

    return imported;
  }

  static List<MemberRecord> _parseMembersRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'First Name',
      'Last Name',
      'Telephone No',
      'Email',
      'Membership Level',
    ]);
    if (headerRowIndex == -1) return [];

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
      return [];
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

    return importedMembers;
  }

  static List<ScheduleRecord> _parseScheduleRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];

    final headerRowIndex = _findHeaderRowIndex(rows, const [
      'Time',
      'Activity',
    ]);
    if (headerRowIndex == -1) return [];

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
      return [];
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

    return importedSchedule;
  }

  static List<GameModeRecord> _parseGameModesRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];

    final headerRowIndex = rows.indexWhere(
      (row) => row.any((cell) => _cleanCell(cell).isNotEmpty),
    );
    if (headerRowIndex == -1) return [];

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

    return imported;
  }

  static List<List<dynamic>>? _sheetRowsByCandidateNames(
    Excel workbook,
    List<String> candidateNames,
  ) {
    for (final candidate in candidateNames) {
      final sheet = workbook.tables[candidate];
      if (sheet != null) {
        return _worksheetToRows(sheet);
      }
    }

    for (final entry in workbook.tables.entries) {
      final normalizedSheetName = _normalizeHeader(entry.key);
      for (final candidate in candidateNames) {
        if (normalizedSheetName == _normalizeHeader(candidate)) {
          return _worksheetToRows(entry.value);
        }
      }
    }

    return null;
  }

  static List<List<dynamic>> _worksheetToRows(Sheet sheet) {
    final rows = <List<dynamic>>[];

    for (final row in sheet.rows) {
      rows.add(
        row.map((cell) {
          if (cell == null) return '';
          final value = cell.value;
          return value?.toString() ?? '';
        }).toList(),
      );
    }

    return rows;
  }

  static Future<List<List<dynamic>>> _pickTabularRows({
    required List<String> candidateSheetNames,
    required List<String> requiredColumns,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return [];

    final extension = (file.extension ?? '').toLowerCase();
    if (extension == 'csv') {
      final text = _decodeCsvBytes(bytes);
      if (text.trim().isEmpty) return [];
      return _parseCsvRows(text);
    }

    try {
      final workbook = Excel.decodeBytes(bytes);

      final byName = _sheetRowsByCandidateNames(workbook, candidateSheetNames);
      if (byName != null && byName.isNotEmpty) {
        return byName;
      }

      final best = _bestSheetRowsByHeader(workbook, requiredColumns);
      return best ?? [];
    } catch (_) {
      return [];
    }
  }

  static List<List<dynamic>>? _bestSheetRowsByHeader(
    Excel workbook,
    List<String> requiredColumns,
  ) {
    List<List<dynamic>>? bestRows;
    int bestScore = -1;

    for (final sheet in workbook.tables.values) {
      final rows = _worksheetToRows(sheet);
      if (rows.isEmpty) continue;

      final headerRowIndex = _findHeaderRowIndex(rows, requiredColumns);
      if (headerRowIndex == -1) continue;

      final header = rows[headerRowIndex].map((e) => _cleanCell(e)).toList();
      int score = 0;
      for (final column in requiredColumns) {
        if (_findColumnIndex(header, [column]) != -1) {
          score++;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestRows = rows;
      }
    }

    return bestRows;
  }

  static Future<Uint8List?> _pickFileBytes(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return bytes;
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
    final latin1Text = latin1.decode(bytes, allowInvalid: true);
    if (latin1Text.contains('Â¥') ||
        latin1Text.contains('ï¿¥') ||
        latin1Text.contains('â‚¬') ||
        latin1Text.contains('ï»¿')) {
      return latin1Text
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .replaceAll('\ufeff', '')
          .replaceAll('ï»¿', '');
    }

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

      final fuzzyIndex = header.indexWhere((h) {
        final normalizedHeader = _normalizeHeader(h);
        return normalizedHeader.contains(normalizedCandidate) ||
            normalizedCandidate.contains(normalizedHeader);
      });

      if (fuzzyIndex != -1) return fuzzyIndex;
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

  static (String, String) _splitFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return ('', '');

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');

    return (parts.first, parts.skip(1).join(' '));
  }

  static String _cleanCell(dynamic value) {
    if (value == null) return '';
    return value.toString().replaceAll('\ufeff', '').trim();
  }

  static String _normalizeMoney(String raw) {
    return raw
        .replaceAll('\u00a5', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll('Â¥', '')
        .replaceAll('ï¿¥', '')
        .replaceAll(r'$', '')
        .replaceAll('£', '')
        .replaceAll('€', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^\d.\-]'), '')
        .trim();
  }

  static String _resolvePaymentStatus({
    required String paymentMethod,
    required String paymentStatus,
    required String total,
    required String totalPaid,
  }) {
    if (_isCardPayment(paymentMethod)) {
      return 'Paid';
    }

    if (_looksPaid(paymentStatus)) {
      return 'Paid';
    }

    final totalValue = double.tryParse(total) ?? 0;
    final totalPaidValue = double.tryParse(totalPaid) ?? 0;

    if (totalValue > 0 && totalPaidValue >= totalValue) {
      return 'Paid';
    }

    if (totalPaidValue > 0) {
      return 'Part Paid';
    }

    return 'Unpaid';
  }

  static String _resolveTotalPaid({
    required String paymentMethod,
    required String paymentStatus,
    required String total,
    required String totalPaid,
  }) {
    if (_isCardPayment(paymentMethod)) {
      return total;
    }

    if (_looksPaid(paymentStatus) && totalPaid.isEmpty) {
      return total;
    }

    return totalPaid;
  }

  static bool _isCardPayment(String raw) {
    final value = raw.trim().toLowerCase();
    return value.contains('credit') ||
        value.contains('card') ||
        value.contains('stripe') ||
        value.contains('visa') ||
        value.contains('mastercard') ||
        value.contains('amex') ||
        value.contains('クレジット');
  }

  static bool _looksPaid(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'paid' ||
        value == 'yes' ||
        value == 'y' ||
        value == 'true' ||
        value == '1' ||
        value == 'complete' ||
        value == 'completed';
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
