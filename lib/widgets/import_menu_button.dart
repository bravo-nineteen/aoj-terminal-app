import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
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
          value: _ImportAction.workbook,
          child: Text('Import Workbook (.xlsx)'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ImportAction.bookingsCsv,
          child: Text('Import Bookings (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.ticketsCsv,
          child: Text('Import Tickets (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.membersCsv,
          child: Text('Import Members (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.scheduleCsv,
          child: Text('Import Schedule (CSV/Excel)'),
        ),
        PopupMenuItem(
          value: _ImportAction.gameModesCsv,
          child: Text('Import Game Modes (CSV/Excel)'),
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
    final messenger = ScaffoldMessenger.of(context);

    _showLoadingDialog(context);

    bool ok = false;
    String successMessage = '';
    String failureMessage = 'Import failed or file was empty.';
    WorkbookImportResult? workbookResult;

    try {
      switch (action) {
        case _ImportAction.workbook:
          workbookResult = await CsvImportService.importWorkbookXlsx(event);
          ok = workbookResult.success;
          successMessage = 'Workbook imported successfully.';
          failureMessage = 'Workbook import failed.';
          break;

        case _ImportAction.bookingsCsv:
          ok = await CsvImportService.importBookingsCsv(event);
          successMessage = 'Bookings imported successfully.';
          failureMessage = 'Bookings import failed.';
          break;

        case _ImportAction.ticketsCsv:
          ok = await CsvImportService.importTicketsCsv(event);
          successMessage = 'Tickets imported successfully.';
          failureMessage = 'Tickets import failed.';
          break;

        case _ImportAction.membersCsv:
          ok = await CsvImportService.importMembersCsv(event);
          successMessage = 'Members imported successfully.';
          failureMessage = 'Members import failed.';
          break;

        case _ImportAction.scheduleCsv:
          ok = await CsvImportService.importScheduleCsv(event);
          successMessage = 'Schedule imported successfully.';
          failureMessage = 'Schedule import failed.';
          break;

        case _ImportAction.gameModesCsv:
          ok = await CsvImportService.importGameModesCsv(event);
          successMessage = 'Game modes imported successfully.';
          failureMessage = 'Game modes import failed.';
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

    if (ok) {
      onImportComplete?.call();

      if (action == _ImportAction.workbook &&
          workbookResult != null &&
          context.mounted) {
        await _showWorkbookSummaryDialog(context, workbookResult);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else {
      if (action == _ImportAction.workbook &&
          workbookResult != null &&
          context.mounted) {
        await _showWorkbookSummaryDialog(context, workbookResult);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(failureMessage),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
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
  workbook,
  bookingsCsv,
  ticketsCsv,
  membersCsv,
  scheduleCsv,
  gameModesCsv,
  fieldMap,
}
