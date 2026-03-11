import 'package:timeago/timeago.dart' as timeago;

/// English messages with numeric singular forms ("1 day" instead of "a day").
class EnNumericMessages extends timeago.EnMessages {
  @override
  String lessThanOneMinute(int seconds) => '1 minute';

  @override
  String aboutAMinute(int minutes) => '1 minute';

  @override
  String minutes(int minutes) => '$minutes minutes';

  @override
  String aboutAnHour(int minutes) => '1 hour';

  @override
  String hours(int hours) => '$hours hours';

  @override
  String aDay(int hours) => '1 day';

  @override
  String days(int days) => '$days days';

  @override
  String aboutAMonth(int days) => '1 month';

  @override
  String months(int months) => '$months months';

  @override
  String aboutAYear(int year) => '1 year';

  @override
  String years(int years) => '$years years';
}
