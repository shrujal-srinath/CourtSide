// Shared time / date helpers used across screens.

class TimeUtils {
  TimeUtils._();

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  /// Parses a booking date string ("Today", "Yesterday", "2 days ago", "14 Apr")
  /// combined with a time-slot string ("7:00 PM - 7:45 PM") into a DateTime.
  /// Returns null if parsing fails.
  static DateTime? parseBookingTime(String dateStr, String timeSlot) {
    try {
      final now = DateTime.now();
      String cleanDate = dateStr.trim();

      if (cleanDate.toLowerCase() == 'today') {
        cleanDate = '${now.day} ${_months[now.month - 1]}';
      } else if (cleanDate.toLowerCase() == 'yesterday') {
        final yest = now.subtract(const Duration(days: 1));
        cleanDate = '${yest.day} ${_months[yest.month - 1]}';
      } else if (cleanDate.toLowerCase().contains('ago')) {
        final days = int.parse(cleanDate.split(' ')[0]);
        final ago = now.subtract(Duration(days: days));
        cleanDate = '${ago.day} ${_months[ago.month - 1]}';
      }

      final dateParts = cleanDate.split(' ');
      if (dateParts.length < 2) return null;

      final day = int.parse(dateParts[0]);
      final month = _months.indexWhere((m) => dateParts[1].startsWith(m)) + 1;
      if (month == 0) return null;

      final timeParts = timeSlot.split(' - ');
      final startPart = timeParts[0].trim();
      final parts = startPart.split(' ');
      if (parts.length < 2) return null;

      final hhmm = parts[0].split(':');
      int h = int.parse(hhmm[0]);
      final m = hhmm.length > 1 ? int.parse(hhmm[1]) : 0;
      if (parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
      if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;

      return DateTime(now.year, month, day, h, m);
    } catch (_) {
      return null;
    }
  }

  /// Formats a DateTime into a human-readable date label.
  /// "Today", "Tomorrow", "14 Apr", etc.
  static String formatBookingDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${(-diff)} days ago';
    return '${d.day} ${_months[d.month - 1]}';
  }

  /// Converts a Postgres time string "09:00:00" → "9:00 AM"
  static String formatPgTime(String pgTime) {
    final parts = pgTime.split(':');
    if (parts.length < 2) return pgTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:$m $period';
  }
}
