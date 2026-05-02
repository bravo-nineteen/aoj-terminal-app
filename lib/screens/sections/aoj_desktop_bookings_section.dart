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
      selectedPaymentFilter: bookingPaymentFilter,
      selectedTicketTypeFilter: bookingTicketTypeFilter,
      onSetActiveEvent: (value) async {
        await _setActiveEvent(value);
        _refresh(() {
          bookingPaymentFilter = 'All Payments';
          bookingTicketTypeFilter = 'All Ticket Types';
          selectedBookingIndex = 0;
        });
      },
      onSearchChanged: (v) {
        _refresh(() {
          bookingSearch = v;
          selectedBookingIndex = 0;
        });
      },
      onPaymentFilterChanged: (value) {
        _refresh(() {
          bookingPaymentFilter = value;
          selectedBookingIndex = 0;
        });
      },
      onTicketTypeFilterChanged: (value) {
        _refresh(() {
          bookingTicketTypeFilter = value;
          selectedBookingIndex = 0;
        });
      },
      onSelectBooking: (index) {
        _refresh(() {
          selectedBookingIndex = index;
        });
      },
      onQuickSetCheckInStatus: _quickSetCheckInStatus,
      onCheckInAll: _checkInAllBookings,
      onOpenBookingEditor: _openBookingEditorWindow,
      onAddManualBooking: _showAddManualBookingDialog,
    );
  }
}
