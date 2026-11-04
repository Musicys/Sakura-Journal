/// 手账式日期写法：今天 / 昨天 / 具体日期
String journalDate(DateTime time, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final day = DateTime(time.year, time.month, time.day);
  final diff = today.difference(day).inDays;

  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');

  if (diff == 0) return '今日 $hh:$mm';
  if (diff == 1) return '昨日 $hh:$mm';
  if (diff < 7) return '$diff 日前';
  if (time.year == ref.year) return '${time.month}月${time.day}日';
  return '${time.year}.${time.month}.${time.day}';
}

/// 首页抬头用：11月3日 · 星期二
String headerDate(DateTime date) {
  return '${date.month}月${date.day}日 · ${weekdayLabel(date)}';
}

const _weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

/// 星期二
String weekdayLabel(DateTime date) {
  final w = _weekdayNames[(date.weekday - 1).clamp(0, 6)];
  return '星期$w';
}

/// 时间轴分组键：2026-11-03
String dayKey(DateTime time) {
  final m = time.month.toString().padLeft(2, '0');
  final d = time.day.toString().padLeft(2, '0');
  return '${time.year}-$m-$d';
}

/// 11月3日
String dayLabel(DateTime time) => '${time.month}月${time.day}日';

/// 14:05
String clockLabel(DateTime time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// 2026年11月3日 · 星期二
String fullDayLabel(DateTime time) {
  return '${time.year}年${time.month}月${time.day}日 · ${weekdayLabel(time)}';
}
