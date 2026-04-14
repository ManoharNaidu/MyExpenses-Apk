import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../data/category_budget_repository.dart';
import '../../data/staged_draft_repository.dart';
import '../../data/transaction_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/category_budget.dart';
import '../../pages/main/budget_management_screen.dart';
import '../../pages/main/staged_review_screen.dart';
import '../../widgets/dashboard_budget_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/category_icons.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
    final userId = ref.read(authProvider).state.userId;
    CategoryBudgetRepository.setCurrentUserId(userId);
    unawaited(CategoryBudgetRepository.ensureInitialized());
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select month',
    );
    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userName = (auth.userName == null || auth.userName!.trim().isEmpty)
        ? 'there'
        : auth.userName!.trim();

    final currencySymbol = currencyFromCode(auth.effectiveCurrency).symbol;

    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      initialData: TransactionRepository.currentTransactions,
      builder: (context, snapshot) {
        final txs = snapshot.data ?? const <TransactionModel>[];
        final expenseColor = transactionTypeColor(context, TxType.expense);
        final incomeColor = transactionTypeColor(context, TxType.income);

        final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

        final selectedTxs = txs.where((tx) {
          return !tx.date.isBefore(start) && tx.date.isBefore(end);
        }).toList();

        double income = 0;
        double expenses = 0;
        for (final tx in selectedTxs) {
          if (tx.type == TxType.income) {
            income += tx.amount;
          } else {
            expenses += tx.amount;
          }
        }

        final savings = income - expenses;
        final daysInMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
          0,
        ).day;
        final dailyAverage = daysInMonth == 0 ? 0.0 : expenses / daysInMonth;

        final topFive = List<TransactionModel>.from(selectedTxs)
          ..sort((a, b) => b.date.compareTo(a.date));
        if (topFive.length > 5) {
          topFive.removeRange(5, topFive.length);
        }

        return RefreshIndicator(
          onRefresh: () =>
              TransactionRepository.loadInitial(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'Welcome, $userName',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _netDisposableCard(
                isDark: isDark,
                monthLabel: DateFormat('MMMM yyyy').format(_selectedMonth),
                currencySymbol: currencySymbol,
                income: income,
                expenses: expenses,
                dailyAverage: dailyAverage,
                savings: savings,
              ),
              const SizedBox(height: 14),
              StreamBuilder<List<CategoryBudget>>(
                stream: CategoryBudgetRepository.getBudgetsStream(),
                initialData: CategoryBudgetRepository.currentBudgets,
                builder: (context, budgetSnapshot) {
                  final budgets =
                      budgetSnapshot.data ?? const <CategoryBudget>[];
                  unawaited(
                    CategoryBudgetRepository.checkThresholds(
                      txs,
                      _selectedMonth,
                    ),
                  );
                  return DashboardBudgetCard(
                    budgets: budgets,
                    transactions: txs,
                    currentMonth: _selectedMonth,
                    currencySymbol: currencySymbol,
                    isDark: isDark,
                    onManage: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BudgetManagementScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              StreamBuilder<int>(
                stream: StagedDraftRepository.getDraftsStream().map(
                  (drafts) => drafts.length,
                ),
                initialData: StagedDraftRepository.currentDrafts.length,
                builder: (context, stagingSnapshot) {
                  final stagedCount = stagingSnapshot.data ?? 0;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepOrange.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.fact_check_rounded,
                          color: Colors.deepOrange,
                        ),
                      ),
                      title: const Text('Review staged transactions'),
                      subtitle: Text(
                        stagedCount == 0
                            ? 'Upload a bank PDF to stage rows for review.'
                            : '$stagedCount row(s) waiting for review and confirmation.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StagedReviewScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Recent Activity (${DateFormat('MMM yyyy').format(_selectedMonth)})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (topFive.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No transactions for this month',
                  message:
                      'Use the + button in the footer to add transactions.',
                )
              else
                ...topFive.map(
                  (tx) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transactionTypeColor(
                          context,
                          tx.type,
                        ).withValues(alpha: 0.12),
                        child: Icon(
                          categoryIconFor(tx.category),
                          color: transactionTypeColor(context, tx.type),
                        ),
                      ),
                      title: Text(tx.category),
                      subtitle: Builder(
                        builder: (_) {
                          final source = (tx.notes ?? tx.description ?? '')
                              .trim();
                          final shortDescription = source.length <= 50
                              ? source
                              : '${source.substring(0, 50)}...';
                          if (shortDescription.isEmpty) {
                            return Text(
                              DateFormat('dd MMM yyyy').format(tx.date),
                            );
                          }
                          return Text(
                            shortDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      trailing: Text(
                        '${tx.type == TxType.income ? '+' : '-'}$currencySymbol${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tx.type == TxType.income
                              ? incomeColor
                              : expenseColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _netDisposableCard({
    required bool isDark,
    required String monthLabel,
    required String currencySymbol,
    required double income,
    required double expenses,
    required double dailyAverage,
    required double savings,
  }) {
    final disposable = income - expenses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2B2B31), const Color(0xFF1D1F24)]
              : [const Color(0xFFFFF7E5), const Color(0xFFFFEFD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Disposable',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Select month',
                onPressed: _pickMonth,
                icon: const Icon(Icons.calendar_month_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${disposable.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: disposable >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metricItem(
                  label: 'Income',
                  value: '$currencySymbol${income.toStringAsFixed(2)}',
                  icon: Icons.south_west_rounded,
                  bgColor: isDark
                      ? const Color(0xFF20372C)
                      : const Color(0xFFE7F6EA),
                  accentColor: isDark
                      ? const Color(0xFF4CAF7D)
                      : const Color(0xFF2D7A4F),
                  iconBg: isDark
                      ? const Color(0xFF2D4537)
                      : const Color(0xFFCDEFD8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricItem(
                  label: 'Expenses',
                  value: '$currencySymbol${expenses.toStringAsFixed(2)}',
                  icon: Icons.north_east_rounded,
                  bgColor: isDark
                      ? const Color(0xFF342127)
                      : const Color(0xFFFBE9EC),
                  accentColor: isDark
                      ? const Color(0xFFE05C5C)
                      : const Color(0xFFC0392B),
                  iconBg: isDark
                      ? const Color(0xFF4B2C32)
                      : const Color(0xFFF3CDD3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricItem(
                  label: 'Daily Average',
                  value: '$currencySymbol${dailyAverage.toStringAsFixed(2)}',
                  icon: Icons.insights_rounded,
                  bgColor: isDark
                      ? const Color(0xFF31261D)
                      : const Color(0xFFF7ECDD),
                  accentColor: isDark
                      ? const Color(0xFFE0A85A)
                      : const Color(0xFFC9924A),
                  iconBg: isDark
                      ? const Color(0xFF433627)
                      : const Color(0xFFF0DEBE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricItem(
                  label: 'Savings',
                  value: '$currencySymbol${savings.toStringAsFixed(2)}',
                  icon: Icons.savings_rounded,
                  bgColor: isDark
                      ? const Color(0xFF1F3041)
                      : const Color(0xFFE8F3FB),
                  accentColor: isDark
                      ? const Color(0xFF74B9E8)
                      : const Color(0xFF2F9AD6),
                  iconBg: isDark
                      ? const Color(0xFF2C4054)
                      : const Color(0xFFD3E8F7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
