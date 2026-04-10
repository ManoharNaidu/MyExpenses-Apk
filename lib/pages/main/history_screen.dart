import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/transaction_repository.dart';
import '../../models/transaction_model.dart';
import '../../widgets/add_transaction_modal.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String typeFilter = "All";
  String categoryFilter = "All";
  String monthFilter = "All"; // yyyy-mm
  String searchQuery = "";
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    TransactionRepository.ensureInitialized();
    unawaited(_loadCategories());
    _searchController.addListener(
      () => setState(
        () => searchQuery = _searchController.text.trim().toLowerCase(),
      ),
    );
  }

  static void unawaited(Future<void> f) => f;

  String _formatMonthFilterLabel(String key) {
    if (key == 'All') return key;
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return key;
    return DateFormat('MMM yyyy').format(DateTime(year, month, 1));
  }

  Future<void> _loadCategories() async {
    await TransactionRepository.fetchCategories();
    if (mounted) setState(() {});
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
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(TransactionModel t) {
    if (searchQuery.isEmpty) return true;
    final notes = (t.notes ?? t.description ?? '').toLowerCase();
    return (t.category.toLowerCase().contains(searchQuery)) ||
        notes.contains(searchQuery) ||
        t.amount.toString().contains(searchQuery);
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
        final all = snapshot.data ?? [];

        final months = <String>{};
        final cats = <String>{
          ...TransactionRepository.incomeCategories,
          ...TransactionRepository.expenseCategories,
        };

        for (final t in all) {
          months.add(
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}",
          );
          if (TransactionRepository.incomeCategories.isEmpty &&
              TransactionRepository.expenseCategories.isEmpty) {
            cats.add(t.category);
          }
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
          final searchOk = _matchesSearch(t);

          return typeOk && catOk && monthOk && searchOk;
        }).toList();

        final hasMore = TransactionRepository.hasMore;
        final isLoading = TransactionRepository.isLoading;
        final isOnline = TransactionRepository.isOnline;

        final listItemCount =
            filtered.length + ((hasMore || isLoading) ? 1 : 0);

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () =>
                TransactionRepository.loadInitial(forceRefresh: true),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by category, notes, amount...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: typeFilter,
                          items: const ["All", "Income", "Expense"]
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
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
                          initialValue: monthFilter,
                          items:
                              [
                                'All',
                                ...months.toList()
                                  ..sort((a, b) => b.compareTo(a)),
                              ].map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(_formatMonthFilterLabel(v)),
                                );
                              }).toList(),
                          onChanged: (v) =>
                              setState(() => monthFilter = v ?? "All"),
                          decoration: const InputDecoration(labelText: "Month"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: categoryFilter,
                    items: ["All", ...cats.toList()..sort()]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => categoryFilter = v ?? "All"),
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                  const SizedBox(height: 12),
                  if (!isOnline)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                    child: all.isEmpty
                        ? EmptyState(
                            icon: Icons.history_rounded,
                            title: 'No transactions yet',
                            message:
                                'Add your first transaction or upload a bank PDF from the Dashboard.',
                            actionLabel: 'Add transaction',
                            onAction: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) =>
                                  AddTransactionModal(onSaved: () {}),
                            ),
                          )
                        : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.filter_list_rounded,
                            title: 'No results',
                            message:
                                'No transactions match your filters or search. Try changing filters or search term.',
                            actionLabel: 'Clear search & filters',
                            onAction: () {
                              setState(() {
                                typeFilter = "All";
                                categoryFilter = "All";
                                monthFilter = "All";
                                _searchController.clear();
                                searchQuery = "";
                              });
                            },
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: listItemCount,
                            itemBuilder: (context, i) {
                              if (i >= filtered.length) {
                                if (isLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (hasMore && isOnline) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text('Scroll to load more...'),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              final tx = filtered[i];
                              return Dismissible(
                                key: ValueKey(
                                  tx.id ?? '${tx.date.toIso8601String()}-$i',
                                ),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) async {
                                  if (tx.id != null) {
                                    await TransactionRepository.delete(tx.id!);
                                  }
                                },
                                child: TransactionTile(
                                  tx: tx,
                                  onDelete: () async {
                                    if (tx.id != null) {
                                      await TransactionRepository.delete(
                                        tx.id!,
                                      );
                                    }
                                  },
                                  onEdit: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (_) => AddTransactionModal(
                                      existing: tx,
                                      onSaved: () {},
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
