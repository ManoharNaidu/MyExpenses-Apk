import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0; // 0 = Weekly, 1 = Monthly

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      initialData: TransactionRepository.currentTransactions,
      builder: (context, snapshot) {
        if (snapshot.data == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final txs = snapshot.data ?? [];

        // WEEKLY: group by weekStart (Mon)
        final weekly = <DateTime, Map<String, double>>{};
        for (final t in txs) {
          final w = DateUtilsX.weekStartMonday(t.date);
          weekly.putIfAbsent(w, () => {"Income": 0.0, "Expense": 0.0});
          if (t.type == TxType.income) {
            weekly[w]!["Income"] = weekly[w]!["Income"]! + t.amount;
          } else {
            weekly[w]!["Expense"] = weekly[w]!["Expense"]! + t.amount;
          }
        }

        final weeklyKeys = weekly.keys.toList()..sort();
        final weeklyIncome = weeklyKeys
            .map((k) => weekly[k]!["Income"]!)
            .toList();
        final weeklyExpense = weeklyKeys
            .map((k) => weekly[k]!["Expense"]!)
            .toList();

        // MONTHLY: group by yyyy-mm
        final monthly = <String, Map<String, double>>{};
        for (final t in txs) {
          final m = DateUtilsX.yyyyMm(t.date);
          monthly.putIfAbsent(m, () => {"Income": 0.0, "Expense": 0.0});
          if (t.type == TxType.income) {
            monthly[m]!["Income"] = monthly[m]!["Income"]! + t.amount;
          } else {
            monthly[m]!["Expense"] = monthly[m]!["Expense"]! + t.amount;
          }
        }

        final monthlyKeys = monthly.keys.toList()..sort();
        final monthlyIncome = monthlyKeys
            .map((k) => monthly[k]!["Income"]!)
            .toList();
        final monthlyExpense = monthlyKeys
            .map((k) => monthly[k]!["Expense"]!)
            .toList();

        if (txs.isEmpty) {
          return const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No data for analytics yet',
            message:
                'Add transactions or upload a bank PDF to see weekly and monthly income vs expense trends.',
          );
        }

        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final surfaceColor = theme.colorScheme.surfaceContainerHighest;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Weekly",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 0
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Monthly",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 1
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedTab == 0
                    ? _barChart(
                        context: context,
                        labels: weeklyKeys
                            .map((d) => DateUtilsX.weekLabel(d))
                            .toList(),
                        a: weeklyIncome,
                        b: weeklyExpense,
                        aName: "Income",
                        bName: "Expense",
                      )
                    : _barChart(
                        context: context,
                        labels: monthlyKeys,
                        a: monthlyIncome,
                        b: monthlyExpense,
                        aName: "Income",
                        bName: "Expense",
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _barChart({
    required BuildContext context,
    required List<String> labels,
    required List<double> a,
    required List<double> b,
    required String aName,
    required String bName,
  }) {
    final n = labels.length;
    if (n == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              "No data for this period.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final incomeColor = Colors.green;
    final expenseColor = Colors.red.shade700;

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < n; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: a[i],
              width: 6,
              color: incomeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: b[i],
              width: 6,
              color: expenseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Legend
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem("Income", Colors.green),
                  const SizedBox(width: 20),
                  _legendItem("Expense", Colors.red),
                ],
              ),
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: n > 6 ? 2 : 1,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[idx],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  groupsSpace: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
