/// A single per-category budget entry.
///
/// Budgets are stored locally and keyed by `category`.
/// A null [monthYear] means the budget is a *default* that applies to every
/// month unless overridden.
class BudgetModel {
  final String category;
  final double monthlyLimit;

  /// First day of the month this budget applies to, or `null` for a default.
  final DateTime? monthYear;

  BudgetModel({
    required this.category,
    required this.monthlyLimit,
    this.monthYear,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      category: json['category'] as String,
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      monthYear: json['month_year'] != null
          ? DateTime.parse(json['month_year'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'monthly_limit': monthlyLimit,
      if (monthYear != null)
        'month_year': monthYear!.toIso8601String().split('T')[0],
    };
  }

  BudgetModel copyWith({
    String? category,
    double? monthlyLimit,
    DateTime? monthYear,
  }) {
    return BudgetModel(
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  @override
  String toString() =>
      'BudgetModel(category: $category, limit: $monthlyLimit, month: $monthYear)';
}
