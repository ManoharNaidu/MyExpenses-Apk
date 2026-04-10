import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/health_score.dart';

class HealthScoreService {
  /// Entry point to calculate health score for a specific month.
  /// Uses [compute] to offload heavy calculations to a background isolate.
  static Future<HealthScore> calculate({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required DateTime targetMonth,
  }) async {
    return compute(_calculateTask, {
      'transactions': transactions,
      'budgets': budgets,
      'targetMonth': targetMonth,
    });
  }

  static HealthScore _calculateTask(Map<String, dynamic> data) {
    final transactions = data['transactions'] as List<TransactionModel>;
    final budgets = data['budgets'] as List<BudgetModel>;
    final targetMonth = data['targetMonth'] as DateTime;

    final monthKey = DateFormat('yyyy-MM').format(targetMonth);
    final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    final monthEnd = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    // Filter current month data
    final currentTxs = transactions
        .where(
          (tx) =>
              !tx.date.isBefore(monthStart) &&
              !tx.date.isAfter(monthEnd) &&
              tx.description != null,
        )
        .toList();

    double income = 0;
    double expense = 0;
    final Map<String, double> catSpending = {};
    final Set<int> activeDays = {};

    for (var tx in currentTxs) {
      if (tx.type == TxType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        catSpending[tx.category] = (catSpending[tx.category] ?? 0) + tx.amount;
      }
      activeDays.add(tx.date.day);
    }

    // 1. Savings Rate (30 pts)
    double savingsRate = income > 0 ? (income - expense) / income : 0;
    int savingsPoints = (savingsRate.clamp(0, 0.3) / 0.3 * 30).round();

    // 2. Budget Adherence (25 pts)
    // Only count budgets active for this month or default budgets
    final activeBudgets = budgets.where((b) => b.category != 'Total').toList();
    double budgetAdherence = 1.0;
    int budgetPoints = 25;
    if (activeBudgets.isNotEmpty) {
      int overCount = 0;
      for (var b in activeBudgets) {
        if ((catSpending[b.category] ?? 0) > b.monthlyLimit) overCount++;
      }
      budgetAdherence =
          (activeBudgets.length - overCount) / activeBudgets.length;
      budgetPoints = (budgetAdherence * 25).round();
    }

    // 3. Spend Trends (20 pts)
    // Compare current expense vs average of last 3 months
    double avgPastExpense = _getAverageMetric(
      transactions,
      targetMonth,
      3,
      TxType.expense,
    );
    double spendVsAverage = avgPastExpense > 0 ? expense / avgPastExpense : 1.0;
    int trendPoints = 0;
    if (spendVsAverage <= 0.9)
      trendPoints = 20;
    else if (spendVsAverage <= 1.0)
      trendPoints = 15;
    else if (spendVsAverage <= 1.2)
      trendPoints = 5;

    // 4. Consistency (15 pts)
    // 10+ days of tracking = full points
    int consistencyPoints = (activeDays.length / 10 * 15).clamp(0, 15).round();

    // 5. Income Growth (10 pts)
    double avgPastIncome = _getAverageMetric(
      transactions,
      targetMonth,
      3,
      TxType.income,
    );
    int growthPoints = (avgPastIncome > 0 && income >= avgPastIncome) ? 10 : 0;

    int total =
        savingsPoints +
        budgetPoints +
        trendPoints +
        consistencyPoints +
        growthPoints;

    return HealthScore(
      totalScore: total,
      monthKey: monthKey,
      calculatedAt: DateTime.now(),
      savingsPoints: savingsPoints,
      budgetPoints: budgetPoints,
      trendPoints: trendPoints,
      consistencyPoints: consistencyPoints,
      growthPoints: growthPoints,
      savingsRate: savingsRate,
      budgetAdherence: budgetAdherence,
      spendVsAverage: spendVsAverage,
      activeDays: activeDays.length,
    );
  }

  static double _getAverageMetric(
    List<TransactionModel> txs,
    DateTime targetMonth,
    int monthsBack,
    TxType type,
  ) {
    double total = 0;
    int count = 0;
    for (int i = 1; i <= monthsBack; i++) {
      final m = DateTime(targetMonth.year, targetMonth.month - i, 1);
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);

      double sum = 0;
      bool found = false;
      for (var tx in txs) {
        if (!tx.date.isBefore(start) &&
            !tx.date.isAfter(end) &&
            tx.type == type &&
            tx.description != null) {
          sum += tx.amount;
          found = true;
        }
      }
      if (found) {
        total += sum;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }
}
