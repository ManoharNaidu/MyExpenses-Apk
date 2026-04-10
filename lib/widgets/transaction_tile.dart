import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../app/theme.dart';
import '../utils/category_icons.dart';

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
    final txColor = transactionTypeColor(context, tx.type);
    final iconBg = txColor.withValues(alpha: 0.12);
    final amt = (isIncome ? '+' : '-') + tx.amount.toStringAsFixed(2);
    final date = DateFormat('dd MMM yyyy').format(tx.date);
    final notes = (tx.notes ?? tx.description ?? '').trim();
    final shortNotes = notes.length <= 50
        ? notes
        : '${notes.substring(0, 50)}...';

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
                backgroundColor: iconBg,
                child: Icon(categoryIconFor(tx.category), color: txColor),
              ),
        title: Text(
          tx.category,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          '$date • ${tx.type == TxType.income ? "Income" : "Expense"}${shortNotes.isNotEmpty ? " • $shortNotes" : ""}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          amt,
          style: TextStyle(fontWeight: FontWeight.w900, color: txColor),
        ),
        onTap: onEdit,
      ),
    );
  }
}
