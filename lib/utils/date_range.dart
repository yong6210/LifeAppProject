class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);
}

DateRange todayRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return DateRange(start, end);
}

DateRange thisWeekRange({int weekStartsOn = DateTime.monday}) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final diff = (startOfDay.weekday - weekStartsOn + 7) % 7;
  final start = startOfDay.subtract(Duration(days: diff));
  final end = start.add(const Duration(days: 7));
  return DateRange(start, end);
}
