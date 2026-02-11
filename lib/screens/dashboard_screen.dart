import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction_model.dart';
import '../models/staged_transaction_draft.dart';
import '../utils/date_utils.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/summary_card.dart';
import '../data/transaction_repository.dart';
import '../core/api/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isUploadingPdf = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to read selected PDF")),
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
      final drafts = StagedTransactionDraft.fromUploadResponse(decoded);

      if (!mounted) return;

      if (drafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No transactions detected in PDF")),
        );
        return;
      }

      await _openStagingReview(drafts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingPdf = false);
    }
  }

  Future<void> _openStagingReview(List<StagedTransactionDraft> drafts) async {
    final edited = List<StagedTransactionDraft>.from(drafts);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final acceptedCount = edited.where((e) => e.accepted).length;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Review extracted transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text('$acceptedCount/${edited.length} selected'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: edited.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final d = edited[index];
                          return Card(
                            child: ListTile(
                              onTap: () async {
                                final updated = await _editDraftDialog(d);
                                if (updated != null) {
                                  setSheetState(() => edited[index] = updated);
                                }
                              },
                              leading: Checkbox(
                                value: d.accepted,
                                onChanged: (v) {
                                  setSheetState(
                                    () => edited[index] = d.copyWith(
                                      accepted: v ?? false,
                                    ),
                                  );
                                },
                              ),
                              title: Text(
                                '${d.type == TxType.income ? 'Income' : 'Expense'} • ${d.category}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${DateUtilsX.yyyyMmDd(d.date)}\n${d.description ?? 'No description'}',
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                d.amount.toStringAsFixed(2),
                                style: TextStyle(
                                  color: d.type == TxType.income
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: acceptedCount == 0
                                ? null
                                : () async {
                                    final accepted = edited
                                        .where((e) => e.accepted)
                                        .toList();
                                    await _confirmStagedTransactions(accepted);
                                    if (mounted) Navigator.pop(context);
                                  },
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<StagedTransactionDraft?> _editDraftDialog(
    StagedTransactionDraft draft,
  ) async {
    final amountCtrl = TextEditingController(text: draft.amount.toString());
    final categoryCtrl = TextEditingController(text: draft.category);
    final descCtrl = TextEditingController(text: draft.description ?? '');
    TxType type = draft.type;
    DateTime date = draft.date;

    final updated = await showDialog<StagedTransactionDraft>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<TxType>(
                      value: type,
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
                        if (v != null) setState(() => type = v);
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(DateUtilsX.yyyyMmDd(date)),
                      trailing: const Icon(Icons.calendar_month_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime(2035, 12, 31),
                          initialDate: date,
                        );
                        if (picked != null) setState(() => date = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter valid amount')),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      draft.copyWith(
                        type: type,
                        category: categoryCtrl.text.trim().isEmpty
                            ? 'Misc'
                            : categoryCtrl.text.trim(),
                        amount: amount,
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        date: date,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    amountCtrl.dispose();
    categoryCtrl.dispose();
    descCtrl.dispose();

    return updated;
  }

  Future<void> _confirmStagedTransactions(
    List<StagedTransactionDraft> accepted,
  ) async {
    final payload = {
      'transactions': accepted.map((e) => e.toConfirmJson()).toList(),
    };

    final candidatePaths = [
      '/upload-pdf/confirm',
      '/confirm-upload-pdf',
      '/transactions/confirm',
    ];

    String? lastError;
    for (final path in candidatePaths) {
      final res = await ApiClient.post(path, payload);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await TransactionRepository.refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions confirmed and saved')),
        );
        return;
      }

      if (res.statusCode == 404 || res.statusCode == 405) {
        lastError = 'Endpoint $path not available';
        continue;
      }

      lastError = 'Confirm failed: ${res.statusCode} - ${res.body}';
      break;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lastError ?? 'Failed to confirm transactions')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final txs = snapshot.data ?? [];

        final now = DateTime.now();
        final todayKey = DateTime(now.year, now.month, now.day);
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

        bool isToday(TransactionModel t) =>
            DateTime(t.date.year, t.date.month, t.date.day) == todayKey;

        bool isThisWeek(TransactionModel t) =>
            !t.date.isBefore(weekStart) && !t.date.isAfter(weekEnd);

        bool isThisMonth(TransactionModel t) =>
            t.date.year == monthKey.year && t.date.month == monthKey.month;

        final todayNet = sumWhere(isToday);
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
                  title: "Today (Net)",
                  value: todayNet.toStringAsFixed(2),
                  icon: Icons.today_rounded,
                ),
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
