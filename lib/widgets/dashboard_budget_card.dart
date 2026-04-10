import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/category_budget.dart';
import '../models/transaction_model.dart';

class DashboardBudgetCard extends StatelessWidget {
  final List<CategoryBudget> budgets;
  final List<TransactionModel> transactions;
  final DateTime currentMonth;
  final String currencySymbol;
  final bool isDark;
  final VoidCallback? onManage;

  const DashboardBudgetCard({
    super.key,
    required this.budgets,
    required this.transactions,
    required this.currentMonth,
    required this.currencySymbol,
    required this.isDark,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final active = budgets.where((b) => b.enabled).take(5).toList();
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Budgets',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: onManage, child: const Text('Manage')),
              ],
            ),
            if (active.isEmpty)
              Text(
                'No category budgets set. Tap Manage to add one.',
                style: TextStyle(color: textSecondary),
              )
            else
              ...active.map((budget) {
                final spent = transactions
                    .where(
                      (t) =>
                          t.type == TxType.expense &&
                          t.category == budget.category &&
                          t.date.year == currentMonth.year &&
                          t.date.month == currentMonth.month,
                    )
                    .fold<double>(0, (sum, t) => sum + t.amount);

                final ratio = budget.monthlyLimit <= 0
                    ? 0.0
                    : (spent / budget.monthlyLimit).clamp(0.0, 1.0);
                final color = ratio >= 0.9
                    ? AppTheme.expenseRed
                    : ratio >= 0.7
                    ? AppTheme.budgetAmber
                    : AppTheme.incomeGreen;

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 86,
                        child: Text(
                          budget.category,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: ratio),
                          duration: const Duration(milliseconds: 380),
                          builder: (_, value, __) => LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                            backgroundColor: isDark
                                ? AppTheme.darkField
                                : AppTheme.divider,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currencySymbol${spent.toStringAsFixed(0)} / ${budget.monthlyLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
