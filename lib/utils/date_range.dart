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

DateRange thisMonthRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = (now.month == 12)
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  return DateRange(start, end);
}

DateRange lastNDaysRange(int days) {
  assert(days > 0, 'days must be greater than zero');
  final today = todayRange();
  final start = today.start.subtract(Duration(days: days - 1));
  return DateRange(start, today.end);
}

List<DateRange> dailyRanges(int count) {
  assert(count > 0);
  final todayStart = todayRange().start;
  return List.generate(count, (index) {
    final offset = count - 1 - index;
    final start = todayStart.subtract(Duration(days: offset));
    return DateRange(start, start.add(const Duration(days: 1)));
  });
}

List<DateRange> weeklyRanges(int count, {int weekStartsOn = DateTime.monday}) {
  assert(count > 0);
  final currentWeek = thisWeekRange(weekStartsOn: weekStartsOn);
  return List.generate(count, (index) {
    final offsetWeeks = count - 1 - index;
    final start = currentWeek.start.subtract(Duration(days: 7 * offsetWeeks));
    return DateRange(start, start.add(const Duration(days: 7)));
  });
}

List<DateRange> monthlyRanges(int count) {
  assert(count > 0);
  final now = DateTime.now();
  final currentStart = DateTime(now.year, now.month, 1);
  return List.generate(count, (index) {
    final offset = count - 1 - index;
    final start = DateTime(currentStart.year, currentStart.month - offset, 1);
    final end = DateTime(start.year, start.month + 1, 1);
    return DateRange(start, end);
  });
}
