part of '../aoj_desktop.dart';

extension _AojDesktopBookingsSection on _AOJDesktopState {
  Widget _buildBookingsSection(DesktopWindowData window) {
    return BookingsPanel(
      accent: window.accent,
      appState: appState,
      event: activeEvent,
      groups: _groupedBookingsForActiveEvent(),
      selectedBookingIndex: selectedBookingIndex,
      checkInStatuses: checkInStatuses,
      paymentStatuses: paymentStatuses,
      onSetActiveEvent: (value) async {
        await _setActiveEvent(value);
        _refresh(() {
          selectedBookingIndex = 0;
        });
      },
      onSearchChanged: (v) {
        _refresh(() {
          bookingSearch = v;
          selectedBookingIndex = 0;
        });
      },
      onSelectBooking: (index) {
        _refresh(() {
          selectedBookingIndex = index;
        });
      },
      onQuickSetCheckInStatus: _quickSetCheckInStatus,
      onQuickSetPaymentStatus: _quickSetPaymentStatus,
      onCheckInAll: _checkInAllBookings,
      onOpenBookingEditor: _openBookingEditorWindow,
      onAddManualBooking: _showAddManualBookingDialog,
    );
  }
}
