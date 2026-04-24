part of '../aoj_desktop.dart';

extension _AojDesktopScheduleSection on _AOJDesktopState {
  Widget _buildScheduleSection(DesktopWindowData window) {
    return SchedulePanel(
      accent: window.accent,
      event: activeEvent,
      gameModes: activeEvent?.gameModes ?? const <GameModeRecord>[],
      onOpenGameMode: _openGameModeFromSchedule,
      onSave: _saveLocalState,
      onRefresh: () => _refresh(),
    );
  }
}
