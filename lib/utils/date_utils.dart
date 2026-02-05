import 'package:intl/intl.dart';

class DateUtilsX {
  static String monthLabel(DateTime d) => DateFormat('MMM').format(d);

  // Week label like "2-8" (your Excel logic is Wed-Tue-ish; for app we use Mon-Sun by default)
  static DateTime weekStartMonday(DateTime d) {
    final diff = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  static DateTime weekEndSunday(DateTime d) {
    final start = weekStartMonday(d);
    return start.add(const Duration(days: 6));
  }

  static String weekLabel(DateTime d) {
    final s = weekStartMonday(d);
    final e = weekEndSunday(d);
    return '${s.day}-${e.day}';
  }

  static String yyyyMm(DateTime d) => DateFormat('yyyy-MM').format(d);
  static String yyyyMmDd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
