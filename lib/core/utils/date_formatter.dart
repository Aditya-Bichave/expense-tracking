import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime dateTime, {String? locale}) {
    try {
      final format = DateFormat.yMMMd(locale).add_jm();
      return format.format(dateTime);
    } catch (e) {
      return dateTime.toIso8601String();
    }
  }

  static String formatDate(DateTime dateTime, {String? locale}) {
    try {
      return DateFormat.yMd(locale).format(dateTime);
    } catch (e) {
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    }
  }
}
