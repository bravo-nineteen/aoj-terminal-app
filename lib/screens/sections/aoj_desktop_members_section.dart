part of '../aoj_desktop.dart';

extension _AojDesktopMembersSection on _AOJDesktopState {
  Widget _buildMembersSection(DesktopWindowData window) {
    return MembersPanel(
      accent: window.accent,
      event: activeEvent,
      selectedMember: selectedMember,
      selectedMemberIndex: selectedMemberIndex,
      membershipLevels: membershipLevels,
      onAddMember: _addManualMember,
      onDeleteMember: _deleteSelectedMember,
      onSelectMember: (index) {
        _refresh(() {
          selectedMemberIndex = index;
        });
      },
      onSave: _saveLocalState,
      onRefresh: () => _refresh(),
    );
  }
}
