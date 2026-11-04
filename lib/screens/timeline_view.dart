import 'package:flutter/material.dart';

import '../data/note_store.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import '../widgets/day_entry.dart';
import '../widgets/decor.dart';

/// 日记目录：按日期排布的时间轴
class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.groups,
    required this.selectedId,
    required this.onOpen,
    required this.onPlayDay,
    required this.onPlayAll,
  });

  final List<DayGroup> groups;
  final String? selectedId;
  final ValueChanged<Note> onOpen;
  final ValueChanged<DayGroup> onPlayDay;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    final total = groups.fold<int>(0, (sum, group) => sum + group.count);

    return Column(
      children: [
        _PlayAllBar(total: total, days: groups.length, onTap: onPlayAll),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 18, 30),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _DayBlock(
                group: group,
                first: index == 0,
                last: index == groups.length - 1,
                selectedId: selectedId,
                onOpen: onOpen,
                onPlayDay: onPlayDay,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 时间轴顶部的回顾入口
class _PlayAllBar extends StatefulWidget {
  const _PlayAllBar({
    required this.total,
    required this.days,
    required this.onTap,
  });

  final int total;
  final int days;
  final VoidCallback onTap;

  @override
  State<_PlayAllBar> createState() => _PlayAllBarState();
}

class _PlayAllBarState extends State<_PlayAllBar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 18, 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: PressScale(
          onTap: widget.onTap,
          scale: 0.99,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: Palette.lapisMist.withValues(alpha: _hover ? 0.85 : 0.5),
              border: const Border(
                left: BorderSide(color: Palette.lapis, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 15,
                  color: Palette.lapis.withValues(alpha: _hover ? 1 : 0.8),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '回顾 ${widget.total} 篇 · 跨 ${widget.days} 天',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      10,
                      color: Palette.lapis,
                      spacing: 1.2,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '自动翻页',
                  style: AppText.label(
                    9,
                    color: Palette.inkGhost,
                    spacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.group,
    required this.first,
    required this.last,
    required this.selectedId,
    required this.onOpen,
    required this.onPlayDay,
  });

  final DayGroup group;
  final bool first;
  final bool last;
  final String? selectedId;
  final ValueChanged<Note> onOpen;
  final ValueChanged<DayGroup> onPlayDay;

  @override
  Widget build(BuildContext context) {
    final isToday = dayKey(DateTime.now()) == dayKey(group.day);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: CustomPaint(
              painter: _RailPainter(
                first: first,
                last: last,
                highlight: isToday,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: first ? 2 : 5,
                bottom: last ? 22 : 26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(isToday),
                  const SizedBox(height: 10),
                  for (final note in group.notes)
                    DayEntry(
                      key: ValueKey('timeline-${note.id}'),
                      note: note,
                      selected: note.id == selectedId,
                      onTap: () => onOpen(note),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool isToday) {
    return Row(
      children: [
        Text(
          dayLabel(group.day),
          style: AppText.display(18, weight: FontWeight.w700, spacing: 1.2),
        ),
        const SizedBox(width: 9),
        Text(
          weekdayLabel(group.day),
          style: AppText.label(9.5, color: Palette.inkSoft, spacing: 1.4),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isToday ? '· 今天 · ${group.count} 篇' : '· ${group.count} 篇',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(9.5, color: Palette.inkGhost, spacing: 1.2),
          ),
        ),
        if (group.count > 1) _PlayDayButton(onTap: () => onPlayDay(group)),
      ],
    );
  }
}

class _PlayDayButton extends StatefulWidget {
  const _PlayDayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PlayDayButton> createState() => _PlayDayButtonState();
}

class _PlayDayButtonState extends State<_PlayDayButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: widget.onTap,
        scale: 0.88,
        child: Tooltip(
          message: '播放这一天',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: _hover
                  ? Palette.lapis.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: Border.all(
                color: Palette.lapis.withValues(alpha: _hover ? 0.5 : 0.22),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 11,
              color: Palette.lapis.withValues(alpha: _hover ? 1 : 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.first,
    required this.last,
    required this.highlight,
  });

  final bool first;
  final bool last;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    const x = 13.0;
    const dotY = 14.0;

    final line = Paint()
      ..color = Palette.ink.withValues(alpha: 0.13)
      ..strokeWidth = 1;

    if (!first) {
      canvas.drawLine(Offset(x, 0), Offset(x, dotY - 6), line);
    }
    if (!last) {
      canvas.drawLine(Offset(x, dotY + 6), Offset(x, size.height), line);
    }

    final accent = highlight ? Palette.sakuraDeep : Palette.lapis;
    canvas.drawCircle(
      const Offset(x, dotY),
      6.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.26),
    );
    canvas.drawCircle(const Offset(x, dotY), 3.2, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.first != first || old.last != last || old.highlight != highlight;
}
