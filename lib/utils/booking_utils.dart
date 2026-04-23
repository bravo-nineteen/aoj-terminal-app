import '../models/aoj_models.dart';
import 'money_utils.dart';

class LunchBreakdownItem {
  final LunchOptionRecord option;
  final int count;

  const LunchBreakdownItem({
    required this.option,
    required this.count,
  });
}

class BookingUtils {
  static double ticketsTotal(BookingGroup group) {
    return group.tickets
        .where(ticketIsActive)
        .fold<double>(
          0.0,
          (sum, ticket) =>
              sum + (MoneyUtils.parseMoney(ticket.price) * ticketQuantity(ticket)),
        );
  }

  static double salesTotal(BookingGroup group) {
    return group.primary.sales.fold<double>(
      0.0,
      (sum, sale) => sum + MoneyUtils.parseMoney(sale.price),
    );
  }

  static double paymentsTotal(BookingGroup group) {
    return group.primary.payments.fold<double>(0.0, (sum, payment) {
      final amount = MoneyUtils.parseMoney(payment.amount);
      if (payment.method.trim().toLowerCase() == 'refund') return sum - amount;
      return sum + amount;
    });
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

      final tickets = event.tickets.where((ticket) {
        if (ticketIds.contains(ticket.id)) return true;

        if (primary.bookingId.isNotEmpty && ticket.bookingId.isNotEmpty) {
          if (primary.bookingId.trim().toLowerCase() ==
              ticket.bookingId.trim().toLowerCase()) {
            return true;
          }
        }

        return ticket.bookingName.trim().toLowerCase() ==
            primary.fullName.trim().toLowerCase();
      }).toList();

      return BookingGroup(
        key: entry.key,
        primary: primary,
        rows: rows,
        tickets: tickets,
      );
    }).toList();

    result.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

    return result;
  }

  static String bookingGroupKey(BookingRecord booking) {
    final bookingId = booking.bookingId.trim().toLowerCase();
    final email = booking.email.trim().toLowerCase();
    final phone = booking.phone.trim().toLowerCase();
    final name = booking.fullName.trim().toLowerCase();
    final eventName = booking.event.trim().toLowerCase();

    if (bookingId.isNotEmpty) return 'booking:$eventName:$bookingId';
    if (email.isNotEmpty) return 'email:$eventName:$email';
    if (phone.isNotEmpty) return 'phone:$eventName:$phone';
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
          if (ticket.bookingId.trim().toLowerCase() ==
              booking.bookingId.trim().toLowerCase()) {
            return true;
          }
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
    final parsed = int.tryParse(cleaned) ?? 1;
    return parsed <= 0 ? 1 : parsed;
  }

  static int groupPersonCount(BookingGroup group) {
    final guestCount = guestListFromRaw(group.guestNames).length;
    return 1 + guestCount;
  }

  static int groupRentalCount(BookingGroup group) {
    return group.tickets
        .where((ticket) => ticketIsActive(ticket) && ticketIsRental(ticket))
        .fold<int>(0, (sum, ticket) => sum + ticketQuantity(ticket));
  }

  static int groupTicketQuantityTotal(BookingGroup group) {
    return group.tickets
        .where(ticketIsActive)
        .fold<int>(0, (sum, ticket) => sum + ticketQuantity(ticket));
  }

  static int eventBookedPersons(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<int>(0, (sum, group) => sum + groupPersonCount(group));
  }

  static double eventTicketValue(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<double>(0, (sum, group) => sum + ticketsTotal(group));
  }

  static double eventSalesValue(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<double>(0, (sum, group) => sum + salesTotal(group));
  }

  static int eventRentalCount(EventRecord event) {
    return groupedBookingsForEvent(event)
        .fold<int>(0, (sum, group) => sum + groupRentalCount(group));
  }

  static List<BookingGroup> pickupGroups(EventRecord event) {
    return groupedBookingsForEvent(event)
        .where((group) => group.rows.any((row) => row.needsPickup))
        .toList();
  }

  static List<BookingGroup> trainingGroups(EventRecord event) {
    return groupedBookingsForEvent(event)
        .where((group) => group.rows.any((row) => row.needsTraining))
        .toList();
  }

  static List<String> pickupNames(EventRecord event) {
    return pickupGroups(event)
        .map((group) => group.displayName.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static List<String> trainingNames(EventRecord event) {
    return trainingGroups(event)
        .map((group) => group.displayName.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static List<String> guestListFromRaw(String raw) {
    return raw
        .split(RegExp(r'[\n;/]+'))
        .expand((part) => part.split(','))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static double eventTicketCostTotal(EventRecord event) {
    final ticketCostPerPerson = MoneyUtils.parseMoney(event.ticketCostPerPerson);
    final bookedPersons = eventBookedPersons(event);
    return ticketCostPerPerson * bookedPersons;
  }

  static double eventEstimatedProfit(EventRecord event) {
    return eventTicketValue(event) - eventTicketCostTotal(event) + eventSalesValue(event);
  }

  static List<LunchBreakdownItem> lunchBreakdown(EventRecord event) {
    final counts = <String, int>{
      for (final option in event.lunchOptions) option.id: 0,
    };

    for (final group in groupedBookingsForEvent(event)) {
      final unique = group.primary.lunchOrderIds.toSet();
      for (final optionId in unique) {
        if (!counts.containsKey(optionId)) continue;
        counts[optionId] = (counts[optionId] ?? 0) + 1;
      }
    }

    return event.lunchOptions
        .map(
          (option) => LunchBreakdownItem(
            option: option,
            count: counts[option.id] ?? 0,
          ),
        )
        .where((item) => item.count > 0)
        .toList();
  }

  static void recalculateAllTotals(EventRecord event) {
    final groups = groupedBookingsForEvent(event);

    for (final group in groups) {
      final grand = grandTotal(group);
      final paid = paymentsTotal(group);
      final remaining = grand - paid;

      final total = MoneyUtils.formatMoney(grand);
      final totalPaid = MoneyUtils.formatMoney(paid);

      final nextStatus = paid <= 0
          ? 'Unpaid'
          : remaining <= 0
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
