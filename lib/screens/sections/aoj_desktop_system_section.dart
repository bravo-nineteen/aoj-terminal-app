part of '../aoj_desktop.dart';

extension _AojDesktopSystemSection on _AOJDesktopState {
  Widget _buildSystemSection(DesktopWindowData window) {
    return SystemPanel(
      accent: window.accent,
      appState: appState,
      activeEvent: activeEvent,
      systemStatus: systemStatus,
      exportStatus: exportStatus,
      syncStatus: syncStatus,
      onCreateEvent: _createEvent,
      onExportEvent: _exportActiveEventJson,
      onExportBookings: _exportBookingsCsv,
      onImportWorkbook: _importWorkbookXlsx,
      onImportBookings: _importBookingsCsv,
      onImportTickets: _importTicketsCsv,
      onImportMembers: _importMembersCsv,
      onImportSchedule: _importScheduleCsv,
      onImportGameModes: _importGameModesCsv,
      onImportFieldMap: _importFieldMap,
      onSyncPush: _syncPush,
      onSyncPull: _syncPull,
    );
  }
}
