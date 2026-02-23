import 'package:intl/intl.dart';

class DateFormatter {
  static final Map<String?, DateFormat> _dateTimeFormatters = {};
  static final Map<String?, DateFormat> _dateFormatters = {};
  static final Map<String?, DateFormat> _monthYearFormatters = {};

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

  static String formatMonthYear(DateTime dateTime, {String? locale}) {
    try {
      final format = _getMonthYearFormatter(locale);
      return format.format(dateTime);
    } catch (e) {
      return "${dateTime.month}/${dateTime.year}";
    }
  }

  static DateFormat _getDateTimeFormatter(String? locale) {
    if (!_dateTimeFormatters.containsKey(locale)) {
      _dateTimeFormatters[locale] = DateFormat.yMMMd(locale).add_jm();
    }
    return _dateTimeFormatters[locale]!;
  }

  static DateFormat _getDateFormatter(String? locale) {
    if (!_dateFormatters.containsKey(locale)) {
      _dateFormatters[locale] = DateFormat.yMd(locale);
    }
    return _dateFormatters[locale]!;
  }

  static DateFormat _getMonthYearFormatter(String? locale) {
    if (!_monthYearFormatters.containsKey(locale)) {
      _monthYearFormatters[locale] = DateFormat.yMMM(locale);
    }
    return _monthYearFormatters[locale]!;
  }
}
