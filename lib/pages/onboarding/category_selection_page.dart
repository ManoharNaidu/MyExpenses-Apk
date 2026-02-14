import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/auth/auth_provider.dart';
import '../../app/theme.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final Set<String> selectedIncome = {};
  final Set<String> selectedExpense = {};
  final _incomeCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _expenseCtrl.dispose();
    super.dispose();
  }

  void _addCustomIncome() {
    final value = _incomeCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      selectedIncome.add(value);
      _incomeCtrl.clear();
    });
  }

  void _addCustomExpense() {
    final value = _expenseCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      selectedExpense.add(value);
      _expenseCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Categories",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Choose your categories",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pick both income and expense categories. You can add your own too.",
              style: TextStyle(fontSize: 14, color: AppTheme.textSoft),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Income Categories",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...predefinedIncomeCategories.map((cat) {
                          final isSelected = selectedIncome.contains(cat);
                          return FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                val
                                    ? selectedIncome.add(cat)
                                    : selectedIncome.remove(cat);
                              });
                            },
                            backgroundColor: AppTheme.card,
                            selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.accentDark,
                          );
                        }),
                        ...selectedIncome
                            .where(
                              (cat) =>
                                  !predefinedIncomeCategories.contains(cat),
                            )
                            .map(
                              (cat) => InputChip(
                                label: Text(cat),
                                onDeleted: () {
                                  setState(() => selectedIncome.remove(cat));
                                },
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _incomeCtrl,
                            decoration: const InputDecoration(
                              labelText: "Add custom income category",
                            ),
                            onSubmitted: (_) => _addCustomIncome(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCustomIncome,
                          icon: const Icon(Icons.add_circle_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Expense Categories",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...predefinedExpenseCategories.map((cat) {
                          final isSelected = selectedExpense.contains(cat);
                          return FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                val
                                    ? selectedExpense.add(cat)
                                    : selectedExpense.remove(cat);
                              });
                            },
                            backgroundColor: AppTheme.card,
                            selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.accentDark,
                          );
                        }),
                        ...selectedExpense
                            .where(
                              (cat) =>
                                  !predefinedExpenseCategories.contains(cat),
                            )
                            .map(
                              (cat) => InputChip(
                                label: Text(cat),
                                onDeleted: () {
                                  setState(() => selectedExpense.remove(cat));
                                },
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expenseCtrl,
                            decoration: const InputDecoration(
                              labelText: "Add custom expense category",
                            ),
                            onSubmitted: (_) => _addCustomExpense(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCustomExpense,
                          icon: const Icon(Icons.add_circle_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selected count
            if (selectedIncome.isNotEmpty || selectedExpense.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  "Income: ${selectedIncome.length} • Expense: ${selectedExpense.length}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (selectedIncome.isEmpty && selectedExpense.isEmpty)
                    ? null
                    : () {
                        final incomeList = selectedIncome.toList();
                        final expenseList = selectedExpense.toList();
                        final categoriesList = {...incomeList, ...expenseList}
                            .toList();

                        debugPrint(
                          "🎯 Onboarding categories income=$incomeList expense=$expenseList",
                        );

                        context.read<AuthProvider>().markOnboarded(
                          categories: categoriesList,
                          incomeCategories: incomeList,
                          expenseCategories: expenseList,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () {
                  context.read<AuthProvider>().markOnboarded();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Skip for now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
