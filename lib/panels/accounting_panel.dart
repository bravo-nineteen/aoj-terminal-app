import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/ui_components.dart';

class AccountingPanel extends StatefulWidget {
  final Color accent;
  final EventRecord? event;
  final Future<void> Function() onExportFullCsv;
  final Future<void> Function() onAddExpense;
  final Future<void> Function(String expenseId) onDeleteExpense;
  final Future<void> Function() onExportSummary;
  final Future<void> Function(String body) onAddAccountingNote;
  final Future<void> Function(String expenseId, String body) onAddExpenseNote;

  const AccountingPanel({
    super.key,
    required this.accent,
    required this.event,
    required this.onExportFullCsv,
    required this.onAddExpense,
    required this.onDeleteExpense,
    required this.onExportSummary,
    required this.onAddAccountingNote,
    required this.onAddExpenseNote,
  });

  @override
  State<AccountingPanel> createState() => _AccountingPanelState();
}

class _AccountingPanelState extends State<AccountingPanel> {
  bool _notesExpanded = false;

  Future<void> _promptAddAccountingNote() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Accounting Note'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter note…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await widget.onAddAccountingNote(ctrl.text.trim());
    }
  }

  Future<void> _showExpenseNotes(ExpenseRecord expense) async {
    final accent = widget.accent;
    final ctrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Notes — ${expense.item.isEmpty ? 'Expense' : expense.item}',
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (expense.notes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No notes yet.'),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: expense.notes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = expense.notes[i];
                        return ListTile(
                          dense: true,
                          title: Text(n.body),
                          subtitle: Text(
                            '${n.author.isEmpty ? 'Unknown' : n.author}  •  ${_formatDate(n.createdAt)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: 'Add a note…',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final body = ctrl.text.trim();
                        if (body.isEmpty) return;
                        ctrl.clear();
                        Navigator.pop(ctx);
                        await widget.onAddExpenseNote(expense.id, body);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text('NO ACTIVE EVENT'),
              ),
            ),
          ],
        ),
      );
    }

    final groups = BookingUtils.groupedBookingsForEvent(widget.event!);

    final incomeLines = <_LedgerLine>[];
    final deductionLines = <_LedgerLine>[];

    int checkedInCount = 0;
    final int bookingCount = groups.length;
    final int bookedPersons = BookingUtils.eventBookedPersons(widget.event!);

    final double ticketValueByPeople =
      BookingUtils.eventTicketCostTotal(widget.event!);
    double ticketCostTotal = 0;
    double donationTicketsTotal = 0;
    double lunchPassThroughTotal = 0;
    double salesTotal = 0;
    double grandTotal = 0;
    double chargeableTotal = 0;
    double paymentsRecorded = 0;
    double cardFees = 0;
    double manualExpensesTotal = 0;

    for (final group in groups) {
      if (group.primary.checkInStatus.trim() == 'Checked In') {
        checkedInCount++;
      }

      final groupTicketCost =
          BookingUtils.groupTicketRevenueExcludingDonations(group);
      final groupDonationTickets = BookingUtils.groupDonationTotal(group);
      final groupLunchPassThrough =
          BookingUtils.lunchTotal(group, widget.event!);
      final groupSales = BookingUtils.salesTotal(group);

      ticketCostTotal += groupTicketCost;
      donationTicketsTotal += groupDonationTickets;
      lunchPassThroughTotal += groupLunchPassThrough;
      salesTotal += groupSales;
      grandTotal += groupTicketCost + groupSales + groupDonationTickets;
      chargeableTotal += BookingUtils.grandTotal(group, widget.event);
      paymentsRecorded += BookingUtils.paymentsTotal(group);

      for (final payment in group.primary.payments) {
        final amount = _toDouble(payment.amount);
        if (amount <= 0) continue;

        incomeLines.add(
          _LedgerLine(
            id: payment.id,
            title: group.displayName,
            subtitle:
                'PAYMENT • ${payment.method}${payment.note.isEmpty ? '' : ' • ${payment.note}'}',
            amount: amount,
            isDeletable: false,
            isRefund: payment.method.trim().toLowerCase() == 'refund',
          ),
        );

        if (_isCardMethod(payment.method)) {
          final fee = amount * 0.04;
          cardFees += fee;
          deductionLines.add(
            _LedgerLine(
              id: 'card_fee_${payment.id}',
              title: group.displayName,
              subtitle: 'CARD FEE 4% • ${payment.method}',
              amount: fee,
              isDeletable: false,
            ),
          );
        }
      }

      for (final sale in group.primary.sales) {
        final amount = _toDouble(sale.price);
        if (amount <= 0) continue;

        incomeLines.add(
          _LedgerLine(
            id: sale.id,
            title: group.displayName,
            subtitle:
                'SALE • ${sale.product.isEmpty ? 'Unnamed item' : sale.product}',
            amount: amount,
            isDeletable: false,
          ),
        );
      }
    }

    for (final expense in widget.event!.expenses) {
      final amount = _toDouble(expense.amount);
      if (amount <= 0) continue;

      manualExpensesTotal += amount;
      deductionLines.add(
        _LedgerLine(
          id: expense.id,
          title: expense.item.isEmpty ? 'Expense' : expense.item,
          subtitle:
              'MANUAL EXPENSE • ${expense.category.isEmpty ? 'General' : expense.category}${expense.note.isEmpty ? '' : ' • ${expense.note}'}',
          amount: amount,
          isDeletable: true,
          expense: expense,
        ),
      );
    }

    final totalDeductions = cardFees + manualExpensesTotal;
    final netAfterAllDeductions = paymentsRecorded - totalDeductions;
    final outstandingBalance = chargeableTotal - paymentsRecorded;
    final accent = widget.accent;
    final accountingNotes = widget.event!.accountingNotes;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _LedgerCard(
                          title: 'Income Ledger',
                          accent: accent,
                          emptyText: 'NO INCOME LINES',
                          lines: incomeLines,
                          onDeleteLine: null,
                          onViewExpenseNotes: null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LedgerCard(
                          title: 'Deductions Ledger',
                          accent: accent,
                          emptyText: 'NO DEDUCTIONS',
                          lines: deductionLines,
                          onDeleteLine: (line) async {
                            if (!line.isDeletable) return;
                            await widget.onDeleteExpense(line.id);
                          },
                          onViewExpenseNotes: (line) async {
                            if (line.expense == null) return;
                            await _showExpenseNotes(line.expense!);
                          },
                          headerAction: ElevatedButton.icon(
                            onPressed: widget.onAddExpense,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('ADD EXPENSE'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── Accounting Notes ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xCC101511),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.30)),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: _notesExpanded,
                      onExpansionChanged: (v) =>
                          setState(() => _notesExpanded = v),
                      leading:
                          Icon(Icons.sticky_note_2_outlined, color: accent),
                      title: Text(
                        'ACCOUNTING NOTES  (${accountingNotes.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      trailing: TextButton.icon(
                        onPressed: _promptAddAccountingNote,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Note',
                            style: TextStyle(fontSize: 12)),
                      ),
                      children: [
                        if (accountingNotes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No notes yet.',
                                style: TextStyle(fontSize: 12)),
                          )
                        else
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxHeight: 150),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              itemCount: accountingNotes.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final n = accountingNotes[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(n.body,
                                      style: const TextStyle(fontSize: 12)),
                                  subtitle: Text(
                                    '${n.author.isEmpty ? 'Unknown' : n.author}  •  ${_formatDate(n.createdAt)}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xCC101511),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OVERALL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 6,
                        children: [
                          _SummaryStat(
                            label: 'Bookings',
                            value: bookingCount.toString(),
                          ),
                          _SummaryStat(
                            label: 'Booked Persons',
                            value: bookedPersons.toString(),
                          ),
                          _SummaryStat(
                            label: 'Checked In',
                            value: checkedInCount.toString(),
                          ),
                          _SummaryStat(
                            label: 'Ticket Value',
                            value:
                                '¥ ${MoneyUtils.formatMoney(ticketValueByPeople)}',
                          ),
                          _SummaryStat(
                            label: 'Ticket Cost Total',
                            value:
                                '¥ ${MoneyUtils.formatMoney(ticketCostTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Donation Tickets',
                            value:
                                '¥ ${MoneyUtils.formatMoney(donationTicketsTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Sales Value',
                            value: '¥ ${MoneyUtils.formatMoney(salesTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Lunch Fees (Pass-through)',
                            value:
                                '¥ ${MoneyUtils.formatMoney(lunchPassThroughTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Gross Event Value',
                            value: '¥ ${MoneyUtils.formatMoney(grandTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Payments Recorded',
                            value:
                                '¥ ${MoneyUtils.formatMoney(paymentsRecorded)}',
                          ),
                          _SummaryStat(
                            label: 'Card Fees',
                            value: '¥ ${MoneyUtils.formatMoney(cardFees)}',
                          ),
                          _SummaryStat(
                            label: 'Manual Expenses',
                            value:
                                '¥ ${MoneyUtils.formatMoney(manualExpensesTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Total Deductions',
                            value:
                                '¥ ${MoneyUtils.formatMoney(totalDeductions)}',
                          ),
                          _SummaryStat(
                            label: 'Net After Deductions',
                            value:
                                '¥ ${MoneyUtils.formatMoney(netAfterAllDeductions)}',
                          ),
                          _SummaryStat(
                            label: 'Outstanding Balance',
                            value:
                                '¥ ${MoneyUtils.formatMoney(outstandingBalance)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: widget.onExportSummary,
                              icon: const Icon(
                                  Icons.summarize_outlined,
                                  size: 16),
                              label: const Text('EVENT SUMMARY'),
                            ),
                            ElevatedButton.icon(
                              onPressed: widget.onExportFullCsv,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('EXPORT FULL EVENT CSV'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isCardMethod(String raw) {
    final value = raw.trim().toLowerCase();
    return value.contains('credit') ||
        value.contains('card') ||
        value.contains('stripe') ||
        value.contains('visa') ||
        value.contains('mastercard') ||
        value.contains('amex') ||
        value.contains('クレジット');
  }

  static double _toDouble(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}

class _LedgerCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<_LedgerLine> lines;
  final String emptyText;
  final Widget? headerAction;
  final Future<void> Function(_LedgerLine line)? onDeleteLine;
  final Future<void> Function(_LedgerLine line)? onViewExpenseNotes;

  const _LedgerCard({
    required this.title,
    required this.accent,
    required this.lines,
    required this.emptyText,
    required this.onDeleteLine,
    required this.onViewExpenseNotes,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xCC101511),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              color: accent.withValues(alpha: 0.12),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.25)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? Center(child: Text(emptyText))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final titleStyle = TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: line.isRefund ? Colors.blueAccent : null,
                      );
                      final subtitleStyle = TextStyle(
                        fontSize: 11,
                        color: line.isRefund
                            ? Colors.blueAccent.withValues(alpha: 0.7)
                            : null,
                      );
                      final amountText = line.isRefund
                          ? '(REFUND) ¥ ${MoneyUtils.formatMoney(line.amount)}'
                          : '¥ ${MoneyUtils.formatMoney(line.amount)}';
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          line.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        subtitle: Text(
                          line.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              amountText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: line.isRefund
                                    ? Colors.blueAccent
                                    : null,
                              ),
                            ),
                            if (line.isDeletable && onDeleteLine != null) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () => onDeleteLine!(line),
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                tooltip: 'Delete expense',
                              ),
                            ],
                            if (line.expense != null &&
                                onViewExpenseNotes != null)
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        onViewExpenseNotes!(line),
                                    icon: const Icon(
                                        Icons.sticky_note_2_outlined,
                                        size: 18),
                                    tooltip: 'Expense notes',
                                  ),
                                  if (line.expense!.notes.isNotEmpty)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9BA59A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerLine {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isDeletable;
  final bool isRefund;
  final ExpenseRecord? expense;

  const _LedgerLine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDeletable,
    this.isRefund = false,
    this.expense,
  });
}
