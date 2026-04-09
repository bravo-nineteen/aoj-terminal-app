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
          child: Text('Import Bookings CSV'),
        ),
        PopupMenuItem(
          value: _ImportAction.ticketsCsv,
          child: Text('Import Tickets CSV'),
        ),
        PopupMenuItem(
          value: _ImportAction.membersCsv,
          child: Text('Import Members CSV'),
        ),
        PopupMenuItem(
          value: _ImportAction.scheduleCsv,
          child: Text('Import Schedule CSV'),
        ),
        PopupMenuItem(
          value: _ImportAction.gameModesCsv,
          child: Text('Import Game Modes CSV'),
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

    try {
      switch (action) {
        case _ImportAction.workbook:
          ok = await CsvImportService.importWorkbookXlsx(event);
          successMessage = 'Workbook imported successfully.';
          failureMessage = 'Workbook import failed.';
          break;

        case _ImportAction.bookingsCsv:
          ok = await CsvImportService.importBookingsCsv(event);
          successMessage = 'Bookings CSV imported successfully.';
          failureMessage = 'Bookings CSV import failed.';
          break;

        case _ImportAction.ticketsCsv:
          ok = await CsvImportService.importTicketsCsv(event);
          successMessage = 'Tickets CSV imported successfully.';
          failureMessage = 'Tickets CSV import failed.';
          break;

        case _ImportAction.membersCsv:
          ok = await CsvImportService.importMembersCsv(event);
          successMessage = 'Members CSV imported successfully.';
          failureMessage = 'Members CSV import failed.';
          break;

        case _ImportAction.scheduleCsv:
          ok = await CsvImportService.importScheduleCsv(event);
          successMessage = 'Schedule CSV imported successfully.';
          failureMessage = 'Schedule CSV import failed.';
          break;

        case _ImportAction.gameModesCsv:
          ok = await CsvImportService.importGameModesCsv(event);
          successMessage = 'Game modes CSV imported successfully.';
          failureMessage = 'Game modes CSV import failed.';
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(failureMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
