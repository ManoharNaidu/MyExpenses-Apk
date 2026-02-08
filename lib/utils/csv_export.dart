import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

    // 3. Platform Specific Logic
    if (kIsWeb) {
      // WEB: Standard browser download
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
    } else {
      // ANDROID/APK: Save to temp storage and trigger Share Sheet
      try {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/$fileName.csv').create();
        await file.writeAsBytes(bytes);

        // This allows the user to save to "Downloads", send to Email, or Drive
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Exported Transactions CSV',
          subject: 'Transactions Export',
        );
      } catch (e) {
   
      }
    }
  }

  static String _escape(String? v) {
    final val = v ?? '';
    final needs = val.contains(',') || val.contains('"') || val.contains('\n');
    if (!needs) return val;
    return '"${val.replaceAll('"', '""')}"';
  }
}
