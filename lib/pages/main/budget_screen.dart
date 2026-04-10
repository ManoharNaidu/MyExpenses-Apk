import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../data/budget_repository.dart';
import '../../data/transaction_repository.dart';

/// Full-page budget-management screen.
///
/// Shows per-category budget cards for the selected month,
/// lets users add / edit / delete budgets, and visualises
/// spending progress with animated progress bars.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  StreamSubscription? _budgetSub;
  StreamSubscription? _txSub;

  @override
  void initState() {
    super.initState();
    BudgetRepository.ensureLoaded();
    TransactionRepository.ensureInitialized();

    // Rebuild when budgets or transactions change
    _budgetSub = BudgetRepository.stream.listen((_) {
      if (mounted) setState(() {});
    });
    _txSub = TransactionRepository.getTransactionsStream().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _txSub?.cancel();
    super.dispose();
  }

  String _currencySymbol() {
    final code = ref.read(authProvider).state.effectiveCurrency;
    return currencyFromCode(code).symbol;
  }

  void _goMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
  }

  // ───────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statuses = BudgetRepository.statusForMonth(_selectedMonth);
    final sym = _currencySymbol();
    final authState = ref.watch(authProvider).state;
    final expenseCategories = authState.effectiveExpenseCategories;

    final bg = isDark ? AppTheme.darkBg : AppTheme.cream;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.card;
    final textPri = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPri,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Budgets',
          style: TextStyle(
            color: textPri,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.accent,
              size: 26,
            ),
            tooltip: 'Add Budget',
            onPressed: () =>
                _showAddBudgetSheet(context, expenseCategories, sym),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          _monthSelector(textPri, textSec).animate().fadeIn(duration: 250.ms),
          const SizedBox(height: 8),

          // Overview chip row
          if (statuses.isNotEmpty)
            _overviewChips(
              statuses,
              sym,
              isDark,
              textPri,
              textSec,
            ).animate().fadeIn(delay: 80.ms, duration: 250.ms),

          const SizedBox(height: 8),

          // Budget list
          Expanded(
            child: statuses.isEmpty
                ? _emptyState(context, expenseCategories, sym)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: statuses.length,
                    itemBuilder: (ctx, i) => _budgetCard(
                      statuses[i],
                      sym,
                      isDark,
                      cardColor,
                      textPri,
                      textSec,
                      i,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  //  MONTH SELECTOR
  // ───────────────────────────────────────────────────

  Widget _monthSelector(Color textPri, Color textSec) {
    final label = DateFormat('MMMM yyyy').format(_selectedMonth);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: textSec, size: 28),
            onPressed: () => _goMonth(-1),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPri,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: textSec, size: 28),
            onPressed: () => _goMonth(1),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  //  OVERVIEW CHIPS
  // ───────────────────────────────────────────────────

  Widget _overviewChips(
    List<BudgetStatus> statuses,
    String sym,
    bool isDark,
    Color textPri,
    Color textSec,
  ) {
    final totalBudget = statuses.fold<double>(0, (s, b) => s + b.limit);
    final totalSpent = statuses.fold<double>(0, (s, b) => s + b.spent);
    final overCount = statuses.where((s) => s.isOverBudget).length;
    final warnCount = statuses.where((s) => s.isWarning).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip(
            '$sym${_compact(totalSpent)} / $sym${_compact(totalBudget)}',
            isDark ? AppTheme.darkAccent : AppTheme.accent,
            isDark,
          ),
          const SizedBox(width: 8),
          if (overCount > 0)
            _chip(
              '$overCount over',
              isDark ? AppTheme.darkExpense : AppTheme.expenseRed,
              isDark,
            ),
          if (warnCount > 0) ...[
            const SizedBox(width: 8),
            _chip('$warnCount warning', AppTheme.budgetAmber, isDark),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  //  BUDGET CARD
  // ───────────────────────────────────────────────────

  Widget _budgetCard(
    BudgetStatus status,
    String sym,
    bool isDark,
    Color cardColor,
    Color textPri,
    Color textSec,
    int index,
  ) {
    final pct = status.percentage;
    final barColor = status.isOverBudget
        ? (isDark ? AppTheme.darkExpense : AppTheme.expenseRed)
        : status.isWarning
        ? AppTheme.budgetAmber
        : (isDark ? AppTheme.darkIncome : AppTheme.incomeGreen);

    final barBg = isDark ? AppTheme.darkField : const Color(0xFFEEEBE7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showEditBudgetSheet(context, status, sym),
        child:
            Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: category + amount
                      Row(
                        children: [
                          // Category icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _categoryIcon(status.category),
                              size: 18,
                              color: barColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Category name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.category,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPri,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status.isOverBudget
                                      ? 'Over by $sym${_fmt(status.spent - status.limit)}'
                                      : '$sym${_fmt(status.remaining)} remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status.isOverBudget
                                        ? barColor
                                        : textSec,
                                    fontWeight: status.isOverBudget
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$sym${_fmt(status.spent)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPri,
                                ),
                              ),
                              Text(
                                'of $sym${_fmt(status.limit)}',
                                style: TextStyle(fontSize: 12, color: textSec),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: barBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Percentage label
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: barColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: (60 * index).ms, duration: 300.ms)
                .slideY(
                  begin: 0.06,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  //  EMPTY STATE
  // ───────────────────────────────────────────────────

  Widget _emptyState(
    BuildContext context,
    List<String> categories,
    String sym,
  ) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary.withValues(alpha: 0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 72, color: color),
            const SizedBox(height: 20),
            Text(
              'No budgets set',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set monthly budgets per category to track your spending and stay in control.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddBudgetSheet(context, categories, sym),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Budget'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  //  ADD BUDGET SHEET
  // ───────────────────────────────────────────────────

  void _showAddBudgetSheet(
    BuildContext context,
    List<String> categories,
    String sym,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;
    final sheetBg = isDark ? AppTheme.darkElevated : Colors.white;
    final fieldBg = isDark ? AppTheme.darkField : AppTheme.fieldFill;

    // Filter out categories that already have budgets
    final existing = BudgetRepository.forMonth(
      _selectedMonth,
    ).map((b) => b.category).toSet();
    final available = categories.where((c) => !existing.contains(c)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All categories already have budgets set.'),
        ),
      );
      return;
    }

    String selectedCategory = available.first;
    final amountController = TextEditingController();
    bool setAsDefault = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textSec.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set Budget',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPri,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: TextStyle(fontSize: 13, color: textSec),
                  ),
                  const SizedBox(height: 20),

                  // Category picker
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSec,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: sheetBg,
                      style: TextStyle(
                        fontSize: 15,
                        color: textPri,
                        fontWeight: FontWeight.w500,
                      ),
                      items: available
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setSheetState(
                        () => selectedCategory = v ?? selectedCategory,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  Text(
                    'Monthly Limit ($sym)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSec,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: textPri,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      filled: true,
                      fillColor: fieldBg,
                      prefixText: '$sym ',
                      prefixStyle: TextStyle(
                        fontSize: 15,
                        color: textSec,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Default toggle
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: setAsDefault,
                          onChanged: (v) =>
                              setSheetState(() => setAsDefault = v),
                          activeColor: Colors.white,
                          activeTrackColor: AppTheme.accent,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD1D5DB),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Apply to all months (default budget)',
                          style: TextStyle(fontSize: 13, color: textSec),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (amount == null || amount <= 0) return;
                        await BudgetRepository.setBudget(
                          selectedCategory,
                          amount,
                          month: setAsDefault ? null : _selectedMonth,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Budget',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────
  //  EDIT BUDGET SHEET
  // ───────────────────────────────────────────────────

  void _showEditBudgetSheet(
    BuildContext context,
    BudgetStatus status,
    String sym,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;
    final sheetBg = isDark ? AppTheme.darkElevated : Colors.white;
    final fieldBg = isDark ? AppTheme.darkField : AppTheme.fieldFill;

    final amountController = TextEditingController(
      text: status.limit.toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSec.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit — ${status.category}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPri,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark
                          ? AppTheme.darkExpense
                          : AppTheme.expenseRed,
                    ),
                    onPressed: () async {
                      await BudgetRepository.deleteBudget(status.category);
                      // Also delete the default if it exists
                      await BudgetRepository.deleteBudget(
                        status.category,
                        month: _selectedMonth,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current spending info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18, color: textSec),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Spent this month: $sym${_fmt(status.spent)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(status.percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: status.isOverBudget
                            ? (isDark
                                  ? AppTheme.darkExpense
                                  : AppTheme.expenseRed)
                            : status.isWarning
                            ? AppTheme.budgetAmber
                            : (isDark
                                  ? AppTheme.darkIncome
                                  : AppTheme.incomeGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount input
              Text(
                'Monthly Limit ($sym)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSec,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: textPri,
                  fontWeight: FontWeight.w500,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '0.00',
                  filled: true,
                  fillColor: fieldBg,
                  prefixText: '$sym ',
                  prefixStyle: TextStyle(
                    fontSize: 15,
                    color: textSec,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) return;
                    // Update both the default and month-specific entry
                    await BudgetRepository.setBudget(status.category, amount);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Update Budget',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────
  //  HELPERS
  // ───────────────────────────────────────────────────

  static String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  static String _compact(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return _fmt(v);
  }

  static IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'room rent':
      case 'housing':
        return Icons.home_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'utilities':
        return Icons.flash_on_outlined;
      case 'medical':
        return Icons.local_hospital_outlined;
      case 'food':
      case 'dining out':
        return Icons.restaurant_outlined;
      case 'groceries':
        return Icons.shopping_cart_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'sports':
        return Icons.fitness_center_outlined;
      case 'savings':
        return Icons.savings_outlined;
      default:
        return Icons.label_outlined;
    }
  }
}
