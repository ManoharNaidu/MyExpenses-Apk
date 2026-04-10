import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/transaction_model.dart';

class NetWorthResult {
  final double totalNetWorth;
  final double delta;
  final List<double> sparkPoints;
  final DateTime? earliest;

  const NetWorthResult({
    required this.totalNetWorth,
    required this.delta,
    required this.sparkPoints,
    required this.earliest,
  });
}

class NetWorthService {
  static Future<NetWorthResult> calculate(
    List<TransactionModel> txs,
    DateTime selectedMonth,
  ) async {
    final sorted = [...txs]..sort((a, b) => a.date.compareTo(b.date));
    double running = 0;
    final monthly = <String, double>{};

    for (final tx in sorted) {
      running += tx.type == TxType.income ? tx.amount : -tx.amount;
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      monthly[key] = running;
    }

    final total = running;
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final prevKey = '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';
    final prevValue = monthly[prevKey] ?? 0;

    final spark = List<double>.generate(6, (i) {
      final m = DateTime(selectedMonth.year, selectedMonth.month - (5 - i), 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      return monthly[key] ?? 0;
    });

    return NetWorthResult(
      totalNetWorth: total,
      delta: total - prevValue,
      sparkPoints: spark,
      earliest: sorted.isEmpty ? null : sorted.first.date,
    );
  }
}

class NetWorthCard extends StatelessWidget {
  final NetWorthResult result;
  final String currencySymbol;
  final bool isDark;

  const NetWorthCard({
    super.key,
    required this.result,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final positive = result.totalNetWorth >= 0;
    final valueColor = positive
        ? (isDark ? AppTheme.darkIncome : AppTheme.incomeGreen)
        : (isDark ? AppTheme.darkExpense : AppTheme.expenseRed);

    final sparkColor = result.sparkPoints.isEmpty
        ? valueColor
        : (result.sparkPoints.last >= 0
            ? (isDark ? AppTheme.darkIncome : AppTheme.incomeGreen)
            : (isDark ? AppTheme.darkExpense : AppTheme.expenseRed));

    final lineSpots = result.sparkPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final baseline = result.sparkPoints.isEmpty
        ? 0.0
        : result.sparkPoints.reduce(min);
    final topLine = result.sparkPoints.isEmpty
        ? 1.0
        : result.sparkPoints.reduce(max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Net Worth', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '$currencySymbol${result.totalNetWorth.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.delta >= 0 ? '↑' : '↓'} ${result.delta >= 0 ? '+' : ''}$currencySymbol${result.delta.toStringAsFixed(2)} vs last month',
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: LineChart(
                LineChartData(
                  minY: baseline,
                  maxY: topLine == baseline ? baseline + 1 : topLine,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineSpots,
                      isCurved: true,
                      color: sparkColor,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.earliest == null
                  ? 'No historical transactions yet'
                  : 'All transactions since ${_shortDate(result.earliest!)}',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSec : AppTheme.textSoft,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime d) {
    final month = _monthNames[d.month - 1];
    return '${d.day.toString().padLeft(2, '0')} $month ${d.year}';
  }

  static const _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
