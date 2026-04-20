part of '../aoj_desktop.dart';

extension _AojDesktopEventSection on _AOJDesktopState {
  Widget _buildEventSection(DesktopWindowData window) {
    return EventPanel(
      accent: window.accent,
      appState: appState,
      event: activeEvent,
      onSetActiveEvent: _setActiveEvent,
      onDeleteEvent: _deleteActiveEvent,
      onSave: _saveLocalState,
      onRefresh: () => _refresh(),
    );
  }
}
