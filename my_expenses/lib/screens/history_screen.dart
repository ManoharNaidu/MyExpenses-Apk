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

  @override
  Widget build(BuildContext context) {
    final all = TransactionRepository.all();

    final months = <String>{};
    final cats = <String>{};

    for (final t in all) {
      months.add("${t.date.year}-${t.date.month.toString().padLeft(2, '0')}");
      cats.add(t.category);
    }

    List<TransactionModel> filtered = all.where((t) {
      final typeOk = typeFilter == "All" ||
          (typeFilter == "Income" && t.type == TxType.income) ||
          (typeFilter == "Expense" && t.type == TxType.expense);

      final catOk = categoryFilter == "All" || t.category == categoryFilter;
      final mKey = "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}";
      final monthOk = monthFilter == "All" || mKey == monthFilter;

      return typeOk && catOk && monthOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => AddTransactionModal(onSaved: () => setState(() {})),
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
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => typeFilter = v ?? "All"),
                    decoration: const InputDecoration(labelText: "Type"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: monthFilter,
                    items: ["All", ...months.toList()..sort((a, b) => b.compareTo(a))]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => monthFilter = v ?? "All"),
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

            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final tx = filtered[i];
                  return TransactionTile(
                    tx: tx,
                    onDelete: () async {
                      await TransactionRepository.delete(tx.id);
                      setState(() {});
                    },
                    onEdit: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => AddTransactionModal(
                        existing: tx,
                        onSaved: () => setState(() {}),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
