import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final _log = Logger('DateUtils');

class DateUtils {
  static String getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e, st) {
      _log.fine('Failed to parse date: $dateString', e, st);
      return dateString;
    }
  }

  static String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }
}
