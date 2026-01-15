import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../utils/date_utils.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txs = TransactionRepository.all();

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
    final weeklyIncome = weeklyKeys.map((k) => weekly[k]!["Income"]!).toList();
    final weeklyExpense = weeklyKeys.map((k) => weekly[k]!["Expense"]!).toList();

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
    final monthlyIncome = monthlyKeys.map((k) => monthly[k]!["Income"]!).toList();
    final monthlyExpense = monthlyKeys.map((k) => monthly[k]!["Expense"]!).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Weekly", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _barChart(
              labels: weeklyKeys.map((d) => DateUtilsX.weekLabel(d)).toList(),
              a: weeklyIncome,
              b: weeklyExpense,
              aName: "Income",
              bName: "Expense",
            ),
            const SizedBox(height: 22),
            Text("Monthly", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _barChart(
              labels: monthlyKeys,
              a: monthlyIncome,
              b: monthlyExpense,
              aName: "Income",
              bName: "Expense",
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChart({
    required List<String> labels,
    required List<double> a,
    required List<double> b,
    required String aName,
    required String bName,
  }) {
    final n = labels.length;
    if (n == 0) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No data yet.")));
    }

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < n; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: a[i], width: 8, borderRadius: BorderRadius.circular(6)),
            BarChartRodData(toY: b[i], width: 8, borderRadius: BorderRadius.circular(6)),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              barGroups: groups,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: n > 8 ? 2 : 1,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(labels[idx], style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: true),
              groupsSpace: 14,
            ),
          ),
        ),
      ),
    );
  }
}
