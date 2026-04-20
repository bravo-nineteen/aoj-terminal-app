part of '../aoj_desktop.dart';

extension _AojDesktopGameModesSection on _AOJDesktopState {
  Widget _buildGameModesSection(DesktopWindowData window) {
    return GameModesPanel(
      accent: window.accent,
      event: activeEvent,
      modes: _filteredGameModes(),
      onSearchChanged: (v) {
        _refresh(() {
          gameModeSearch = v;
        });
      },
      onImportGameModes: _importGameModesCsv,
    );
  }
}
