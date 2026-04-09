import 'package:flutter/material.dart';

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
}
