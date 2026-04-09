import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../models/staged_transaction_draft.dart';
import '../../utils/date_utils.dart';
import '../../widgets/add_transaction_modal.dart';
import '../../widgets/app_feedback_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_tile.dart';
import '../../data/transaction_repository.dart';
import '../../data/staged_draft_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../core/theme/theme_provider.dart';
import '../../app/theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isUploadingPdf = false;

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
    StagedDraftRepository.ensureInitialized();
  }

  Future<void> _uploadPdfAndReview() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    final filePath = kIsWeb ? null : file.path;
    final fileBytes = file.bytes;

    if (filePath == null && fileBytes == null) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Upload Failed',
        message: 'Unable to read selected PDF.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() => _isUploadingPdf = true);

    try {
      final res = await ApiClient.uploadFile(
        '/upload-pdf',
        fieldName: 'file',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: file.name,
      );
      ApiClient.ensureSuccess(res, fallbackMessage: 'Upload failed');

      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : [];
      final drafts = await _extractStagingDrafts(decoded);
      if (!mounted) return;

      if (drafts.isEmpty) {
        await showAppFeedbackDialog(
          context,
          title: 'No Transactions Found',
          message: 'No staged transactions were found in this file.',
          type: AppFeedbackType.error,
        );
        return;
      }

      await StagedDraftRepository.upsertDrafts(drafts);
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Upload Successful',
        message:
            'Your bank statement was uploaded. Review staged transactions to confirm.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Upload Error',
        message: '$e',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isUploadingPdf = false);
    }
  }

  Future<void> _reviewStagedTransactions() async {
    try {
      await StagedDraftRepository.ensureInitialized();
      var drafts = StagedDraftRepository.currentDrafts;
      if (drafts.isEmpty) {
        final fetched = await _extractStagingDrafts(const []);
        if (fetched.isNotEmpty) {
          await StagedDraftRepository.upsertDrafts(fetched);
          drafts = StagedDraftRepository.currentDrafts;
        }
      }
      if (!mounted) return;

      if (drafts.isEmpty) {
        await showAppFeedbackDialog(
          context,
          title: 'No Pending Staged Transactions',
          message: 'Upload a bank statement first.',
          type: AppFeedbackType.error,
        );
        return;
      }

      final selectedUserCats = ref
          .read(authProvider)
          .state
          .effectiveExpenseCategories;
      final selectedIncomeCats = ref
          .read(authProvider)
          .state
          .effectiveIncomeCategories;

      final accepted = await _openStagingReview(
        drafts,
        incomeCategories: selectedIncomeCats,
        expenseCategories: selectedUserCats,
      );

      if (!mounted || accepted == null) return;

      if (accepted.isEmpty) {
        await showAppFeedbackDialog(
          context,
          title: 'No Selection',
          message: 'No transactions selected to confirm.',
          type: AppFeedbackType.error,
        );
        return;
      }

      await _confirmStagedTransactions(accepted);
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Review Error',
        message: '$e',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<List<StagedTransactionDraft>?> _openStagingReview(
    List<StagedTransactionDraft> drafts, {
    required List<String> incomeCategories,
    required List<String> expenseCategories,
  }) async {
    return Navigator.of(context).push<List<StagedTransactionDraft>>(
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _StagingReviewScreen(
            drafts: drafts,
            incomeCategories: incomeCategories,
            expenseCategories: expenseCategories,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<List<StagedTransactionDraft>> _extractStagingDrafts(
    dynamic decoded,
  ) async {
    final inline = StagedTransactionDraft.fromUploadResponse(decoded);
    if (inline.isNotEmpty) return inline;

    final res = await ApiClient.get('/staging');
    if (res.statusCode < 200 || res.statusCode >= 300 || res.body.isEmpty) {
      return [];
    }
    try {
      final parsed = jsonDecode(res.body);
      return StagedTransactionDraft.fromUploadResponse(parsed);
    } catch (_) {
      return [];
    }
  }

  Future<void> _confirmStagedTransactions(
    List<StagedTransactionDraft> accepted,
  ) async {
    final selectedComplete = accepted
        .where(
          (e) =>
              (e.stagingId ?? '').isNotEmpty &&
              e.stagedType != null &&
              (e.stagedCategory ?? '').trim().isNotEmpty,
        )
        .toList();

    final transactions = selectedComplete
        .map((e) => e.toConfirmJson())
        .toList();

    if (transactions.isEmpty) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Invalid Selection',
        message: 'No valid staged transactions selected to confirm.',
        type: AppFeedbackType.error,
      );
      return;
    }

    await TransactionRepository.enqueueStagingConfirmation(transactions);
    final confirmedIds = selectedComplete
        .map((e) => e.stagingId)
        .whereType<String>()
        .toSet();
    await StagedDraftRepository.removeByStagingIds(confirmedIds);
    unawaited(TransactionRepository.syncPendingOperations());

    if (!mounted) return;
    final pending = TransactionRepository.pendingOutboxCount;
    await showAppFeedbackDialog(
      context,
      title: 'Success',
      message: pending == 0
          ? 'Staged confirmations were synced.'
          : 'Staged confirmations were queued for sync.',
      type: AppFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider).mode == ThemeMode.dark;
    final currencyCode = ref.watch(authProvider).state.effectiveCurrency;
    final currencyOption = currencyFromCode(currencyCode);

    final bgColor = isDark ? AppTheme.darkBg : AppTheme.cream;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.textSoft;
    final dividerColor = isDark
        ? AppTheme.darkDivider
        : const Color(0xFFEDE8E3);

    String formatMoney(double amount) {
      final sign = amount < 0 ? '-' : '';
      final absValue = amount.abs().toStringAsFixed(2);
      return '$sign${currencyOption.symbol}$absValue';
    }

    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      initialData: TransactionRepository.currentTransactions,
      builder: (context, snapshot) {
        if (snapshot.data == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final txs = snapshot.data ?? [];

        final now = DateTime.now();
        final monthKey = DateTime(now.year, now.month, 1);

        double sumWhere(bool Function(TransactionModel t) pred) => txs
            .where(pred)
            .fold(
              0.0,
              (a, b) => a + (b.type == TxType.expense ? -b.amount : b.amount),
            );
        double incomeWhere(bool Function(TransactionModel t) pred) => txs
            .where((t) => pred(t) && t.type == TxType.income)
            .fold(0.0, (a, b) => a + b.amount);
        double expenseWhere(bool Function(TransactionModel t) pred) => txs
            .where((t) => pred(t) && t.type == TxType.expense)
            .fold(0.0, (a, b) => a + b.amount);

        bool isThisMonth(TransactionModel t) =>
            t.date.year == now.year && t.date.month == now.month;

        final monthNet = sumWhere(isThisMonth);
        final monthIncome = incomeWhere(isThisMonth);
        final monthExpense = expenseWhere(isThisMonth);

        return Container(
          color: bgColor,
          child: RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () =>
                TransactionRepository.loadInitial(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (txs.isEmpty) ...[
                  const SizedBox(height: 24),
                  EmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No transactions yet',
                    message:
                        'Add your first income or expense to see summaries here.',
                    actionLabel: 'Add transaction',
                    onAction: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => AddTransactionModal(onSaved: () {}),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                ],

                // ── Monthly Overview Card ──
                _MonthlyOverviewCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: dividerColor,
                      monthNet: monthNet,
                      monthIncome: monthIncome,
                      monthExpense: monthExpense,
                      formatMoney: formatMoney,
                      now: now,
                    )
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 400.ms)
                    .slideY(begin: 0.06),

                const SizedBox(height: 16),

                // ── Recent Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _reviewStagedTransactions,
                      icon: Icon(
                        Icons.playlist_add_check_circle_outlined,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                      label: Text(
                        'Review Staged',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 120.ms),

                const SizedBox(height: 8),

                if (txs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Your recent transactions will appear here.',
                      style: TextStyle(color: textSecondary),
                    ),
                  )
                else
                  ...txs.take(10).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    return TransactionTile(
                          tx: t,
                          onEdit: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => AddTransactionModal(
                              existing: t,
                              onSaved: () {},
                            ),
                          ),
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Transaction'),
                                content: const Text(
                                  'Are you sure you want to delete this transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await TransactionRepository.delete(t.id!);
                              HapticFeedback.lightImpact();
                            }
                          },
                        )
                        .animate(delay: Duration(milliseconds: 140 + i * 40))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.04);
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Monthly Overview Card ────────────────────────────────────────────────────

class _MonthlyOverviewCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor, textPrimary, textSecondary, dividerColor;
  final double monthNet, monthIncome, monthExpense;
  final String Function(double) formatMoney;
  final DateTime now;

  const _MonthlyOverviewCard({
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.monthNet,
    required this.monthIncome,
    required this.monthExpense,
    required this.formatMoney,
    required this.now,
  });

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysPassed = now.day;
    final dailyAvg = monthExpense / daysPassed;
    final savingsRate = monthIncome > 0
        ? ((monthIncome - monthExpense) / monthIncome) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withValues(alpha: 0.8),
                ],
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_months[now.month - 1]} ${now.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_graph_rounded,
                  size: 20,
                  color: textSecondary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),

          // Main Balance section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET DISPOSABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formatMoney(monthNet),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: netColor,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: netColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: netColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12,
                            color: netColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${savingsRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: netColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Stats Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Income',
                        value: formatMoney(monthIncome),
                        icon: Icons.south_west_rounded,
                        color: const Color(0xFF22C55E),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatPill(
                        label: 'Expenses',
                        value: formatMoney(monthExpense),
                        icon: Icons.north_east_rounded,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Daily Avg',
                        value: formatMoney(dailyAvg),
                        icon: Icons.today_rounded,
                        color: AppTheme.accent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatPill(
                        label: 'Savings %',
                        value: '${savingsRate.toStringAsFixed(1)}%',
                        icon: Icons.savings_rounded,
                        color: const Color(0xFF0EA5E9),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Staging Review Screen ───────────────────────────────────────────────────

class _StagingReviewScreen extends ConsumerStatefulWidget {
  final List<StagedTransactionDraft> drafts;
  final List<String> incomeCategories;
  final List<String> expenseCategories;

  const _StagingReviewScreen({
    required this.drafts,
    required this.incomeCategories,
    required this.expenseCategories,
  });

  @override
  ConsumerState<_StagingReviewScreen> createState() =>
      _StagingReviewScreenState();
}

class _StagingReviewScreenState extends ConsumerState<_StagingReviewScreen> {
  late final List<StagedTransactionDraft> _edited;

  @override
  void initState() {
    super.initState();
    _edited = List<StagedTransactionDraft>.from(widget.drafts);
  }

  void _toggleAll(bool value) {
    setState(() {
      for (var i = 0; i < _edited.length; i++) {
        _edited[i] = _edited[i].copyWith(accepted: value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final acceptedCount = _edited.where((e) => e.accepted).length;
    final allSelected = acceptedCount == _edited.length;
    final validSelectedCount = _edited
        .where(
          (e) =>
              e.accepted &&
              e.stagedType != null &&
              (e.stagedCategory ?? '').trim().isNotEmpty,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review staged'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _toggleAll(!allSelected),
            child: Text(allSelected ? 'Deselect All' : 'Select All'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$acceptedCount/${_edited.length} selected • $validSelectedCount ready',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set both type and category. Only complete selections are sent.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: validSelectedCount == 0
                      ? null
                      : () => Navigator.pop(
                          context,
                          _edited.where((e) => e.accepted).toList(),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.textDark,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _edited.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final item = _edited[index];
                final selectedType = item.stagedType;
                final selectedCategory = item.stagedCategory;
                final categoryOptions = selectedType == null
                    ? const <String>[]
                    : (selectedType == TxType.income
                          ? widget.incomeCategories
                          : widget.expenseCategories);

                final safeCategory =
                    categoryOptions.contains(selectedCategory) &&
                        (selectedCategory ?? '').isNotEmpty
                    ? selectedCategory
                    : null;

                if (safeCategory != selectedCategory) {
                  _edited[index] = item.copyWith(clearStagedCategory: true);
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: item.accepted,
                              activeColor: AppTheme.accent,
                              onChanged: (v) => setState(
                                () => _edited[index] = item.copyWith(
                                  accepted: v ?? false,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.description ?? 'No description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              item.amount.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color:
                                    (selectedType ?? item.predictedType) ==
                                        TxType.income
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Predicted: ${item.predictedType == TxType.income ? "Income" : "Expense"} • ${item.predictedCategory}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TxType>(
                                initialValue: selectedType,
                                hint: const Text('Type'),
                                items: const [
                                  DropdownMenuItem(
                                    value: TxType.income,
                                    child: Text('Income'),
                                  ),
                                  DropdownMenuItem(
                                    value: TxType.expense,
                                    child: Text('Expense'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  final nextOptions = v == TxType.income
                                      ? widget.incomeCategories
                                      : widget.expenseCategories;
                                  final retainedCategory =
                                      nextOptions.contains(selectedCategory)
                                      ? selectedCategory
                                      : null;
                                  setState(
                                    () => _edited[index] = item.copyWith(
                                      stagedType: v,
                                      stagedCategory: retainedCategory,
                                    ),
                                  );
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: safeCategory,
                                hint: const Text('Category'),
                                items: categoryOptions
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => _edited[index] = item.copyWith(
                                    stagedCategory: v,
                                  ),
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
