import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../data/category_budget_repository.dart';
import '../../data/transaction_repository.dart';
import '../../models/category_budget.dart';
import '../../models/transaction_model.dart';

class BudgetManagementScreen extends ConsumerStatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  ConsumerState<BudgetManagementScreen> createState() =>
      _BudgetManagementScreenState();
}

class _BudgetManagementScreenState
    extends ConsumerState<BudgetManagementScreen> {
  bool _alertsEnabled = true;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authProvider).state.userId;
    CategoryBudgetRepository.setCurrentUserId(userId);
    CategoryBudgetRepository.ensureInitialized();
    TransactionRepository.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).state;
    final categories = authState.effectiveExpenseCategories;
    final symbol = currencyFromCode(authState.effectiveCurrency).symbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Category Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await CategoryBudgetRepository.saveToServer();
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Budgets saved')),
          );
        },
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save all'),
      ),
      body: StreamBuilder<List<CategoryBudget>>(
        stream: CategoryBudgetRepository.getBudgetsStream(),
        initialData: CategoryBudgetRepository.currentBudgets,
        builder: (context, snapshot) {
          final budgets = snapshot.data ?? const <CategoryBudget>[];

          final byCategory = <String, CategoryBudget>{
            for (final b in budgets) b.category: b,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              SwitchListTile(
                title: const Text('Budget Alerts'),
                subtitle: const Text(
                  'Enable notifications for threshold breaches',
                ),
                value: _alertsEnabled,
                onChanged: (value) => setState(() => _alertsEnabled = value),
              ),
              const SizedBox(height: 8),
              ...categories.map((category) {
                final budget =
                    byCategory[category] ??
                    CategoryBudget(
                      userId: authState.userId ?? '',
                      category: category,
                      monthlyLimit: 0,
                      alertsEnabled: true,
                      enabled: false,
                      updatedAt: DateTime.now(),
                    );

                final spent = TransactionRepository.currentTransactions
                    .where(
                      (t) =>
                          t.type == TxType.expense &&
                          t.category == category &&
                          t.date.year == DateTime.now().year &&
                          t.date.month == DateTime.now().month,
                    )
                    .fold<double>(0, (sum, tx) => sum + tx.amount);

                final controller = TextEditingController(
                  text: budget.monthlyLimit > 0
                      ? budget.monthlyLimit.toStringAsFixed(2)
                      : '',
                );

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Monthly limit',
                          prefixText: '$symbol ',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value.trim()) ?? 0;
                          CategoryBudgetRepository.updateBudget(
                            budget.copyWith(
                              monthlyLimit: parsed,
                              enabled: budget.enabled || parsed > 0,
                              alertsEnabled: _alertsEnabled,
                              updatedAt: DateTime.now(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spent: $symbol${spent.toStringAsFixed(2)} this month',
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: budget.enabled,
                    onChanged: (enabled) {
                      CategoryBudgetRepository.updateBudget(
                        budget.copyWith(
                          enabled: enabled,
                          alertsEnabled: _alertsEnabled,
                          updatedAt: DateTime.now(),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
