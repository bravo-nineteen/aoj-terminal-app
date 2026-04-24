part of '../aoj_desktop.dart';

extension _AojDesktopMessagesSection on _AOJDesktopState {
  Widget _buildMessagesSection(DesktopWindowData window) {
    return MessagesPanel(
      accent: window.accent,
      activeEventId: appState.activeEventId,
    );
  }
}
