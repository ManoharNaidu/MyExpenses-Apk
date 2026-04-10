import '../core/storage/secure_storage.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../core/notifications/notification_service.dart';

class DigestContent {
  final String title;
  final String body;

  const DigestContent({required this.title, required this.body});
}

class WeeklyDigestService {
  static const _enabledKey = 'digest_enabled';
  static const _dayKey = 'digest_day';
  static const _hourKey = 'digest_hour';
  static const _minuteKey = 'digest_minute';

  static Future<void> initialize() async {
    final enabled = await isEnabled();
    if (!enabled) return;
    await _scheduleNext();
  }

  static Future<bool> isEnabled() async {
    final v = await SecureStorage.readString(_enabledKey);
    return v != 'false';
  }

  static Future<void> setEnabled(bool value) async {
    await SecureStorage.writeString(_enabledKey, value ? 'true' : 'false');
    if (value) {
      await _scheduleNext();
    } else {
      await _cancelAll();
    }
  }

  static Future<void> _scheduleNext() async {
    final dayPref =
        int.tryParse(await SecureStorage.readString(_dayKey) ?? '0') ?? 0;
    final hour =
        int.tryParse(await SecureStorage.readString(_hourKey) ?? '18') ?? 18;
    final minute =
        int.tryParse(await SecureStorage.readString(_minuteKey) ?? '0') ?? 0;

    final now = DateTime.now();
    final next = _nextWeekday(now, dayPref, hour, minute);
    final content = await buildContent();

    await NotificationService.scheduleWeekly(
      id: 9001,
      title: content.title,
      body: content.body,
      scheduledDate: next,
    );
  }

  static Future<DigestContent> buildContent() async {
    final txs = TransactionRepository.currentTransactions;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekTxs = txs.where((t) => t.date.isAfter(weekAgo)).toList();

    if (weekTxs.isEmpty) {
      return const DigestContent(
        title: 'Quiet week - any transactions to add?',
        body:
            'No transactions recorded this week. Tap to add some or upload your bank statement.',
      );
    }

    final weekExpense = _sumByType(weekTxs, TxType.expense);
    final weekIncome = _sumByType(weekTxs, TxType.income);
    final net = weekIncome - weekExpense;

    if (net >= 0) {
      return DigestContent(
        title: 'Great week - you are net positive',
        body:
            'Income ${weekIncome.toStringAsFixed(0)}, expense ${weekExpense.toStringAsFixed(0)}. Keep it up.',
      );
    }

    return DigestContent(
      title: 'Weekly digest: watch your spending',
      body:
          'Income ${weekIncome.toStringAsFixed(0)}, expense ${weekExpense.toStringAsFixed(0)}. Review top categories in Analytics.',
    );
  }

  static double _sumByType(List<TransactionModel> txs, TxType type) {
    return txs
        .where((t) => t.type == type)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  static DateTime _nextWeekday(
    DateTime from,
    int weekday,
    int hour,
    int minute,
  ) {
    var d = DateTime(from.year, from.month, from.day, hour, minute);
    while (d.weekday % 7 != weekday || d.isBefore(from)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static Future<void> _cancelAll() async {
    await NotificationService.cancel(9001);
  }
}
