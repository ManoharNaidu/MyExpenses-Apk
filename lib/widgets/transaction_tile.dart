import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../app/theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool showDeleteOnLeft;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onDelete,
    required this.onEdit,
    this.showDeleteOnLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TxType.income;
    final amt = (isIncome ? '+' : '-') + tx.amount.toStringAsFixed(2);
    final date = DateFormat('dd MMM yyyy').format(tx.date);
    final notes = (tx.notes ?? tx.description ?? '').trim();

    return Card(
      child: ListTile(
        leading: showDeleteOnLeft
            ? IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: onDelete,
              )
            : CircleAvatar(
                backgroundColor: (isIncome
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFFBC4749))
                    .withValues(alpha: 0.12),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIncome
                      ? const Color(0xFF2D6A4F)
                      : const Color(0xFFBC4749),
                ),
              ),
        title: Text(
          tx.category,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.coffeeDark,
          ),
        ),
        subtitle: Text(
          '$date • ${tx.type == TxType.income ? "Income" : "Expense"}${notes.isNotEmpty ? " • $notes" : ""}',
        ),
        trailing: Text(
          amt,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isIncome
                ? const Color(0xFF2D6A4F)
                : const Color(0xFFBC4749),
          ),
        ),
        onTap: onEdit,
      ),
    );
  }
}
