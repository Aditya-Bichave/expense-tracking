import 'package:intl/intl.dart';

List<String> weekdayNamesMonFirst(String locale) {
  final sundayFirst = DateFormat.EEEE(locale).dateSymbols.WEEKDAYS;
  return [...sundayFirst.skip(1), sundayFirst.first];
}
