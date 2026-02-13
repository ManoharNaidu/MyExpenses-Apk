import 'package:flutter/material.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/transaction_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String typeFilter = "All";
  String categoryFilter = "All";
  String monthFilter = "All"; // yyyy-mm
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    TransactionRepository.ensureInitialized();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 200;

    if (nearBottom && !TransactionRepository.isLoading) {
      TransactionRepository.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionRepository.getTransactionsStream(),
      initialData: TransactionRepository.currentTransactions,
      builder: (context, snapshot) {
        if ((snapshot.data == null || snapshot.data!.isEmpty) &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final all = snapshot.data ?? [];

        final months = <String>{};
        final cats = <String>{};

        for (final t in all) {
          months.add(
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}",
          );
          cats.add(t.category);
        }

        List<TransactionModel> filtered = all.where((t) {
          final typeOk =
              typeFilter == "All" ||
              (typeFilter == "Income" && t.type == TxType.income) ||
              (typeFilter == "Expense" && t.type == TxType.expense);

          final catOk = categoryFilter == "All" || t.category == categoryFilter;
          final mKey =
              "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}";
          final monthOk = monthFilter == "All" || mKey == monthFilter;

          return typeOk && catOk && monthOk;
        }).toList();

        final hasMore = TransactionRepository.hasMore;
        final isLoading = TransactionRepository.isLoading;
        final isOnline = TransactionRepository.isOnline;

        final listItemCount = filtered.length + ((hasMore || isLoading) ? 1 : 0);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => AddTransactionModal(onSaved: () {}),
            ),
            child: const Icon(Icons.add_rounded),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: typeFilter,
                        items: const ["All", "Income", "Expense"]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => typeFilter = v ?? "All"),
                        decoration: const InputDecoration(labelText: "Type"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: monthFilter,
                        items:
                            [
                                  "All",
                                  ...months.toList()
                                    ..sort((a, b) => b.compareTo(a)),
                                ]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setState(() => monthFilter = v ?? "All"),
                        decoration: const InputDecoration(labelText: "Month"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoryFilter,
                  items: ["All", ...cats.toList()..sort()]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => categoryFilter = v ?? "All"),
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 12),
                if (!isOnline)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: const Text(
                      'You are offline. Showing cached transactions.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: listItemCount,
                    itemBuilder: (context, i) {
                      if (i >= filtered.length) {
                        if (isLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (hasMore && isOnline) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('Scroll to load more...')),
                          );
                        }

                        return const SizedBox.shrink();
                      }

                      final tx = filtered[i];
                      return TransactionTile(
                        tx: tx,
                        showDeleteOnLeft: true,
                        onDelete: () async {
                          await TransactionRepository.delete(tx.id!);
                        },
                        onEdit: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) =>
                              AddTransactionModal(existing: tx, onSaved: () {}),
                        ),
                      );
                    },
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
