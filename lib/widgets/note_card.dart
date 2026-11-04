import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import 'decor.dart';

/// 便签卡片：微倾斜、墨线描边、hover 抬起
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.selected,
    required this.index,
    required this.onOpen,
    required this.onTogglePin,
    required this.onDelete,
  });

  final Note note;
  final bool selected;
  final int index;
  final ValueChanged<Note> onOpen;
  final ValueChanged<Note> onTogglePin;
  final ValueChanged<Note> onDelete;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _hover = false;

  late final double _tilt = () {
    final seed = widget.note.id.hashCode % 100;
    return (seed / 100 - 0.5) * 0.024;
  }();

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final paper =
        Palette.notePapers[note.paper.clamp(0, Palette.notePapers.length - 1)];
    final moodColor =
        Palette.moodColors[note.mood.clamp(0, Palette.moodColors.length - 1)];
    final active = widget.selected;
    final lifted = _hover || active;

    final body = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: () => widget.onOpen(note),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutQuart,
          transform: Matrix4.identity()
            ..rotateZ(lifted ? 0 : _tilt)
            ..setTranslationRaw(0, lifted ? -3.0 : 0.0, 0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: active
                  ? Palette.lapis.withValues(alpha: 0.75)
                  : Palette.hairline,
              width: active ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (active ? Palette.lapis : Palette.ink).withValues(
                  alpha: active ? 0.16 : (lifted ? 0.14 : 0.085),
                ),
                offset: Offset(lifted ? 4 : 3, lifted ? 4 : 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _MoodStamp(
                          glyph: Palette.moodGlyphs[note.mood.clamp(0, 4)],
                          color: moodColor,
                        ),
                        if (note.pinned) ...[
                          const SizedBox(width: 8),
                          Transform.rotate(
                            angle: math.pi / 4,
                            child: Icon(
                              Icons.push_pin,
                              size: 12,
                              color: Palette.lapis.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          journalDate(note.updatedAt),
                          style: AppText.label(
                            10.5,
                            color: Palette.inkGhost,
                            spacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(
                        18.5,
                        color: Palette.ink,
                        weight: FontWeight.w600,
                        height: 1.35,
                        spacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      note.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        13,
                        color: Palette.inkSoft,
                        height: 1.75,
                        spacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (note.images.isNotEmpty) ...[
                          Icon(
                            Icons.image_outlined,
                            size: 11,
                            color: Palette.inkGhost.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${note.images.length}',
                            style: AppText.label(
                              10,
                              color: Palette.inkGhost,
                              spacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          '${note.charCount} 字',
                          style: AppText.label(
                            10,
                            color: Palette.inkGhost,
                            spacing: 1.4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 14,
                          height: 1,
                          color: Palette.ink.withValues(alpha: 0.12),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Palette.paperNames[note.paper.clamp(0, 5)],
                          style: AppText.label(
                            10,
                            color: Palette.inkGhost,
                            spacing: 1.4,
                          ),
                        ),
                        const Spacer(),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _hover ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !_hover,
                            child: Row(
                              children: [
                                _MiniAction(
                                  icon: note.pinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  color: Palette.lapis,
                                  onTap: () => widget.onTogglePin(note),
                                ),
                                const SizedBox(width: 4),
                                _MiniAction(
                                  icon: Icons.delete_outline,
                                  color: Palette.seal,
                                  onTap: () => widget.onDelete(note),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _hover ? 0 : 1,
                          child: Icon(
                            note.favorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 12,
                            color: note.favorite
                                ? Palette.sakuraDeep
                                : Palette.inkGhost.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (note.pinned)
                Positioned(
                  top: -12,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: WashiTape(
                        width: 58,
                        height: 17,
                        color: Palette.sakura,
                        angle: -0.05,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return StaggerIn(index: widget.index, child: body);
  }
}

class _MoodStamp extends StatelessWidget {
  const _MoodStamp({required this.glyph, required this.color});

  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        glyph,
        style: AppText.display(
          11.5,
          color: color,
          weight: FontWeight.w600,
          height: 1.35,
          spacing: 0,
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 12, color: color.withValues(alpha: 0.9)),
      ),
    );
  }
}

/// 入场：淡入 + 轻微上浮，按序号错峰
class StaggerIn extends StatelessWidget {
  const StaggerIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delayMs = math.min(index, 8) * 45.0;
    final total = 430.0 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total.round()),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutQuart),
      builder: (context, t, child) {
        final eased = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
