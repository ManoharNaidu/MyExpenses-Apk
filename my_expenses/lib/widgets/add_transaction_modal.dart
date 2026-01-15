import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../data/transaction_repository.dart';

class AddTransactionModal extends StatefulWidget {
  final TransactionModel? existing;
  final VoidCallback onSaved;

  const AddTransactionModal({super.key, this.existing, required this.onSaved});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late TxType type;
  late String category;
  String payment = "Card";
  DateTime date = DateTime.now();

  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final incomeCats = const ["Transfer", "IveHub", "Dash/Uber", "Part-Time"];
  final expenseCats = const ["RoomRent", "Scooty Rent", "PAC", "Groceries", "Petrol", "Food", "Misc"];

  @override
  void initState() {
    super.initState();

    final e = widget.existing;
    type = e?.type ?? TxType.expense;
    category = e?.category ?? (type == TxType.income ? incomeCats.first : expenseCats.first);
    payment = e?.paymentMethod ?? "Card";
    date = e?.date ?? DateTime.now();

    if (e != null) {
      amountCtrl.text = e.amount.toStringAsFixed(2);
      notesCtrl.text = e.notes;
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = type == TxType.income ? incomeCats : expenseCats;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? "Add Transaction" : "Edit Transaction",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // amount
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(
                hintText: "0.00",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 8),

            // type toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pill(
                  label: "Income",
                  selected: type == TxType.income,
                  onTap: () => setState(() {
                    type = TxType.income;
                    category = incomeCats.first;
                  }),
                ),
                const SizedBox(width: 10),
                _pill(
                  label: "Expense",
                  selected: type == TxType.expense,
                  onTap: () => setState(() {
                    type = TxType.expense;
                    category = expenseCats.first;
                  }),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // category dropdown
            DropdownButtonFormField<String>(
              value: category,
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => category = v ?? category),
              decoration: const InputDecoration(labelText: "Category"),
            ),

            const SizedBox(height: 10),

            // payment
            DropdownButtonFormField<String>(
              value: payment,
              items: const [
                DropdownMenuItem(value: "Card", child: Text("Card")),
                DropdownMenuItem(value: "Cash", child: Text("Cash")),
              ],
              onChanged: (v) => setState(() => payment = v ?? payment),
              decoration: const InputDecoration(labelText: "Payment Method"),
            ),

            const SizedBox(height: 10),

            // date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Date"),
              subtitle: Text("${date.day}/${date.month}/${date.year}"),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime(2035, 12, 31),
                  initialDate: date,
                );
                if (picked != null) setState(() => date = picked);
              },
            ),

            // notes
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: "Notes (optional)"),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: _save,
              child: const Text("Save"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _pill({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
          border: Border.all(color: Colors.black12),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));
      return;
    }

    final tx = TransactionModel(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime(date.year, date.month, date.day),
      type: type,
      category: category,
      amount: amount,
      notes: notesCtrl.text.trim(),
      paymentMethod: payment,
    );

    if (widget.existing == null) {
      await TransactionRepository.add(tx);
    } else {
      await TransactionRepository.update(tx);
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}
