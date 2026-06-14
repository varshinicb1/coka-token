import 'package:flutter_test/flutter_test.dart';
import 'package:coka_billing/utils/date_utils.dart' as du;

void main() {
  group('DateUtils', () {
    test('getTodayDateString returns yyyy-MM-dd format', () {
      final today = du.DateUtils.getTodayDateString();
      expect(today, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('formatDate returns formatted date', () {
      expect(du.DateUtils.formatDate('2025-06-14'), '14 Jun 2025');
    });

    test('formatDate returns input on invalid date', () {
      expect(du.DateUtils.formatDate('not-a-date'), 'not-a-date');
    });

    test('formatTime returns hh:mm am/pm format', () {
      final dt = DateTime(2025, 6, 14, 14, 30);
      final formatted = du.DateUtils.formatTime(dt.millisecondsSinceEpoch);
      expect(formatted, contains('02:30'));
    });

    test('formatTime handles midnight', () {
      final dt = DateTime(2025, 6, 14, 0, 5);
      final formatted = du.DateUtils.formatTime(dt.millisecondsSinceEpoch);
      expect(formatted, contains('12:05'));
    });
  });
}
