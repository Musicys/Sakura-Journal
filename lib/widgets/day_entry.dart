import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import 'decor.dart';

/// 目录里的一行手记：时间 + 标题 + 摘要（时间轴与日历共用）
class DayEntry extends StatefulWidget {
  const DayEntry({
    super.key,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final Note note;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<DayEntry> createState() => _DayEntryState();
}

class _DayEntryState extends State<DayEntry> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final mood = Palette.moodColors[note.mood.clamp(0, 4)];

    final railColor = widget.selected
        ? Palette.lapis
        : (_hover
              ? Palette.lapis.withValues(alpha: 0.45)
              : Palette.ink.withValues(alpha: 0.10));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: widget.onTap,
        scale: 0.995,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutQuart,
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? Palette.card
                : (_hover
                      ? Palette.card.withValues(alpha: 0.92)
                      : Palette.card.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(2),
            border: Border(left: BorderSide(color: railColor, width: 2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  clockLabel(note.createdAt),
                  style: AppText.label(
                    9,
                    color: Palette.inkGhost,
                    spacing: 0.6,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            note.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              12.5,
                              weight: FontWeight.w600,
                              height: 1.3,
                              spacing: 0.3,
                            ),
                          ),
                        ),
                        if (note.pinned) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.push_pin_outlined,
                            size: 9,
                            color: Palette.lapis.withValues(alpha: 0.7),
                          ),
                        ],
                        if (note.images.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.image_outlined,
                            size: 9,
                            color: Palette.inkGhost,
                          ),
                        ],
                      ],
                    ),
                    if (note.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        note.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          11,
                          color: Palette.inkSoft,
                          height: 1.5,
                          spacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: mood, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
