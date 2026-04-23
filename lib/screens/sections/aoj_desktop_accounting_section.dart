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
    );
  }
}
