import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../app/theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TxType.income;
    final amt = (isIncome ? '+' : '-') + tx.amount.toStringAsFixed(2);
    final date = DateFormat('dd MMM yyyy').format(tx.date);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isIncome ? Colors.green : Colors.red).withOpacity(
            0.12,
          ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          tx.category,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          '$date • ${tx.type == TxType.income ? "Income" : "Expense"}${(tx.description ?? '').isNotEmpty ? " • ${tx.description}" : ""}',
        ),
        trailing: Text(
          amt,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        onTap: onEdit,
        onLongPress: onDelete,
      ),
    );
  }
}
