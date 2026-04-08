import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/aoj_models.dart';

class CsvImportService {
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
      final dateOfBirth = _cellAt(row, dobIndex);
      final gender = _normalizeGender(_cellAt(row, genderIndex));
      final telephone = _cellAt(row, telephoneIndex);
      final email = _cellAt(row, emailIndex);
      final membershipLevel = _normalizeMembershipLevel(
        _cellAt(row, membershipLevelIndex),
      );

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
          dateOfBirth: dateOfBirth,
          gender: gender,
          telephone: telephone,
          email: email,
          membershipLevel: membershipLevel,
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

    return raw.trim();
  }

  static String _makeId(String prefix, int index) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$index';
  }
}
