/// Utilitas format dan parsing tanggal untuk aplikasi Dr4oxBill.
library date_utils;

import 'package:intl/intl.dart';

/// Format tampilan tanggal Indonesia: "dd MMMM yyyy", misal "23 Oktober 2026".
String formatDisplayDate(DateTime date) {
  return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
}

/// Format tampilan tanggal singkat: "dd/MM/yyyy", misal "23/10/2026".
String formatShortDate(DateTime date) {
  return DateFormat('dd/MM/yyyy', 'id_ID').format(date);
}

/// Format tampilan waktu: "HH:mm", misal "14:30".
String formatTime(DateTime date) {
  return DateFormat('HH:mm', 'id_ID').format(date);
}

/// Format tanggal dan waktu lengkap: "dd/MM/yyyy HH:mm".
String formatDateTime(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(date);
}

/// Format untuk disimpan di database: ISO 8601 "yyyy-MM-ddTHH:mm:ss".
String formatDbDateTime(DateTime date) {
  return date.toIso8601String();
}

/// Parse string ISO 8601 dari database menjadi DateTime.
DateTime parseDbDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) {
    return DateTime.now();
  }
  try {
    return DateTime.parse(isoString);
  } catch (e) {
    return DateTime.now();
  }
}

/// Mendapatkan awal hari (00:00:00.000) untuk tanggal tertentu.
DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Mendapatkan akhir hari (23:59:59.999) untuk tanggal tertentu.
DateTime endOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

/// Apakah dua tanggal berada pada hari yang sama.
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Mendapatkan rentang tanggal hari ini.
DateTimeRange todayRange() {
  final now = DateTime.now();
  return DateTimeRange(start: startOfDay(now), end: endOfDay(now));
}

/// Representasi rentang tanggal.
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
