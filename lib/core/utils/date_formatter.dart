import 'package:intl/intl.dart';

/// Formatter for Dates & Times.
abstract final class DateFormatter {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm · dd/MM/yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd/MM');

  /// 19:00
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// 27/10/2026
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  /// 27/10
  static String formatDayMonth(DateTime dateTime) {
    return _dayMonthFormat.format(dateTime.toLocal());
  }

  /// 19:00 · 27/10/2026
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  /// Weekday abbreviation: T2, T3, T4, T5, T6, T7, CN
  static String formatWeekdayAbbr(DateTime dateTime) {
    final local = dateTime.toLocal();
    switch (local.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  /// Weekday full name: Thứ Hai, Thứ Ba...
  static String formatWeekdayFull(DateTime dateTime) {
    final local = dateTime.toLocal();
    switch (local.weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  /// Format countdown timer (minutes:seconds, e.g. 04:32)
  static String formatTimer(Duration remaining) {
    if (remaining.isNegative) {
      return '00:00';
    }
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
