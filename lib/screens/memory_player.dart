import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/media_store.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import '../widgets/decor.dart';

/// 打开「回顾播放」：按传入顺序自动翻页
Future<void> showMemoryPlayer(
  BuildContext context, {
  required List<Note> notes,
  int startIndex = 0,
}) {
  if (notes.isEmpty) return Future<void>.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭回顾',
    barrierColor: Palette.ink.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (_, _, _) =>
        MemoryPlayer(notes: notes, startIndex: startIndex),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 日记回顾播放器：一页一页翻过写下的日子
class MemoryPlayer extends StatefulWidget {
  const MemoryPlayer({super.key, required this.notes, this.startIndex = 0});

  final List<Note> notes;
  final int startIndex;

  @override
  State<MemoryPlayer> createState() => _MemoryPlayerState();
}

class _MemoryPlayerState extends State<MemoryPlayer>
    with SingleTickerProviderStateMixin {
  static const _pageDuration = Duration(seconds: 6);

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _pageDuration,
  );

  late int _index = widget.startIndex.clamp(0, widget.notes.length - 1);
  bool _playing = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener(_onStatus);
    _progress.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_index >= widget.notes.length - 1) {
      setState(() {
        _playing = false;
        _finished = true;
      });
    } else {
      _goTo(_index + 1);
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.notes.length) return;
    setState(() {
      _index = index;
      _playing = true;
      _finished = false;
    });
    _progress.forward(from: 0);
  }

  void _toggle() {
    if (_finished) {
      _goTo(0);
      return;
    }
    setState(() => _playing = !_playing);
    if (_playing) {
      _progress.forward();
    } else {
      _progress.stop();
    }
  }

  void _next() {
    if (_index >= widget.notes.length - 1) {
      _progress.stop();
      setState(() {
        _playing = false;
        _finished = true;
      });
      return;
    }
    _goTo(_index + 1);
  }

  void _prev() => _goTo(_index == 0 ? 0 : _index - 1);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.notes[_index];
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width < 700 ? size.width - 36 : 620.0;
    final maxHeight = size.height * 0.7;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _toggle,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _prev,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: PetalRain(count: 6, opacity: 0.2),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _progressBar(),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            switchInCurve: Curves.easeOutQuart,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.035),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _PageCard(
                              key: ValueKey(note.id),
                              note: note,
                              index: _index,
                              total: widget.notes.length,
                              maxHeight: maxHeight,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _controls(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(top: 10, right: 14, child: _closeButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBar() {
    final total = widget.notes.length;
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final fill = i < _index
                      ? 1.0
                      : (i == _index ? _progress.value : 0.0);
                  return SizedBox(
                    height: 2,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Palette.card.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        if (fill > 0)
                          Positioned.fill(
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: fill.clamp(0.0, 1.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Palette.sakura,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _controls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundButton(
              icon: Icons.skip_previous_rounded,
              tooltip: '上一篇',
              onTap: _prev,
            ),
            const SizedBox(width: 16),
            _RoundButton(
              icon: _finished
                  ? Icons.replay_rounded
                  : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              tooltip: _finished ? '再看一遍' : (_playing ? '暂停' : '继续'),
              primary: true,
              onTap: _toggle,
            ),
            const SizedBox(width: 16),
            _RoundButton(
              icon: Icons.skip_next_rounded,
              tooltip: '下一篇',
              onTap: _next,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _finished
              ? '回顾到这里了'
              : '第 ${_index + 1} / ${widget.notes.length} 篇 · 空格暂停 · ← → 翻页',
          style: AppText.label(
            9.5,
            color: Palette.card.withValues(alpha: 0.55),
            spacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _closeButton() {
    return _RoundButton(
      icon: Icons.close_rounded,
      tooltip: '结束回顾',
      onTap: () => Navigator.of(context).maybePop(),
    );
  }
}

class _RoundButton extends StatefulWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.primary ? 48.0 : 34.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        child: PressScale(
          onTap: widget.onTap,
          scale: 0.9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primary
                  ? Palette.sakura.withValues(alpha: _hover ? 1 : 0.92)
                  : (_hover
                        ? Palette.card.withValues(alpha: 0.12)
                        : Colors.transparent),
              border: Border.all(
                color: widget.primary
                    ? Colors.transparent
                    : Palette.card.withValues(alpha: _hover ? 0.6 : 0.3),
                width: 1.1,
              ),
            ),
            child: Icon(
              widget.icon,
              size: widget.primary ? 23 : 15,
              color: widget.primary ? Palette.ink : Palette.card,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    super.key,
    required this.note,
    required this.index,
    required this.total,
    required this.maxHeight,
  });

  final Note note;
  final int index;
  final int total;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final photos = note.images
        .map(MediaStore.provider)
        .whereType<ImageProvider>()
        .take(2)
        .toList();
    final moodIndex = note.mood.clamp(0, Palette.moodColors.length - 1);
    final moodColor = Palette.moodColors[moodIndex];
    final body = note.body.trim();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight, minHeight: 270),
      child: Sheet(
        color: Palette.card,
        padding: EdgeInsets.zero,
        shadow: const Offset(7, 7),
        shadowColor: Palette.ink.withValues(alpha: 0.38),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 28, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    fullDayLabel(note.createdAt),
                    style: AppText.label(
                      9.5,
                      color: Palette.lapis.withValues(alpha: 0.9),
                      spacing: 1.6,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${clockLabel(note.createdAt)}',
                    style: AppText.label(
                      9.5,
                      color: Palette.inkGhost,
                      spacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: moodColor.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      Palette.moodGlyphs[moodIndex],
                      style: AppText.display(
                        11,
                        color: moodColor,
                        weight: FontWeight.w600,
                        spacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                note.displayTitle,
                style: AppText.display(
                  25,
                  weight: FontWeight.w700,
                  spacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const DashedDivider(),
              const SizedBox(height: 16),
              if (photos.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Palette.paper,
                    border: Border.all(
                      color: Palette.ink.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Image(
                    image: photos.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                body.isEmpty ? '（这一页没有留下文字）' : body,
                style: AppText.body(
                  13.5,
                  color: body.isEmpty ? Palette.inkGhost : Palette.ink,
                  height: 2.0,
                  spacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'NO.${index + 1} / $total',
                    style: AppText.label(
                      8.5,
                      color: Palette.inkGhost,
                      spacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  const SakuraGlyph(
                    size: 13,
                    color: Palette.sakuraDeep,
                    stroke: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
