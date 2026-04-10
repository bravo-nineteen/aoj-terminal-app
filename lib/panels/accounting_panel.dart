import 'package:flutter/material.dart';

import '../models/aoj_models.dart';
import '../utils/booking_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/ui_components.dart';

class AccountingPanel extends StatelessWidget {
  final Color accent;
  final EventRecord? event;
  final Future<void> Function() onExportFullCsv;
  final Future<void> Function() onAddExpense;
  final Future<void> Function(String expenseId) onDeleteExpense;

  const AccountingPanel({
    super.key,
    required this.accent,
    required this.event,
    required this.onExportFullCsv,
    required this.onAddExpense,
    required this.onDeleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text('NO ACTIVE EVENT'),
              ),
            ),
          ],
        ),
      );
    }

    final groups = BookingUtils.groupedBookingsForEvent(event!);

    final incomeLines = <_LedgerLine>[];
    final deductionLines = <_LedgerLine>[];

    int checkedInCount = 0;
    final int bookingCount = groups.length;

    double ticketsTotal = 0;
    double salesTotal = 0;
    double grandTotal = 0;
    double paymentsRecorded = 0;
    double cardFees = 0;
    double manualExpensesTotal = 0;

    for (final group in groups) {
      if (group.primary.checkInStatus.trim() == 'Checked In') {
        checkedInCount++;
      }

      ticketsTotal += BookingUtils.ticketsTotal(group);
      salesTotal += BookingUtils.salesTotal(group);
      grandTotal += BookingUtils.grandTotal(group);
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

    for (final expense in event!.expenses) {
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
        ),
      );
    }

    final totalDeductions = cardFees + manualExpensesTotal;
    final netAfterAllDeductions = paymentsRecorded - totalDeductions;
    final outstandingBalance = grandTotal - paymentsRecorded;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeroPanel(
            title: 'ACCOUNT MANAGEMENT',
            subtitle: 'Income, deductions and event totals',
            accent: accent,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 14),
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
                            await onDeleteExpense(line.id);
                          },
                          headerAction: ElevatedButton.icon(
                            onPressed: onAddExpense,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('ADD EXPENSE'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xCC101511),
                    border: Border.all(color: accent.withOpacity(0.35)),
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
                            label: 'Checked In',
                            value: checkedInCount.toString(),
                          ),
                          _SummaryStat(
                            label: 'Ticket Value',
                            value: '¥ ${MoneyUtils.formatMoney(ticketsTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Sales Value',
                            value: '¥ ${MoneyUtils.formatMoney(salesTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Gross Event Value',
                            value: '¥ ${MoneyUtils.formatMoney(grandTotal)}',
                          ),
                          _SummaryStat(
                            label: 'Payments Recorded',
                            value: '¥ ${MoneyUtils.formatMoney(paymentsRecorded)}',
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
                        child: ElevatedButton.icon(
                          onPressed: onExportFullCsv,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('EXPORT FULL EVENT CSV'),
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

  const _LedgerCard({
    required this.title,
    required this.accent,
    required this.lines,
    required this.emptyText,
    required this.onDeleteLine,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xCC101511),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              color: accent.withOpacity(0.12),
              border: Border(
                bottom: BorderSide(color: accent.withOpacity(0.25)),
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
                      color: Colors.white.withOpacity(0.06),
                    ),
                    itemBuilder: (context, index) {
                      final line = lines[index];
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          line.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¥ ${MoneyUtils.formatMoney(line.amount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (line.isDeletable && onDeleteLine != null) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () => onDeleteLine!(line),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                tooltip: 'Delete expense',
                              ),
                            ],
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

  const _LedgerLine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDeletable,
  });
}
