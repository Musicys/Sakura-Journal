import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import '../widgets/day_entry.dart';
import '../widgets/decor.dart';

/// 日历表：一月一表，点一天看那天写了什么
class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    required this.notes,
    required this.selectedId,
    required this.onOpen,
    required this.onPlayDay,
  });

  final List<Note> notes;
  final String? selectedId;
  final ValueChanged<Note> onOpen;
  final ValueChanged<List<Note>> onPlayDay;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final focus = _latestStamp() ?? DateTime.now();
    _month = DateTime(focus.year, focus.month);
    _selected = DateTime(focus.year, focus.month, focus.day);
  }

  DateTime? _latestStamp() {
    if (widget.notes.isEmpty) return null;
    var latest = widget.notes.first.createdAt;
    for (final note in widget.notes) {
      if (note.createdAt.isAfter(latest)) latest = note.createdAt;
    }
    return latest;
  }

  Map<String, List<Note>> _byDay() {
    final map = <String, List<Note>>{};
    for (final note in widget.notes) {
      map.putIfAbsent(dayKey(note.createdAt), () => <Note>[]).add(note);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return map;
  }

  void _shift(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final byDay = _byDay();
    final days = DateTime(next.year, next.month + 1, 0).day;

    DateTime? pick;
    for (var d = 1; d <= days; d++) {
      final date = DateTime(next.year, next.month, d);
      if ((byDay[dayKey(date)] ?? const <Note>[]).isNotEmpty) {
        pick = date;
        break;
      }
    }

    setState(() {
      _month = next;
      _selected = pick ?? DateTime(next.year, next.month, 1);
    });
  }

  void _backToToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _byDay();
    final dayNotes = byDay[dayKey(_selected)] ?? const <Note>[];

    return Column(
      children: [
        _monthHeader(),
        _weekdayHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          child: _monthGrid(byDay),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: const DashedDivider(),
        ),
        Expanded(child: _dayPanel(dayNotes)),
      ],
    );
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          InkButton(
            icon: Icons.chevron_left_rounded,
            tooltip: '上个月',
            size: 24,
            onPressed: () => _shift(-1),
          ),
          const SizedBox(width: 2),
          Text(
            '${_month.year} 年 ${_month.month} 月',
            style: AppText.display(15, weight: FontWeight.w700, spacing: 1),
          ),
          const SizedBox(width: 2),
          InkButton(
            icon: Icons.chevron_right_rounded,
            tooltip: '下个月',
            size: 24,
            onPressed: () => _shift(1),
          ),
          const Spacer(),
          InkButton(
            icon: Icons.today_outlined,
            tooltip: '回到今天',
            size: 24,
            onPressed: _backToToday,
          ),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  names[i],
                  style: AppText.label(
                    9,
                    color: i >= 5
                        ? Palette.sakuraDeep.withValues(alpha: 0.7)
                        : Palette.inkGhost,
                    spacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _monthGrid(Map<String, List<Note>> byDay) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final total = ((leading + days) / 7).ceil() * 7;
    final todayKey = dayKey(DateTime.now());
    final selectedKey = dayKey(_selected);

    final cells = <Widget>[];
    for (var i = 0; i < total; i++) {
      final dayNumber = i - leading + 1;
      if (dayNumber < 1 || dayNumber > days) {
        cells.add(const Expanded(child: SizedBox(height: 38)));
        continue;
      }

      final date = DateTime(_month.year, _month.month, dayNumber);
      final key = dayKey(date);
      cells.add(
        Expanded(
          child: _DayCell(
            date: date,
            count: byDay[key]?.length ?? 0,
            isToday: key == todayKey,
            isSelected: key == selectedKey,
            onTap: () => setState(() => _selected = date),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var row = 0; row < total ~/ 7; row++)
          Row(children: cells.sublist(row * 7, row * 7 + 7)),
      ],
    );
  }

  Widget _dayPanel(List<Note> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${dayLabel(_selected)} · ${weekdayLabel(_selected)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    11.5,
                    weight: FontWeight.w600,
                    height: 1.4,
                    spacing: 0.3,
                  ),
                ),
              ),
              if (notes.isNotEmpty) ...[
                Text(
                  '${notes.length} 篇',
                  style: AppText.label(9, color: Palette.inkGhost, spacing: 1),
                ),
                const SizedBox(width: 6),
                InkButton(
                  icon: Icons.play_arrow_rounded,
                  tooltip: '播放这一天',
                  size: 24,
                  onPressed: () => widget.onPlayDay(notes),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? _emptyHint()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 2, 12, 24),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return DayEntry(
                      key: ValueKey('calendar-${note.id}'),
                      note: note,
                      selected: note.id == widget.selectedId,
                      onTap: () => widget.onOpen(note),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SakuraGlyph(
              size: 24,
              color: Palette.inkGhost.withValues(alpha: 0.55),
              stroke: 1,
            ),
            const SizedBox(height: 8),
            Text(
              '这一天还空着',
              style: AppText.label(9.5, color: Palette.inkGhost, spacing: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.date,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasNotes = widget.count > 0;
    final selected = widget.isSelected;

    final Color background;
    if (selected) {
      background = Palette.lapis;
    } else if (_hover) {
      background = Palette.lapis.withValues(alpha: 0.08);
    } else if (hasNotes) {
      background = Palette.lapisMist.withValues(alpha: 0.65);
    } else {
      background = Colors.transparent;
    }

    final Color textColor;
    if (selected) {
      textColor = Palette.card;
    } else if (hasNotes) {
      textColor = Palette.ink;
    } else {
      textColor = Palette.inkGhost.withValues(alpha: 0.7);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: widget.onTap,
        scale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutQuart,
          height: 36,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: widget.isToday
                  ? Palette.sakuraDeep.withValues(alpha: selected ? 0 : 0.65)
                  : Colors.transparent,
              width: 1.1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.date.day}',
                style: AppText.body(
                  11,
                  color: textColor,
                  weight: hasNotes || selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  height: 1.1,
                  spacing: 0.4,
                ),
              ),
              if (hasNotes) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.count.clamp(1, 3); i++)
                      Container(
                        width: 2.6,
                        height: 2.6,
                        margin: const EdgeInsets.symmetric(horizontal: 0.9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? Palette.card.withValues(alpha: 0.85)
                              : Palette.lapis.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ] else
                const SizedBox(height: 5.6),
            ],
          ),
        ),
      ),
    );
  }
}
