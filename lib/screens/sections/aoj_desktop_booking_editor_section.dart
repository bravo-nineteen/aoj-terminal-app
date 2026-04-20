part of '../aoj_desktop.dart';

extension _AojDesktopBookingEditorSection on _AOJDesktopState {
  Widget _buildBookingEditorSection(DesktopWindowData window) {
    final primaryId = window.id.replaceFirst('booking_editor::', '');
    final event = activeEvent;
    final group = _findBookingGroupByPrimaryId(primaryId);

    if (event == null || group == null) {
      return const Center(
        child: Text('BOOKING NO LONGER AVAILABLE'),
      );
    }

    return BookingEditorPanel(
      accent: window.accent,
      event: event,
      group: group,
      membershipLevel: _membershipLevelForGroup(event, group),
      paymentStatuses: paymentStatuses,
      checkInStatuses: checkInStatuses,
      onToggleCheckIn: _toggleCheckInForGroup,
      onEditContact: _showEditContactDialog,
      onDeleteGroup: _deleteBookingGroup,
      onAddTicket: _showAddTicketDialog,
      onAddPayment: _showAddPaymentDialog,
      onDeletePayment: _deletePaymentFromGroup,
      onAddSale: _showAddSaleDialog,
      onDeleteSale: _deleteSaleFromGroup,
      onSaveGroup: _saveGroupedBooking,
      onSave: _saveLocalState,
      onRefresh: () => _refresh(),
      onOpenTicketEditor: _openTicketEditorWindow,
    );
  }
}
