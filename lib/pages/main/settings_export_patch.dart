// ════════════════════════════════════════════════════════════════
// PATCH for lib/pages/main/settings_page.dart
// ════════════════════════════════════════════════════════════════
//
// 1) ADD this import at the top of settings_page.dart:
//    import '../../utils/csv_export.dart';
//
// 2) REPLACE the entire _doExport method with the version below.
// ════════════════════════════════════════════════════════════════

Future<void> _doExport(BuildContext context, String format) async {
  try {
    final txs = await TransactionRepository.fetchAll();
    if (!context.mounted) return;

    if (txs.isEmpty) {
      await showAppFeedbackDialog(
        context,
        title: 'No Data',
        message: 'No transactions to export.',
        type: AppFeedbackType.error,
      );
      return;
    }

    // Ask for optional date range
    final useRange = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export ${format.toUpperCase()}'),
        content: const Text('Export all transactions, or choose a date range.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Export all'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose range'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    List<TransactionModel> toExport = txs;
    if (useRange == true) {
      final now = DateTime.now();
      final start = await showDatePicker(
        context: context,
        initialDate: now.subtract(const Duration(days: 30)),
        firstDate: DateTime(2020),
        lastDate: now,
      );
      if (!context.mounted || start == null) return;
      final end = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: start,
        lastDate: DateTime(2030),
      );
      if (!context.mounted || end == null) return;

      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);
      toExport = txs.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return !d.isBefore(startDay) && !d.isAfter(endDay);
      }).toList();

      if (toExport.isEmpty) {
        if (!context.mounted) return;
        await showAppFeedbackDialog(
          context,
          title: 'No data in range',
          message: 'No transactions fall within the selected date range.',
          type: AppFeedbackType.error,
        );
        return;
      }
    }

    final result = await CsvExport.exportTransactions(toExport);
    if (!context.mounted) return;

    await showAppFeedbackDialog(
      context,
      title: format == 'pdf' ? 'Export Ready' : 'CSV Exported',
      message: format == 'pdf'
          ? result.openedShareSheet
                ? 'Select a PDF-capable app from the share sheet to save as PDF.'
                : 'File exported. Open it in a spreadsheet app and save as PDF.'
          : result.openedShareSheet
          ? 'Choose where to save or share the CSV file.'
          : 'CSV saved successfully.',
      type: AppFeedbackType.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    await showAppFeedbackDialog(
      context,
      title: 'Export Failed',
      message: '$e',
      type: AppFeedbackType.error,
    );
  }
}
