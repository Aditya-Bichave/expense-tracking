import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd hh:mm a')
        .format(dateTime); // Customize format
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
