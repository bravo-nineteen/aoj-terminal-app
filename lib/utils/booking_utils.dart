
import '../models/aoj_models.dart';
import 'money_utils.dart';

class BookingUtils {
  static double ticketsTotal(BookingGroup group) {
    return group.tickets
        .where((t) => t.status != 'Cancelled')
        .fold(0.0, (sum, t) => sum + MoneyUtils.parseMoney(t.price));
  }

  static double salesTotal(BookingGroup group) {
    return group.primary.sales.fold(0.0, (sum, s) => sum + MoneyUtils.parseMoney(s.price));
  }

  static double paymentsTotal(BookingGroup group) {
    return group.primary.payments.fold(0.0, (sum, p) => sum + MoneyUtils.parseMoney(p.amount));
  }

  static double grandTotal(BookingGroup group) {
    return ticketsTotal(group) + salesTotal(group);
  }

  static double balance(BookingGroup group) {
    return grandTotal(group) - paymentsTotal(group);
  }

  static List<BookingGroup> groupedBookingsForEvent(EventRecord event) {
    final Map<String, List<BookingRecord>> grouped = {};

    for (final booking in event.bookings) {
      final key = bookingGroupKey(booking);
      grouped.putIfAbsent(key, () => []).add(booking);
    }

    final result = grouped.entries.map((entry) {
      final rows = entry.value;
      final primary = rows.first;

      final ticketIds = <String>{};
      for (final row in rows) {
        ticketIds.addAll(row.ticketIds);
      }

      final tickets = event.tickets.where((t) {
        if (ticketIds.contains(t.id)) return true;
        if (primary.bookingId.isNotEmpty && t.bookingId.isNotEmpty) {
          if (primary.bookingId == t.bookingId) return true;
        }
        return t.bookingName.trim().toLowerCase() ==
            primary.fullName.trim().toLowerCase();
      }).toList();

      return BookingGroup(
        key: entry.key,
        primary: primary,
        rows: rows,
        tickets: tickets,
      );
    }).toList();

    result.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return result;
  }

  static String bookingGroupKey(BookingRecord booking) {
    final bookingId = booking.bookingId.trim().toLowerCase();
    final email = booking.email.trim().toLowerCase();
    final name = booking.fullName.trim().toLowerCase();
    final eventName = booking.event.trim().toLowerCase();

    if (bookingId.isNotEmpty) return 'booking:$eventName:$bookingId';
    if (email.isNotEmpty) return 'email:$eventName:$email';
    return 'name:$eventName:$name';
  }

  static void linkTicketsToBookings(EventRecord event) {
    for (final booking in event.bookings) {
      booking.ticketIds.clear();
    }

    for (final ticket in event.tickets) {
      final matches = event.bookings.where((booking) {
        final bookingName = booking.fullName.trim().toLowerCase();
        final ticketName = ticket.bookingName.trim().toLowerCase();

        if (ticket.bookingId.isNotEmpty && booking.bookingId.isNotEmpty) {
          if (ticket.bookingId == booking.bookingId) return true;
        }

        return bookingName == ticketName;
      }).toList();

      if (matches.isNotEmpty) {
        matches.first.ticketIds.add(ticket.id);
      }
    }
  }

  static bool looksTrue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized == 'yes' ||
        normalized == 'y' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'checked in' ||
        normalized == 'paid';
  }

  static bool ticketIsActive(TicketRecord ticket) {
    final status = ticket.status.trim().toLowerCase();
    return status != 'cancelled' && status != 'refunded' && status != 'void';
  }

  static bool ticketIsRental(TicketRecord ticket) {
    final name = ticket.ticketName.toLowerCase();
    return name.contains('rental') ||
        name.contains('gun set') ||
        name.contains('full set') ||
        name.contains('rental set');
  }

  static int ticketQuantity(TicketRecord ticket) {
    final cleaned = ticket.spaces.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? 1;
  }

  static int groupPersonCount(BookingGroup group) {
    final guestCount = guestListFromRaw(group.guestNames).length;
    return 1 + guestCount;
  }

  static int groupRentalCount(BookingGroup group) {
    return group.tickets
        .where((t) => ticketIsActive(t) && ticketIsRental(t))
        .fold<int>(0, (sum, t) => sum + ticketQuantity(t));
  }

  static int eventBookedPersons(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<int>(0, (sum, g) => sum + groupPersonCount(g));
  }

  static double eventTicketValue(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<double>(0, (sum, g) => sum + ticketsTotal(g));
  }

  static double eventSalesValue(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<double>(0, (sum, g) => sum + salesTotal(g));
  }

  static int eventRentalCount(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<int>(0, (sum, g) => sum + groupRentalCount(g));
  }

  static List<BookingGroup> pickupGroups(EventRecord event) {
    return groupedBookingsForEvent(event).where((g) => g.needsPickup).toList();
  }

  static List<BookingGroup> trainingGroups(EventRecord event) {
    return groupedBookingsForEvent(event).where((g) => g.needsTraining).toList();
  }

  static List<String> guestListFromRaw(String raw) {
    return raw
        .split(RegExp(r'[\n;/]+'))
        .expand((part) => part.split(','))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static void recalculateAllTotals(EventRecord event) {
    final groups = groupedBookingsForEvent(event);
    for (final group in groups) {
      final total = MoneyUtils.formatMoney(grandTotal(group));
      final totalPaid = MoneyUtils.formatMoney(paymentsTotal(group));
      final balanceValue = grandTotal(group) - paymentsTotal(group);
      final nextStatus = paymentsTotal(group) <= 0
          ? 'Unpaid'
          : balanceValue <= 0
              ? 'Paid'
              : 'Part Paid';
      for (final row in group.rows) {
        row.total = total;
        row.totalPaid = totalPaid;
        row.paymentStatus = nextStatus;
      }
    }
  }
}
