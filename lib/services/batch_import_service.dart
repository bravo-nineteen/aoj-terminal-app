import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import 'csv_import_service.dart';

class BatchImportResult {
  final bool anySuccess;
  final int bookingsImported;
  final int ticketsImported;
  final int membersImported;
  final int scheduleImported;
  final int gameModesImported;
  final List<String> successMessages;
  final List<String> errorMessages;

  const BatchImportResult({
    required this.anySuccess,
    required this.bookingsImported,
    required this.ticketsImported,
    required this.membersImported,
    required this.scheduleImported,
    required this.gameModesImported,
    required this.successMessages,
    required this.errorMessages,
  });

  int get totalImported =>
      bookingsImported +
      ticketsImported +
      membersImported +
      scheduleImported +
      gameModesImported;
}

class BatchImportService {
  static Future<BatchImportResult> importMultipleFiles(
    EventRecord event,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
      allowMultiple: true,
      withData: true,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      return const BatchImportResult(
        anySuccess: false,
        bookingsImported: 0,
        ticketsImported: 0,
        membersImported: 0,
        scheduleImported: 0,
        gameModesImported: 0,
        successMessages: [],
        errorMessages: ['No files selected.'],
      );
    }

    final successMessages = <String>[];
    final errorMessages = <String>[];
    int bookingsImported = 0;
    int ticketsImported = 0;
    int membersImported = 0;
    int scheduleImported = 0;
    int gameModesImported = 0;

    for (final file in result.files) {
      try {
        final fileName = file.name.toLowerCase();
        final bytes = await _readFileBytes(file);
        if (bytes == null || bytes.isEmpty) {
          errorMessages.add('$fileName: Could not read file data.');
          continue;
        }

        final ext = (file.extension ?? '').toLowerCase();
        final rows = _parseFileToRows(bytes, fileName, ext);
        if (rows.isEmpty) {
          errorMessages.add('$fileName: No data rows found.');
          continue;
        }

        bool imported = false;

        if (_looksLikeBookings(fileName, rows)) {
          final parsed = CsvImportService.parseBookingsRows(rows, event.name);
          if (parsed.isNotEmpty) {
            event.bookings.addAll(parsed);
            bookingsImported += parsed.length;
            successMessages.add('$fileName: Imported ${parsed.length} bookings.');
            imported = true;
          }
        }

        if (_looksLikeTickets(fileName, rows)) {
          final parsed = CsvImportService.parseTicketsRows(rows);
          if (parsed.isNotEmpty) {
            event.tickets.addAll(parsed);
            ticketsImported += parsed.length;
            successMessages.add('$fileName: Imported ${parsed.length} tickets.');
            imported = true;
          }
        }

        if (_looksLikeMembers(fileName, rows)) {
          final parsed = CsvImportService.parseMembersRows(rows);
          if (parsed.isNotEmpty) {
            event.members.addAll(parsed);
            membersImported += parsed.length;
            successMessages.add('$fileName: Imported ${parsed.length} members.');
            imported = true;
          }
        }

        if (_looksLikeSchedule(fileName, rows)) {
          final parsed = CsvImportService.parseScheduleRows(rows);
          if (parsed.isNotEmpty) {
            event.schedule.addAll(parsed);
            scheduleImported += parsed.length;
            successMessages.add('$fileName: Imported ${parsed.length} schedule rows.');
            imported = true;
          }
        }

        if (_looksLikeGameModes(fileName, rows)) {
          final parsed = CsvImportService.parseGameModesRows(rows);
          if (parsed.isNotEmpty) {
            event.gameModes.addAll(parsed);
            gameModesImported += parsed.length;
            successMessages.add('$fileName: Imported ${parsed.length} game modes.');
            imported = true;
          }
        }

        if (!imported) {
          errorMessages.add('$fileName: No matching columns found.');
        }
      } catch (e) {
        errorMessages.add('${file.name}: $e');
      }
    }

    if (bookingsImported > 0 ||
        ticketsImported > 0 ||
        membersImported > 0 ||
        scheduleImported > 0 ||
        gameModesImported > 0) {
      BookingUtils.linkTicketsToBookings(event);
      BookingUtils.recalculateAllTotals(event);
    }

    return BatchImportResult(
      anySuccess:
          bookingsImported > 0 ||
          ticketsImported > 0 ||
          membersImported > 0 ||
          scheduleImported > 0 ||
          gameModesImported > 0,
      bookingsImported: bookingsImported,
      ticketsImported: ticketsImported,
      membersImported: membersImported,
      scheduleImported: scheduleImported,
      gameModesImported: gameModesImported,
      successMessages: successMessages,
      errorMessages: errorMessages,
    );
  }

  static Future<Uint8List?> _readFileBytes(PlatformFile file) async {
    final expectedSize = file.size;
    Uint8List? bestEffortBytes;

    final inMemoryBytes = file.bytes;
    if (inMemoryBytes != null && inMemoryBytes.isNotEmpty) {
      if (expectedSize > 0 && inMemoryBytes.length >= expectedSize) {
        return inMemoryBytes;
      }
      bestEffortBytes = inMemoryBytes;
    }

    final stream = file.readStream;
    if (stream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in stream) {
        builder.add(chunk);
      }
      final streamedBytes = builder.takeBytes();
      if (streamedBytes.isNotEmpty) {
        if (expectedSize > 0 && streamedBytes.length >= expectedSize) {
          return streamedBytes;
        }
        if (bestEffortBytes == null || streamedBytes.length > bestEffortBytes.length) {
          bestEffortBytes = streamedBytes;
        }
      }
    }

    try {
      final xFileBytes = await file.xFile.readAsBytes();
      if (xFileBytes.isNotEmpty) {
        if (expectedSize > 0 && xFileBytes.length >= expectedSize) {
          return xFileBytes;
        }
        if (bestEffortBytes == null || xFileBytes.length > bestEffortBytes.length) {
          bestEffortBytes = xFileBytes;
        }
      }
    } catch (_) {
      // Fall through to file path lookup.
    }

    final filePath = file.path;
    if (filePath != null && filePath.isNotEmpty) {
      final fsFile = File(filePath);
      if (await fsFile.exists()) {
        final pathBytes = await fsFile.readAsBytes();
        if (pathBytes.isNotEmpty) {
          if (expectedSize > 0 && pathBytes.length >= expectedSize) {
            return pathBytes;
          }
          if (bestEffortBytes == null || pathBytes.length > bestEffortBytes.length) {
            bestEffortBytes = pathBytes;
          }
        }
      }
    }

    return bestEffortBytes;
  }

  static List<List<dynamic>> _parseFileToRows(
    Uint8List bytes,
    String fileName,
    String extension,
  ) {
    return CsvImportService.tabularRowsFromBytes(
      bytes: bytes,
      extensionHint: extension,
      candidateSheetNames: const [],
      requiredColumns: const [],
    );
  }

  static bool _looksLikeBookings(String fileName, List<List<dynamic>> rows) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('booking') || nameLower.contains('order')) {
      return _hasColumns(rows, const ['Booking ID', 'Name', 'Email', 'Total']);
    }
    return false;
  }

  static bool _looksLikeTickets(String fileName, List<List<dynamic>> rows) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('ticket') || nameLower.contains('product')) {
      return _hasColumns(rows, const ['Ticket Name', 'Price', 'Status']);
    }
    return false;
  }

  static bool _looksLikeMembers(String fileName, List<List<dynamic>> rows) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('member') || nameLower.contains('personnel')) {
      return _hasColumns(rows, const ['First Name', 'Last Name', 'Email']);
    }
    return false;
  }

  static bool _looksLikeSchedule(String fileName, List<List<dynamic>> rows) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('schedule') ||
        nameLower.contains('timeline') ||
        nameLower.contains('runsheet')) {
      return _hasColumns(rows, const ['Time', 'Activity']);
    }
    return false;
  }

  static bool _looksLikeGameModes(String fileName, List<List<dynamic>> rows) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('mode') || nameLower.contains('scenario')) {
      return _hasColumns(rows, const ['Mode']);
    }
    return false;
  }

  static bool _hasColumns(
    List<List<dynamic>> rows,
    List<String> requiredColumns,
  ) {
    if (rows.isEmpty) return false;

    final firstRow = rows.first;
    final header = firstRow.map((e) => e.toString().toLowerCase()).toList();

    for (final col in requiredColumns) {
      final colLower = col.toLowerCase();
      final found = header.any((h) => h.contains(colLower) || colLower.contains(h));
      if (!found) return false;
    }

    return true;
  }
}
