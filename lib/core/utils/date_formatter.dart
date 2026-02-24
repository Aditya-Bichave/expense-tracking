import 'package:intl/intl.dart';

class DateFormatter {
  static final Map<String?, DateFormat> _dateTimeFormatters = {};
  static final Map<String?, DateFormat> _dateFormatters = {};

  static String formatDateTime(DateTime dateTime, {String? locale}) {
    try {
      final format = _getDateTimeFormatter(locale);
      return format.format(dateTime);
    } catch (e) {
      return dateTime.toIso8601String();
    }
  }

  static String formatDate(DateTime dateTime, {String? locale}) {
    try {
      final format = _getDateFormatter(locale);
      return format.format(dateTime);
    } catch (e) {
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    }
  }

  static DateFormat _getDateTimeFormatter(String? locale) {
    var format = _dateTimeFormatters[locale];
    if (format == null) {
      format = DateFormat.yMMMd(locale).add_jm();
      _dateTimeFormatters[locale] = format;
    }
    return format;
  }

  static DateFormat _getDateFormatter(String? locale) {
    var format = _dateFormatters[locale];
    if (format == null) {
      format = DateFormat.yMd(locale);
      _dateFormatters[locale] = format;
    }
    return format;
  }
}
