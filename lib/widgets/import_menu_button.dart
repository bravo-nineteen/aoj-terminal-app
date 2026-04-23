import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../services/batch_import_service.dart';
import '../services/csv_import_service.dart';

class ImportMenuButton extends StatelessWidget {
  final EventRecord event;
  final VoidCallback? onImportComplete;

  const ImportMenuButton({
    super.key,
    required this.event,
    this.onImportComplete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ImportAction>(
      tooltip: 'Import Data',
      color: const Color(0xFF1A221B),
      surfaceTintColor: Colors.transparent,
      onSelected: (action) => _handleImport(context, action),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ImportAction.multipleFiles,
          child: Text('Import Multiple Files (CSV/XLSX)'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ImportAction.workbook,
          child: Text('Import Workbook (.xlsx)'),
        ),
        PopupMenuItem(
          value: _ImportAction.workbookGoogle,
          child: Text('Import Workbook (Google Sheets URL)'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ImportAction.bookingsCsv,
          child: Text('Import Bookings (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.bookingsGoogle,
          child: Text('Import Bookings (Google Sheets URL)'),
        ),
        PopupMenuItem(
          value: _ImportAction.ticketsCsv,
          child: Text('Import Tickets (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.ticketsGoogle,
          child: Text('Import Tickets (Google Sheets URL)'),
        ),
        PopupMenuItem(
          value: _ImportAction.membersCsv,
          child: Text('Import Members (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.membersGoogle,
          child: Text('Import Members (Google Sheets URL)'),
        ),
        PopupMenuItem(
          value: _ImportAction.scheduleCsv,
          child: Text('Import Schedule (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.scheduleGoogle,
          child: Text('Import Schedule (Google Sheets URL)'),
        ),
        PopupMenuItem(
          value: _ImportAction.gameModesCsv,
          child: Text('Import Game Modes (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.gameModesGoogle,
          child: Text('Import Game Modes (Google Sheets URL)'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ImportAction.fieldMap,
          child: Text('Import Field Map'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A332B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF55624F)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Import',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImport(
    BuildContext context,
    _ImportAction action,
  ) async {
    String? sourceUrl;
    if (_isGoogleUrlAction(action)) {
      sourceUrl = await _promptForSourceUrl(
        context,
        title: _googleActionTitle(action),
        hintText: action == _ImportAction.workbookGoogle
            ? 'Paste Google Sheets URL'
            : 'Paste sheet URL or CSV export URL',
      );
      if (sourceUrl == null) return;
    }

    if (!context.mounted) return;

    _showLoadingDialog(context);

    bool ok = false;
    String successMessage = '';
    String failureMessage = 'Import failed or file was empty.';
    WorkbookImportResult? workbookResult;

    try {
      switch (action) {
        case _ImportAction.multipleFiles:
          final batchResult =
              await BatchImportService.importMultipleFiles(event);
          ok = batchResult.anySuccess;
          successMessage =
              'Imported ${batchResult.totalImported} items from ${batchResult.successMessages.length} files.';
          failureMessage = batchResult.errorMessages.isNotEmpty
              ? batchResult.errorMessages.join('\n')
              : 'No files imported.';
          if (context.mounted &&
              (batchResult.successMessages.isNotEmpty ||
                  batchResult.errorMessages.isNotEmpty)) {
            Navigator.of(context, rootNavigator: true).pop();
            if (batchResult.anySuccess) onImportComplete?.call();
            await _showBatchResultDialog(context, batchResult);
            return;
          }
          break;

        case _ImportAction.workbook:
          workbookResult = await CsvImportService.importWorkbookXlsx(event);
          ok = workbookResult.success;
          successMessage = 'Workbook imported successfully.';
          failureMessage = 'Workbook import failed.';
          break;

        case _ImportAction.workbookGoogle:
          workbookResult = await CsvImportService.importWorkbookFromUrl(
            event,
            sourceUrl!,
          );
          ok = workbookResult.success;
          successMessage = 'Workbook imported successfully.';
          failureMessage =
              'Workbook import failed. Verify the sheet is shared to Anyone with the link.';
          break;

        case _ImportAction.bookingsCsv:
          ok = await CsvImportService.importBookingsCsv(event);
          successMessage = 'Bookings imported successfully.';
          failureMessage = 'Bookings import failed.';
          break;

        case _ImportAction.bookingsGoogle:
          ok = await CsvImportService.importBookingsFromUrl(event, sourceUrl!);
          successMessage = 'Bookings imported successfully.';
          failureMessage =
              'Bookings import failed. Verify the source link is publicly accessible.';
          break;

        case _ImportAction.ticketsCsv:
          ok = await CsvImportService.importTicketsCsv(event);
          successMessage = 'Tickets imported successfully.';
          failureMessage = 'Tickets import failed.';
          break;

        case _ImportAction.ticketsGoogle:
          ok = await CsvImportService.importTicketsFromUrl(event, sourceUrl!);
          successMessage = 'Tickets imported successfully.';
          failureMessage =
              'Tickets import failed. Verify the source link is publicly accessible.';
          break;

        case _ImportAction.membersCsv:
          ok = await CsvImportService.importMembersCsv(event);
          successMessage = 'Members imported successfully.';
          failureMessage = 'Members import failed.';
          break;

        case _ImportAction.membersGoogle:
          ok = await CsvImportService.importMembersFromUrl(event, sourceUrl!);
          successMessage = 'Members imported successfully.';
          failureMessage =
              'Members import failed. Verify the source link is publicly accessible.';
          break;

        case _ImportAction.scheduleCsv:
          ok = await CsvImportService.importScheduleCsv(event);
          successMessage = 'Schedule imported successfully.';
          failureMessage = 'Schedule import failed.';
          break;

        case _ImportAction.scheduleGoogle:
          ok = await CsvImportService.importScheduleFromUrl(event, sourceUrl!);
          successMessage = 'Schedule imported successfully.';
          failureMessage =
              'Schedule import failed. Verify the source link is publicly accessible.';
          break;

        case _ImportAction.gameModesCsv:
          ok = await CsvImportService.importGameModesCsv(event);
          successMessage = 'Game modes imported successfully.';
          failureMessage = 'Game modes import failed.';
          break;

        case _ImportAction.gameModesGoogle:
          ok = await CsvImportService.importGameModesFromUrl(event, sourceUrl!);
          successMessage = 'Game modes imported successfully.';
          failureMessage =
              'Game modes import failed. Verify the source link is publicly accessible.';
          break;

        case _ImportAction.fieldMap:
          ok = await CsvImportService.importFieldMap(event);
          successMessage = 'Field map imported successfully.';
          failureMessage = 'Field map import failed.';
          break;
      }
    } catch (e) {
      ok = false;
      failureMessage = 'Import error: $e';
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return;

    if (ok) {
      onImportComplete?.call();

      if ((action == _ImportAction.workbook ||
              action == _ImportAction.workbookGoogle) &&
          workbookResult != null &&
          context.mounted) {
        await _showWorkbookSummaryDialog(context, workbookResult);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else {
      if ((action == _ImportAction.workbook ||
              action == _ImportAction.workbookGoogle) &&
          workbookResult != null &&
          context.mounted) {
        await _showWorkbookSummaryDialog(context, workbookResult);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  bool _isGoogleUrlAction(_ImportAction action) {
    return action == _ImportAction.workbookGoogle ||
        action == _ImportAction.bookingsGoogle ||
        action == _ImportAction.ticketsGoogle ||
        action == _ImportAction.membersGoogle ||
        action == _ImportAction.scheduleGoogle ||
        action == _ImportAction.gameModesGoogle;
  }

  String _googleActionTitle(_ImportAction action) {
    switch (action) {
      case _ImportAction.workbookGoogle:
        return 'Import Workbook from Google Sheets';
      case _ImportAction.bookingsGoogle:
        return 'Import Bookings from Google Sheets';
      case _ImportAction.ticketsGoogle:
        return 'Import Tickets from Google Sheets';
      case _ImportAction.membersGoogle:
        return 'Import Members from Google Sheets';
      case _ImportAction.scheduleGoogle:
        return 'Import Schedule from Google Sheets';
      case _ImportAction.gameModesGoogle:
        return 'Import Game Modes from Google Sheets';
      case _ImportAction.workbook:
      case _ImportAction.bookingsCsv:
      case _ImportAction.ticketsCsv:
      case _ImportAction.membersCsv:
      case _ImportAction.scheduleCsv:
      case _ImportAction.gameModesCsv:
      case _ImportAction.fieldMap:
      case _ImportAction.multipleFiles:
        return 'Import from Google Sheets';
    }
  }

  Future<void> _showBatchResultDialog(
    BuildContext context,
    BatchImportResult result,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A221B),
          title: Text(
            result.anySuccess
                ? 'Batch Import Complete'
                : 'Batch Import Results',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white70, height: 1.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result.bookingsImported > 0)
                    _summaryRow('Bookings', result.bookingsImported),
                  if (result.ticketsImported > 0)
                    _summaryRow('Tickets', result.ticketsImported),
                  if (result.membersImported > 0)
                    _summaryRow('Members', result.membersImported),
                  if (result.scheduleImported > 0)
                    _summaryRow('Schedule', result.scheduleImported),
                  if (result.gameModesImported > 0)
                    _summaryRow('Game Modes', result.gameModesImported),
                  if (result.totalImported > 0) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Total imported: ${result.totalImported}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (result.successMessages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Files processed:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...result.successMessages.map((msg) => Text('✓ $msg')),
                  ],
                  if (result.errorMessages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Issues:',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...result.errorMessages.map(
                      (msg) => Text(
                        '⚠ $msg',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(_).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _promptForSourceUrl(
    BuildContext context, {
    required String title,
    required String hintText,
  }) async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A221B),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white38),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text.trim(),
              ),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          backgroundColor: Color(0xFF1A221B),
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Importing...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWorkbookSummaryDialog(
    BuildContext context,
    WorkbookImportResult result,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A221B),
          title: Text(
            result.success
                ? 'Workbook Import Complete'
                : 'Workbook Import Failed',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white70, height: 1.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Bookings', result.bookingsImported),
                  _summaryRow('Tickets', result.ticketsImported),
                  _summaryRow('Members', result.membersImported),
                  _summaryRow('Schedule', result.scheduleImported),
                  _summaryRow('Game Modes', result.gameModesImported),
                  const SizedBox(height: 14),
                  Text(
                    'Total imported: ${result.totalImported}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result.importedSheets.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Imported sheets:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...result.importedSheets.map(
                      (sheet) => Text('• $sheet'),
                    ),
                  ],
                  if (result.missingSheets.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Missing sheets:',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...result.missingSheets.map(
                      (sheet) => Text(
                        '• $sheet',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  ],
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Notes:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...result.notes.map((note) => Text('• $note')),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ImportAction {
  multipleFiles,
  workbook,
  workbookGoogle,
  bookingsCsv,
  bookingsGoogle,
  ticketsCsv,
  ticketsGoogle,
  membersCsv,
  membersGoogle,
  scheduleCsv,
  scheduleGoogle,
  gameModesCsv,
  gameModesGoogle,
  fieldMap,
}
