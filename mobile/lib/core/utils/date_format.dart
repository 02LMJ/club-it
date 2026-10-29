/// 날짜 표시 형식
/// - 오늘: 14:05
/// - 올해: 10.28
/// - 그 외: 2025.12.03
String formatShortDate(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');

  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return '${two(date.hour)}:${two(date.minute)}';
  }
  if (date.year == today.year) return '${two(date.month)}.${two(date.day)}';
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}
