import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../data/staged_draft_repository.dart';
import '../../data/transaction_repository.dart';
import '../../models/staged_transaction_draft.dart';
import '../../models/transaction_model.dart';
import '../../widgets/app_feedback_dialog.dart';
import '../../widgets/empty_state.dart';

class StagedReviewScreen extends ConsumerStatefulWidget {
  const StagedReviewScreen({super.key});

  @override
  ConsumerState<StagedReviewScreen> createState() => _StagedReviewScreenState();
}

class _StagedReviewScreenState extends ConsumerState<StagedReviewScreen> {
  bool _isConfirming = false;
  bool _isLoadingServer = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _hydrateFromServer();
  }

  Future<void> _hydrateFromServer() async {
    if (_isLoadingServer) return;
    setState(() {
      _isLoadingServer = true;
      _loadError = null;
    });

    try {
      final res = await ApiClient.get('/staging');
      ApiClient.ensureSuccess(
        res,
        fallbackMessage: 'Failed to load staged transactions',
      );
      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : [];
      final drafts = StagedTransactionDraft.fromUploadResponse(decoded);
      await StagedDraftRepository.saveDrafts(drafts);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingServer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).state;
    final theme = Theme.of(context);
    final currencySymbol = currencyFromCode(auth.effectiveCurrency).symbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Staged Transactions')),
      body: StreamBuilder<List<StagedTransactionDraft>>(
        stream: StagedDraftRepository.getDraftsStream(),
        initialData: StagedDraftRepository.currentDrafts,
        builder: (context, snapshot) {
          final drafts = snapshot.data ?? const <StagedTransactionDraft>[];

          if (_isLoadingServer && drafts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (drafts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EmptyState(
                    icon: Icons.playlist_remove_rounded,
                    title: 'No staged transactions',
                    message:
                        'Upload a bank PDF from Dashboard and extracted rows will appear here for review.',
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _hydrateFromServer,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh from server'),
                  ),
                ],
              ),
            );
          }

          final readyCount = drafts
              .where(
                (d) =>
                    d.accepted &&
                    d.stagingId != null &&
                    d.stagingId!.isNotEmpty &&
                    _effectiveCategory(d).isNotEmpty,
              )
              .length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$readyCount of ${drafts.length} row(s) ready to confirm. Rows need both Type and Category.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _hydrateFromServer,
                  child: ListView.builder(
                    itemCount: drafts.length,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      return _DraftCard(
                        draft: draft,
                        currencySymbol: currencySymbol,
                        incomeCategories: auth.effectiveIncomeCategories,
                        expenseCategories: auth.effectiveExpenseCategories,
                        onChanged: (next) => _updateDraft(index, next, drafts),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isConfirming
                        ? null
                        : () => _confirmReadyRows(drafts),
                    icon: _isConfirming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isConfirming
                          ? 'Confirming...'
                          : 'Confirm Ready Rows ($readyCount)',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateDraft(
    int index,
    StagedTransactionDraft next,
    List<StagedTransactionDraft> current,
  ) async {
    final updated = List<StagedTransactionDraft>.from(current);
    updated[index] = next;
    await StagedDraftRepository.saveDrafts(updated);
  }

  Future<void> _confirmReadyRows(List<StagedTransactionDraft> drafts) async {
    final confirmable = drafts
        .where(
          (d) =>
              d.accepted &&
              d.stagingId != null &&
              d.stagingId!.isNotEmpty &&
              _effectiveCategory(d).isNotEmpty,
        )
        .toList();

    if (confirmable.isEmpty) {
      await showAppFeedbackDialog(
        context,
        title: 'Nothing To Confirm',
        message: 'Set Type and Category for at least one accepted row first.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() => _isConfirming = true);
    try {
      await TransactionRepository.enqueueStagingConfirmation(
        confirmable
            .map(
              (d) => {
                'id': d.stagingId,
                'final_type': _effectiveType(d) == TxType.income
                    ? 'income'
                    : 'expense',
                'final_category': _effectiveCategory(d),
              },
            )
            .toList(),
      );
      await StagedDraftRepository.removeByStagingIds(
        confirmable.map((d) => d.stagingId!).toSet(),
      );

      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Queued For Sync',
        message:
            '${confirmable.length} staged transaction(s) were queued for confirmation.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Confirmation Failed',
        message: '$e',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  TxType _effectiveType(StagedTransactionDraft draft) {
    return draft.stagedType ?? draft.predictedType;
  }

  String _effectiveCategory(StagedTransactionDraft draft) {
    final explicit = (draft.stagedCategory ?? '').trim();
    if (explicit.isNotEmpty) return explicit;
    return draft.predictedCategory.trim();
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.currencySymbol,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.onChanged,
  });

  final StagedTransactionDraft draft;
  final String currencySymbol;
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final ValueChanged<StagedTransactionDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedType = draft.stagedType ?? draft.predictedType;
    final selectedCategory = (draft.stagedCategory ?? draft.predictedCategory)
        .trim();
    final categoryOptions = _categoryOptionsFor(selectedType, selectedCategory);
    final isReady = draft.accepted && selectedCategory.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(draft.date),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isReady
                        ? Colors.green.withValues(alpha: 0.14)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isReady ? 'Ready' : 'Needs review',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isReady ? Colors.green.shade800 : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$currencySymbol${draft.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((draft.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                draft.description!.trim(),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Predicted: ${_typeLabel(draft.predictedType)} • ${draft.predictedCategory}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<TxType>(
                    segments: const [
                      ButtonSegment<TxType>(
                        value: TxType.expense,
                        label: Text('Expense'),
                      ),
                      ButtonSegment<TxType>(
                        value: TxType.income,
                        label: Text('Income'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      final picked = selection.first;
                      onChanged(
                        draft.copyWith(
                          stagedType: picked,
                          clearStagedCategory: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Final category',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: categoryOptions
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(
                  draft.copyWith(
                    stagedType: selectedType,
                    stagedCategory: value,
                    accepted: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: draft.accepted,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include this row in confirmation'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                if (value == null) return;
                onChanged(draft.copyWith(accepted: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<String> _categoryOptionsFor(TxType type, String selectedCategory) {
    final base = type == TxType.income ? incomeCategories : expenseCategories;
    final merged = <String>{
      ...base.map((c) => c.trim()).where((c) => c.isNotEmpty),
      draft.predictedCategory.trim(),
      selectedCategory,
    };
    final sorted = merged.toList()..sort();
    if (sorted.isEmpty) {
      sorted.add(type == TxType.income ? 'Income' : 'Misc');
    }
    return sorted;
  }

  String _typeLabel(TxType type) =>
      type == TxType.income ? 'Income' : 'Expense';
}
