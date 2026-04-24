part of '../aoj_desktop.dart';

extension _AojDesktopAccountingSection on _AOJDesktopState {
  Widget _buildAccountingSection(DesktopWindowData window) {
    return AccountingPanel(
      accent: window.accent,
      event: activeEvent,
      onExportFullCsv: _exportActiveEventFullCsv,
      onAddExpense: _showAddExpenseDialog,
      onDeleteExpense: _deleteExpenseFromActiveEvent,
      onExportSummary: _exportEventSummary,
      onAddAccountingNote: _addAccountingNote,
      onAddExpenseNote: _addExpenseNote,
    );
  }

  Future<void> _addAccountingNote(String body) async {
    final event = activeEvent;
    if (event == null) return;
    final author = await DeviceIdentityService.getUsername();
    _updateDesktopState(() {
      event.accountingNotes.add(
        NoteRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          author: author.isEmpty ? 'Unknown' : author,
          body: body,
          createdAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    });
    await _saveLocalState();
  }

  Future<void> _addExpenseNote(String expenseId, String body) async {
    final event = activeEvent;
    if (event == null) return;
    final expense = event.expenses.where((e) => e.id == expenseId).firstOrNull;
    if (expense == null) return;
    final author = await DeviceIdentityService.getUsername();
    _updateDesktopState(() {
      expense.notes.add(
        NoteRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          author: author.isEmpty ? 'Unknown' : author,
          body: body,
          createdAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    });
    await _saveLocalState();
  }
}
