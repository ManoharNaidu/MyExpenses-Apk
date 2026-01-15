import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import '../models/transaction_model.dart';
import 'date_utils.dart';

class CsvExport {
  static Future<void> exportTransactions(List<TransactionModel> txs) async {
    final header = ['Date','Month','Week','Type','Category','Amount','PaymentMethod','Notes'];
    final rows = txs.map((t) => [
      DateUtilsX.yyyyMmDd(t.date),
      DateUtilsX.monthLabel(t.date),
      DateUtilsX.weekLabel(t.date),
      t.type == TxType.income ? 'Income' : 'Expense',
      t.category,
      t.amount.toStringAsFixed(2),
      t.paymentMethod,
      t.notes,
    ]);

    final csv = StringBuffer()
      ..writeln(header.join(','));
    for (final r in rows) {
      csv.writeln(r.map(_escape).join(','));
    }

    final bytes = utf8.encode(csv.toString());
    await FileSaver.instance.saveFile(
      name: 'transactions',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static String _escape(String v) {
    final needs = v.contains(',') || v.contains('"') || v.contains('\n');
    if (!needs) return v;
    return '"${v.replaceAll('"', '""')}"';
  }
}
