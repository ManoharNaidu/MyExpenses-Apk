import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/date_utils.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/summary_card.dart';
import '../data/transaction_repository.dart';
import '../utils/csv_export.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final txs = snapshot.data ?? [];

        final now = DateTime.now();
        final todayKey = DateTime(now.year, now.month, now.day);
        final weekStart = DateUtilsX.weekStartMonday(now);
        final weekEnd = DateUtilsX.weekEndSunday(now);
        final monthKey = DateTime(now.year, now.month, 1);

        double sumWhere(bool Function(TransactionModel t) pred) => txs
            .where(pred)
            .fold(
              0.0,
              (a, b) => a + (b.type == TxType.expense ? -b.amount : b.amount),
            );

        double incomeWhere(bool Function(TransactionModel t) pred) => txs
            .where((t) => pred(t) && t.type == TxType.income)
            .fold(0.0, (a, b) => a + b.amount);

        double expenseWhere(bool Function(TransactionModel t) pred) => txs
            .where((t) => pred(t) && t.type == TxType.expense)
            .fold(0.0, (a, b) => a + b.amount);

        bool isToday(TransactionModel t) =>
            DateTime(t.date.year, t.date.month, t.date.day) == todayKey;

        bool isThisWeek(TransactionModel t) =>
            !t.date.isBefore(weekStart) && !t.date.isAfter(weekEnd);

        bool isThisMonth(TransactionModel t) =>
            t.date.year == monthKey.year && t.date.month == monthKey.month;

        final todayNet = sumWhere(isToday);
        final weekNet = sumWhere(isThisWeek);
        final monthNet = sumWhere(isThisMonth);

        final weekIncome = incomeWhere(isThisWeek);
        final weekExpense = expenseWhere(isThisWeek);

        return Scaffold(
          appBar: AppBar(
            title: const Text("My Expenses"),
            actions: [
              IconButton(
                tooltip: "Export CSV",
                onPressed: () async => CsvExport.exportTransactions(txs),
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => AddTransactionModal(onSaved: () {}),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                SummaryCard(
                  title: "Today (Net)",
                  value: todayNet.toStringAsFixed(2),
                  icon: Icons.today_rounded,
                ),
                SummaryCard(
                  title: "This Week (Net)",
                  value: weekNet.toStringAsFixed(2),
                  icon: Icons.date_range_rounded,
                ),
                SummaryCard(
                  title: "This Month (Net)",
                  value: monthNet.toStringAsFixed(2),
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: "Week Income",
                        value: weekIncome.toStringAsFixed(2),
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: "Week Expense",
                        value: weekExpense.toStringAsFixed(2),
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text("Recent", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...txs
                    .take(10)
                    .map(
                      (t) => Card(
                        child: ListTile(
                          title: Text(
                            t.category,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            "${DateUtilsX.yyyyMmDd(t.date)} • ${t.type == TxType.income ? "Income" : "Expense"}",
                          ),
                          trailing: Text(
                            (t.type == TxType.income ? "+" : "-") +
                                t.amount.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: t.type == TxType.income
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
