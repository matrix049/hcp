/// Compact `yyyy-MM-dd HH:mm` formatting for lists (no intl locale needed here).
String formatShortDateTime(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');
