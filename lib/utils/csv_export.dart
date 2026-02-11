import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import '../models/transaction_model.dart';
import 'date_utils.dart';

class CsvExport {
  static Future<void> exportTransactions(List<TransactionModel> txs) async {
    // 1. Prepare Data
    final header = [
      'Date',
      'Month',
      'Week',
      'Type',
      'Category',
      'Amount',
      'Description',
    ];

    final rows = txs.map(
      (t) => [
        DateUtilsX.yyyyMmDd(t.date),
        DateUtilsX.monthLabel(t.date),
        DateUtilsX.weekLabel(t.date),
        t.type == TxType.income ? 'Income' : 'Expense',
        t.category,
        t.amount.toStringAsFixed(2),
        t.description,
      ],
    );

    // 2. Build CSV String
    final csv = StringBuffer()..writeln(header.join(','));
    for (final r in rows) {
      csv.writeln(r.map(_escape).join(','));
    }

    final bytes = utf8.encode(csv.toString());
    final String fileName =
        'transactions_${DateTime.now().millisecondsSinceEpoch}';

    // Cross-platform save (web + mobile + desktop)
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static String _escape(String? v) {
    final val = v ?? '';
    final needs = val.contains(',') || val.contains('"') || val.contains('\n');
    if (!needs) return val;
    return '"${val.replaceAll('"', '""')}"';
  }
}
