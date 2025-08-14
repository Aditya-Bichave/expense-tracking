import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime dateTime) {
    try {
      // Example format: Jan 5, 2024 03:45 PM
      return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTime.toIso8601String(); // Fallback
    }
  }

  static String formatDate(DateTime dateTime) {
    try {
      // Example format: 2024-01-05
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}"; // Fallback
    }
  }
}
