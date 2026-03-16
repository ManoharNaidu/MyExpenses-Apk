import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_provider.dart';
import '../core/constants/currencies.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../widgets/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedConcept = 0;
  int _touchedCategoryIndex = -1;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  static const _categoryColors = <String, Color>{
    'Housing': Color(0xFF26A69A),
    'Groceries': Color(0xFF66BB6A),
    'Food': Color(0xFF66BB6A),
    'Transport': Color(0xFFFFB74D),
    'Dining Out': Color(0xFFFFD54F),
    'Shopping': Color(0xFF5C6BC0),
    'Entertainment': Color(0xFF42A5F5),
    'Savings': Color(0xFF9E9E9E),
    'Other': Color(0xFF90A4AE),
  };

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
  }

  /// Returns a short currency symbol for chart labels (e.g. "$", "₹", "€").
  String _currencySymbol(BuildContext context) {
    final code =
        context.read<AuthProvider>().state.effectiveCurrency;
    return currencyFromCode(code).symbol;
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
        final monthOptions = _buildMonthOptions(txs);

        if (txs.isEmpty) {
          return const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No data for analytics yet',
            message:
                'Add transactions or upload a bank PDF to unlock balance, category drill-down, and trend analysis dashboards.',
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _conceptSelector(context),
              const SizedBox(height: 10),
              _monthSelector(context, monthOptions),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _buildConceptView(context, txs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _conceptSelector(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surfaceContainerHighest;
    final primaryColor = theme.colorScheme.primary;

    Widget item({required int index, required String label}) {
      final selected = _selectedConcept == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedConcept = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          item(index: 0, label: 'Balance'),
          item(index: 1, label: 'Drill-down'),
          item(index: 2, label: 'Trends'),
        ],
      ),
    );
  }

  Widget _buildConceptView(BuildContext context, List<TransactionModel> txs) {
    final selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    switch (_selectedConcept) {
      case 0:
        return _balanceOverviewView(context, txs, selectedMonth);
      case 1:
        return _categoryDrillDownView(context, txs, selectedMonth);
      default:
        return _trendAnalysisView(context, txs, selectedMonth);
    }
  }

  List<DateTime> _buildMonthOptions(List<TransactionModel> txs) {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final months = <DateTime>{currentMonth};
    for (final tx in txs) {
      months.add(DateTime(tx.date.year, tx.date.month, 1));
    }
    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    if (!sorted.any(
      (m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month,
    )) {
      _selectedMonth = currentMonth;
    }
    return sorted;
  }

  Widget _monthSelector(BuildContext context, List<DateTime> monthOptions) {
    return DropdownButtonFormField<DateTime>(
      value: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      items: monthOptions
          .map(
            (month) => DropdownMenuItem<DateTime>(
              value: month,
              child: Text(DateFormat('MMMM yyyy').format(month)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMonth = DateTime(value.year, value.month, 1);
          _touchedCategoryIndex = -1;
        });
      },
      decoration: const InputDecoration(
        labelText: 'Month',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _balanceOverviewView(
    BuildContext context,
    List<TransactionModel> txs,
    DateTime selectedMonth,
  ) {
    final sym = _currencySymbol(context);

    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final previousMonthStart =
        DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final previousMonthEnd = monthStart.subtract(const Duration(days: 1));

    double currentIncome = 0;
    double currentExpenses = 0;
    double previousIncome = 0;
    double previousExpenses = 0;

    for (final tx in txs) {
      if (!tx.date.isBefore(monthStart) && !tx.date.isAfter(monthEnd)) {
        if (tx.type == TxType.income) {
          currentIncome += tx.amount;
        } else {
          currentExpenses += tx.amount;
        }
      } else if (!tx.date.isBefore(previousMonthStart) &&
          !tx.date.isAfter(previousMonthEnd)) {
        if (tx.type == TxType.income) {
          previousIncome += tx.amount;
        } else {
          previousExpenses += tx.amount;
        }
      }
    }

    final gaugeMax =
        (currentIncome > currentExpenses ? currentIncome : currentExpenses) *
                1.15 +
            1;

    final savingsTarget =
        currentIncome <= 0 ? 1000.0 : currentIncome * 0.25;
    final netSavings = (currentIncome - currentExpenses)
        .clamp(0, double.infinity)
        .toDouble();
    final savingsPct =
        (netSavings / savingsTarget).clamp(0.0, 1.0).toDouble();

    final monthBars = _buildSpendingStacksForRecentMonths(
      txs,
      months: 4,
      endMonth: selectedMonth,
    );

    return SingleChildScrollView(
      key: const ValueKey('balance_view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Balance • ${DateFormat('MMMM yyyy').format(selectedMonth)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _gaugeCard(
                  title: 'Income',
                  value: currentIncome,
                  max: gaugeMax,
                  symbol: sym,
                  color: const Color(0xFF2E7D32),
                  isPositiveTrend: currentIncome >= previousIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _gaugeCard(
                  title: 'Expenses',
                  value: currentExpenses,
                  max: gaugeMax,
                  symbol: sym,
                  color: const Color(0xFFF9A825),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFEE58), Color(0xFFFF7043)],
                  ),
                  isPositiveTrend: currentExpenses <= previousExpenses,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _monthlySpendingStackCard(context, monthBars),
          const SizedBox(height: 14),
          _savingsGoalCard(
            current: netSavings,
            target: savingsTarget,
            progress: savingsPct,
            symbol: sym,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _gaugeCard({
    required String title,
    required double value,
    required double max,
    required String symbol,
    required Color color,
    LinearGradient? gradient,
    required bool isPositiveTrend,
  }) {
    final progress = (value / max).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 86,
                    width: 86,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  if (gradient != null)
                    SizedBox(
                      height: 86,
                      width: 86,
                      child: ShaderMask(
                        shaderCallback: (rect) =>
                            gradient.createShader(rect),
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    '$symbol${value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  isPositiveTrend
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: isPositiveTrend ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  isPositiveTrend ? 'up' : 'down',
                  style: TextStyle(
                    color: isPositiveTrend ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_MonthlyCategoryStack> _buildSpendingStacksForRecentMonths(
    List<TransactionModel> txs, {
    int months = 4,
    DateTime? endMonth,
  }) {
    final anchor = endMonth ?? DateTime.now();
    final monthStarts = List.generate(
      months,
      (i) => DateTime(anchor.year, anchor.month - (months - 1 - i), 1),
    );

    final categoryOrder = [
      'Housing',
      'Groceries',
      'Transport',
      'Dining Out',
      'Savings',
      'Other',
    ];

    final stacks = <_MonthlyCategoryStack>[];
    for (final monthStart in monthStarts) {
      final monthEnd =
          DateTime(monthStart.year, monthStart.month + 1, 0);
      final values = <String, double>{
        for (final c in categoryOrder) c: 0,
      };

      for (final tx in txs) {
        if (tx.type != TxType.expense) continue;
        if (tx.date.isBefore(monthStart) || tx.date.isAfter(monthEnd)) {
          continue;
        }
        final normalized = _normalizeSpendingCategory(tx.category);
        values[normalized] = (values[normalized] ?? 0) + tx.amount;
      }

      stacks.add(
        _MonthlyCategoryStack(
          label: DateFormat('MMM').format(monthStart),
          categoryValues: values,
        ),
      );
    }
    return stacks;
  }

  String _normalizeSpendingCategory(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('rent') || value.contains('house')) return 'Housing';
    if (value.contains('grocer') || value.contains('food')) return 'Groceries';
    if (value.contains('transport') ||
        value.contains('fuel') ||
        value.contains('petrol') ||
        value.contains('taxi')) {
      return 'Transport';
    }
    if (value.contains('dining') ||
        value.contains('restaurant') ||
        value.contains('cafe')) {
      return 'Dining Out';
    }
    if (value.contains('saving')) return 'Savings';
    return 'Other';
  }

  Widget _monthlySpendingStackCard(
    BuildContext context,
    List<_MonthlyCategoryStack> bars,
  ) {
    final maxTotal = bars
        .map((e) =>
            e.categoryValues.values.fold<double>(0, (a, b) => a + b))
        .fold<double>(0, (a, b) => a > b ? a : b);

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < bars.length; i++) {
      double running = 0;
      final stacks = <BarChartRodStackItem>[];
      bars[i].categoryValues.forEach((key, value) {
        if (value <= 0) return;
        stacks.add(
          BarChartRodStackItem(
            running,
            running + value,
            _categoryColors[key] ?? Colors.grey,
          ),
        );
        running += value;
      });

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: running,
              rodStackItems: stacks,
              width: 24,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Spending',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  maxY: maxTotal <= 0 ? 100 : maxTotal * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= bars.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              bars[idx].label,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: groups,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                for (final key in [
                  'Housing',
                  'Groceries',
                  'Transport',
                  'Dining Out',
                  'Savings',
                ])
                  _legendItem(key, _categoryColors[key] ?? Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _savingsGoalCard({
    required double current,
    required double target,
    required double progress,
    required String symbol,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Savings Goal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '$symbol${current.toStringAsFixed(0)} to $symbol${target.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text("You're ${(progress * 100).toStringAsFixed(0)}% there!"),
          ],
        ),
      ),
    );
  }

  Widget _categoryDrillDownView(
    BuildContext context,
    List<TransactionModel> txs,
    DateTime selectedMonth,
  ) {
    final sym = _currencySymbol(context);

    final expenses = txs
        .where(
          (e) =>
              e.type == TxType.expense &&
              e.date.year == selectedMonth.year &&
              e.date.month == selectedMonth.month,
        )
        .toList();
    final totals = <String, double>{};

    for (final tx in expenses) {
      final name = _normalizeDrillDownCategory(tx.category);
      totals[name] = (totals[name] ?? 0) + tx.amount;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final totalAmount = top.fold<double>(0, (sum, e) => sum + e.value);

    if (_touchedCategoryIndex >= top.length) {
      _touchedCategoryIndex = top.isEmpty ? -1 : 0;
    }
    if (_touchedCategoryIndex == -1 && top.isNotEmpty) {
      _touchedCategoryIndex = 0;
    }

    final selectedCategory =
        _touchedCategoryIndex >= 0 && _touchedCategoryIndex < top.length
            ? top[_touchedCategoryIndex].key
            : null;

    final selectedTxs = selectedCategory == null
        ? <TransactionModel>[]
        : expenses
              .where(
                (t) =>
                    _normalizeDrillDownCategory(t.category) ==
                    selectedCategory,
              )
              .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final highest = selectedTxs.isEmpty
        ? null
        : selectedTxs.reduce((a, b) => a.amount >= b.amount ? a : b);
    final avg = selectedTxs.isEmpty
        ? 0.0
        : selectedTxs.fold<double>(0, (sum, e) => sum + e.amount) /
              selectedTxs.length;

    return SingleChildScrollView(
      key: const ValueKey('drill_view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Spending • ${DateFormat('MMMM yyyy').format(selectedMonth)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Categories',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 45,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final index = response
                                ?.touchedSection?.touchedSectionIndex;
                            if (index != null) {
                              setState(
                                  () => _touchedCategoryIndex = index);
                            }
                          },
                        ),
                        sections: [
                          for (int i = 0; i < top.length; i++)
                            PieChartSectionData(
                              value: top[i].value,
                              title: totalAmount <= 0
                                  ? top[i].key
                                  : '${top[i].key}\n${(top[i].value / totalAmount * 100).toStringAsFixed(0)}%',
                              radius: _touchedCategoryIndex == i ? 78 : 68,
                              color: _categoryColors[top[i].key] ??
                                  Colors.primaries[
                                      i % Colors.primaries.length],
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCategory == null
                        ? 'Category Details'
                        : '$selectedCategory Expenses',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 36,
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Location')),
                      ],
                      rows: selectedTxs.take(7).map((tx) {
                        return DataRow(
                          cells: [
                            DataCell(
                                Text(DateFormat('MMM d').format(tx.date))),
                            DataCell(
                              Text(
                                tx.notes ?? tx.description ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(Text(
                                '$sym${tx.amount.toStringAsFixed(2)}')),
                            const DataCell(Text('-')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    highest == null
                        ? 'No transactions available for this category yet.'
                        : 'Highest $selectedCategory spending: ${DateFormat('MMM d').format(highest.date)} - '
                              '$sym${highest.amount.toStringAsFixed(0)}. '
                              'Average transaction: $sym${avg.toStringAsFixed(0)}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _normalizeDrillDownCategory(String category) {
    final v = category.toLowerCase();
    if (v.contains('house') || v.contains('rent')) return 'Housing';
    if (v.contains('grocer') || v.contains('food') || v.contains('dining')) {
      return 'Food';
    }
    if (v.contains('shop')) return 'Shopping';
    if (v.contains('entertain')) return 'Entertainment';
    if (v.contains('transport') ||
        v.contains('fuel') ||
        v.contains('petrol') ||
        v.contains('taxi')) {
      return 'Transport';
    }
    return 'Other';
  }

  Widget _trendAnalysisView(
    BuildContext context,
    List<TransactionModel> txs,
    DateTime selectedMonth,
  ) {
    final sym = _currencySymbol(context);

    final months = List.generate(
      6,
      (i) =>
          DateTime(selectedMonth.year, selectedMonth.month - (5 - i), 1),
    );
    final incomeByMonth = List<double>.filled(months.length, 0);
    final expenseByMonth = List<double>.filled(months.length, 0);

    final monthIndexMap = <String, int>{
      for (int i = 0; i < months.length; i++)
        '${months[i].year}-${months[i].month.toString().padLeft(2, '0')}': i,
    };

    for (final tx in txs) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      final idx = monthIndexMap[key];
      if (idx == null) continue;
      if (tx.type == TxType.income) {
        incomeByMonth[idx] += tx.amount;
      } else {
        expenseByMonth[idx] += tx.amount;
      }
    }

    final netByMonth = List<double>.generate(
      months.length,
      (i) => (incomeByMonth[i] - expenseByMonth[i])
          .clamp(0.0, double.infinity)
          .toDouble(),
    );

    final incomeSpots = [
      for (int i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), incomeByMonth[i]),
    ];
    final expenseSpots = [
      for (int i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), expenseByMonth[i]),
    ];
    final netSpots = [
      for (int i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), netByMonth[i]),
    ];

    final maxIncome =
        incomeByMonth.fold<double>(0, (a, b) => a > b ? a : b);
    final maxExpense =
        expenseByMonth.fold<double>(0, (a, b) => a > b ? a : b);
    final maxY =
        (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2 + 50;

    final avgIncome =
        incomeByMonth.fold<double>(0, (a, b) => a + b) / months.length;
    final avgExpense =
        expenseByMonth.fold<double>(0, (a, b) => a + b) / months.length;

    final selectedMonthExpenses = txs.where(
      (e) =>
          e.type == TxType.expense &&
          e.date.year == selectedMonth.year &&
          e.date.month == selectedMonth.month,
    );

    final expenseByCategory = <String, double>{};
    for (final tx in selectedMonthExpenses) {
      final c = _normalizeDrillDownCategory(tx.category);
      expenseByCategory[c] = (expenseByCategory[c] ?? 0) + tx.amount;
    }
    final topCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpense =
        topCategories.fold<double>(0, (sum, e) => sum + e.value);
    final topExpense =
        topCategories.isEmpty ? 'N/A' : topCategories.first.key;

    return SingleChildScrollView(
      key: const ValueKey('trend_view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Trends • Last 6 months to ${DateFormat('MMM yyyy').format(selectedMonth)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 270,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (months.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY <= 0 ? 200 : maxY,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: true),
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
                          reservedSize: 38,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= months.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('MMM').format(months[idx]),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: netSpots,
                        color: Colors.transparent,
                        barWidth: 0,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Avg. Monthly Income: $sym${avgIncome.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  Text(
                      'Avg. Monthly Expenses: $sym${avgExpense.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  Text('Top Expense: $topExpense'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top 5 Categories',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final e in topCategories.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: totalExpense <= 0
                                  ? 0
                                  : e.value / totalExpense,
                              minHeight: 9,
                              borderRadius: BorderRadius.circular(8),
                              color: _categoryColors[e.key] ??
                                  Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            totalExpense <= 0
                                ? '0%'
                                : '${(e.value / totalExpense * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

class _MonthlyCategoryStack {
  final String label;
  final Map<String, double> categoryValues;

  const _MonthlyCategoryStack({
    required this.label,
    required this.categoryValues,
  });
}
