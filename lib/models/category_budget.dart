class CategoryBudget {
  final String? id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final bool alertsEnabled;
  final bool enabled;
  final DateTime updatedAt;

  const CategoryBudget({
    this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    this.alertsEnabled = true,
    this.enabled = true,
    required this.updatedAt,
  });

  CategoryBudget copyWith({
    String? id,
    String? userId,
    String? category,
    double? monthlyLimit,
    bool? alertsEnabled,
    bool? enabled,
    DateTime? updatedAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      enabled: enabled ?? this.enabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      monthlyLimit: (json['monthly_limit'] as num?)?.toDouble() ?? 0,
      alertsEnabled: (json['alerts_enabled'] as bool?) ?? true,
      enabled: (json['enabled'] as bool?) ?? true,
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'monthly_limit': monthlyLimit,
      'alerts_enabled': alertsEnabled,
      'enabled': enabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
