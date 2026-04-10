import 'package:flutter/material.dart';
import 'transaction_model.dart';

enum HealthBand {
  poor('Needs Attention', Colors.red),
  fair('Fair', Colors.orange),
  good('Good', Colors.blue),
  excellent('Excellent', Colors.green);

  final String label;
  final Color color;
  const HealthBand(this.label, this.color);

  static HealthBand fromScore(int score) {
    if (score < 40) return HealthBand.poor;
    if (score < 65) return HealthBand.fair;
    if (score < 85) return HealthBand.good;
    return HealthBand.excellent;
  }
}

class HealthScore {
  final int totalScore;
  final String monthKey; // e.g., "2024-03"
  final DateTime calculatedAt;

  // Breakdown points
  final int savingsPoints;       // Max 30
  final int budgetPoints;        // Max 25
  final int trendPoints;         // Max 20
  final int consistencyPoints;   // Max 15
  final int growthPoints;        // Max 10

  // Raw metrics for the breakdown UI
  final double savingsRate;
  final double budgetAdherence;
  final double spendVsAverage;
  final int activeDays;

  HealthScore({
    required this.totalScore,
    required this.monthKey,
    required this.calculatedAt,
    required this.savingsPoints,
    required this.budgetPoints,
    required this.trendPoints,
    required this.consistencyPoints,
    required this.growthPoints,
    required this.savingsRate,
    required this.budgetAdherence,
    required this.spendVsAverage,
    required this.activeDays,
  });

  HealthBand get band => HealthBand.fromScore(totalScore);

  String get coachingMessage {
    if (totalScore >= 85) return "Fantastic! You're a financial superstar. Keep it up!";
    if (totalScore >= 65) return "Good progress! Watch your budget adherence to reach Excellent.";
    if (totalScore >= 40) return "Fair. Try reducing non-essential spending to boost your score.";
    return "Needs attention. Focus on building a small savings buffer first.";
  }

  static HealthScore calculate(List<TransactionModel> txs, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final monthTxs = txs.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    if (monthTxs.isEmpty) {
      return _empty(month);
    }

    final income = monthTxs.where((t) => t.type == TxType.income).fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthTxs.where((t) => t.type == TxType.expense).fold(0.0, (sum, t) => sum + t.amount);

    // 1. Savings Rate (Max 30)
    final rate = income > 0 ? (income - expense) / income : 0.0;
    final savingsPoints = (rate * 100 / 0.75).clamp(0, 30).round(); // Max at 22.5% savings

    // 2. Consistency (Max 15)
    final activeDays = monthTxs.map((t) => t.date.day).toSet().length;
    final consistencyPoints = (activeDays / 15 * 15).clamp(0, 15).round();

    // 3. Defaults for other complex metrics
    const budgetPoints = 15;
    const trendPoints = 10;
    const growthPoints = 5;

    final total = savingsPoints + budgetPoints + trendPoints + consistencyPoints + growthPoints;

    return HealthScore(
      totalScore: total,
      monthKey: "${month.year}-${month.month.toString().padLeft(2, '0')}",
      calculatedAt: DateTime.now(),
      savingsPoints: savingsPoints,
      budgetPoints: budgetPoints,
      trendPoints: trendPoints,
      consistencyPoints: consistencyPoints,
      growthPoints: growthPoints,
      savingsRate: rate,
      budgetAdherence: 0.6, // Placeholder
      spendVsAverage: 1.0,  // Placeholder
      activeDays: activeDays,
    );
  }

  static HealthScore _empty(DateTime month) {
    return HealthScore(
      totalScore: 0,
      monthKey: "${month.year}-${month.month.toString().padLeft(2, '0')}",
      calculatedAt: DateTime.now(),
      savingsPoints: 0,
      budgetPoints: 0,
      trendPoints: 0,
      consistencyPoints: 0,
      growthPoints: 0,
      savingsRate: 0,
      budgetAdherence: 0,
      spendVsAverage: 1.0,
      activeDays: 0,
    );
  }
}
