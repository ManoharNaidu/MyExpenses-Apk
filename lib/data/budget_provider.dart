import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import 'budget_repository.dart';

/// Provider for raw budget entries.
final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  return BudgetRepository.stream;
});

/// Provider for budget status computed for the current month.
final budgetStatusProvider = Provider.family<List<BudgetStatus>, DateTime>((ref, month) {
  // Watch budgets to trigger re-compute on change
  ref.watch(budgetsProvider);
  return BudgetRepository.statusForMonth(month);
});
