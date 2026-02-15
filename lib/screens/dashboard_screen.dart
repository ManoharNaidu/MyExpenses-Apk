import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/staged_transaction_draft.dart';
import '../utils/date_utils.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/app_feedback_dialog.dart';
import '../widgets/summary_card.dart';
import '../data/transaction_repository.dart';
import '../core/api/api_client.dart';
import '../core/auth/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isUploadingPdf = false;

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
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

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Upload failed: ${res.statusCode} - ${res.body}');
      }

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

      final selectedUserCats = context
          .read<AuthProvider>()
          .state
          .effectiveExpenseCategories;
      final selectedIncomeCats = context
          .read<AuthProvider>()
          .state
          .effectiveIncomeCategories;

      final needsIncomeReview = drafts.any((d) => d.type == TxType.income);
      final needsExpenseReview = drafts.any((d) => d.type == TxType.expense);

      if (needsIncomeReview && selectedIncomeCats.isEmpty) {
        await showAppFeedbackDialog(
          context,
          title: 'Categories Required',
          message:
              'Please add income categories in Settings before confirming staged income transactions.',
          type: AppFeedbackType.error,
        );
        return;
      }

      if (needsExpenseReview && selectedUserCats.isEmpty) {
        await showAppFeedbackDialog(
          context,
          title: 'Categories Required',
          message:
              'Please add expense categories in Settings before confirming staged expense transactions.',
          type: AppFeedbackType.error,
        );
        return;
      }

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
        title: 'Upload Error',
        message: '$e',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isUploadingPdf = false);
    }
  }

  Future<List<StagedTransactionDraft>?> _openStagingReview(
    List<StagedTransactionDraft> drafts, {
    required List<String> incomeCategories,
    required List<String> expenseCategories,
  }) async {
    return Navigator.of(context).push<List<StagedTransactionDraft>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _StagingReviewScreen(
          drafts: drafts,
          incomeCategories: incomeCategories,
          expenseCategories: expenseCategories,
        ),
      ),
    );
  }

  Future<List<StagedTransactionDraft>> _extractStagingDrafts(
    dynamic decoded,
  ) async {
    final inline = StagedTransactionDraft.fromUploadResponse(decoded);
    if (inline.isNotEmpty) return inline;

    final listEndpoints = ['/staging-transactions'];

    for (final path in listEndpoints) {
      final res = await ApiClient.get(path);
      if (res.statusCode < 200 || res.statusCode >= 300 || res.body.isEmpty) {
        continue;
      }

      try {
        final parsed = jsonDecode(res.body);
        final drafts = StagedTransactionDraft.fromUploadResponse(parsed);
        if (drafts.isNotEmpty) return drafts;
      } catch (_) {
        // Try next endpoint.
      }
    }

    return [];
  }

  Future<void> _confirmStagedTransactions(
    List<StagedTransactionDraft> accepted,
  ) async {
    final transactions = accepted
        .where((e) => (e.stagingId ?? '').isNotEmpty)
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

    final res = await ApiClient.post('/confirm-staging-transactions', {
      'transactions': transactions,
    });

    if (res.statusCode >= 200 && res.statusCode < 300) {
      await TransactionRepository.refresh();
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Success',
        message: 'Transactions confirmed and saved.',
        type: AppFeedbackType.success,
      );
      return;
    }

    if (!mounted) return;
    await showAppFeedbackDialog(
      context,
      title: 'Confirmation Failed',
      message: '${res.statusCode} - ${res.body}',
      type: AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      initialData: TransactionRepository.currentTransactions,
      builder: (context, snapshot) {
        if (snapshot.data == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final txs = snapshot.data ?? [];

        final now = DateTime.now();
        final weekStart = DateUtilsX.weekStartMonday(now);
        final weekEnd = DateUtilsX.weekEndSunday(now);
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

        bool isThisWeek(TransactionModel t) =>
            !t.date.isBefore(weekStart) && !t.date.isAfter(weekEnd);

        bool isThisMonth(TransactionModel t) =>
            t.date.year == monthKey.year && t.date.month == monthKey.month;

        final weekNet = sumWhere(isThisWeek);
        final monthNet = sumWhere(isThisMonth);

        final weekIncome = incomeWhere(isThisWeek);
        final weekExpense = expenseWhere(isThisWeek);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => AddTransactionModal(onSaved: () {}),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                SummaryCard(
                  title: "This Week (Net)",
                  value: weekNet.toStringAsFixed(2),
                  icon: Icons.date_range_rounded,
                ),
                SummaryCard(
                  title: "This Month (Net)",
                  value: monthNet.toStringAsFixed(2),
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUploadingPdf ? null : _uploadPdfAndReview,
                    icon: _isUploadingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(
                      _isUploadingPdf ? 'Uploading PDF...' : 'Upload Bank PDF',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: "Week Income",
                        value: weekIncome.toStringAsFixed(2),
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: "Week Expense",
                        value: weekExpense.toStringAsFixed(2),
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text("Recent", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...txs
                    .take(10)
                    .map(
                      (t) => Card(
                        child: ListTile(
                          title: Text(
                            t.category,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            "${DateUtilsX.yyyyMmDd(t.date)} • ${t.type == TxType.income ? "Income" : "Expense"}",
                          ),
                          trailing: Text(
                            (t.type == TxType.income ? "+" : "-") +
                                t.amount.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: t.type == TxType.income
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StagingReviewScreen extends StatefulWidget {
  final List<StagedTransactionDraft> drafts;
  final List<String> incomeCategories;
  final List<String> expenseCategories;

  const _StagingReviewScreen({
    required this.drafts,
    required this.incomeCategories,
    required this.expenseCategories,
  });

  @override
  State<_StagingReviewScreen> createState() => _StagingReviewScreenState();
}

class _StagingReviewScreenState extends State<_StagingReviewScreen> {
  late final List<StagedTransactionDraft> _edited;

  @override
  void initState() {
    super.initState();
    _edited = List<StagedTransactionDraft>.from(widget.drafts);
  }

  @override
  Widget build(BuildContext context) {
    final acceptedCount = _edited.where((e) => e.accepted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review staged transactions'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$acceptedCount/${_edited.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton(
                  onPressed: acceptedCount == 0
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            _edited.where((e) => e.accepted).toList(),
                          );
                        },
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
                final categoryOptions = item.type == TxType.income
                    ? widget.incomeCategories
                    : widget.expenseCategories;
                final safeCategory = categoryOptions.contains(item.category)
                    ? item.category
                    : (categoryOptions.isNotEmpty
                          ? categoryOptions.first
                          : item.category);

                if (safeCategory != item.category) {
                  _edited[index] = item.copyWith(category: safeCategory);
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
                              onChanged: (v) {
                                setState(
                                  () => _edited[index] = item.copyWith(
                                    accepted: v ?? false,
                                  ),
                                );
                              },
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
                                color: item.type == TxType.income
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Predicted: '
                          '${item.predicted_type == TxType.income ? 'Income' : 'Expense'} '
                          '• ${item.predicted_category}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TxType>(
                                initialValue: item.type,
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
                                  final nextCategory =
                                      nextOptions.contains(item.category)
                                      ? item.category
                                      : (nextOptions.isNotEmpty
                                            ? nextOptions.first
                                            : item.category);

                                  setState(
                                    () => _edited[index] = item.copyWith(
                                      type: v,
                                      category: nextCategory,
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
                                items: categoryOptions
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(
                                    () => _edited[index] = item.copyWith(
                                      category: v,
                                    ),
                                  );
                                },
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
