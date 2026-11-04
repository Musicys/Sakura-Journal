import 'package:flutter/material.dart';

import '../data/note_store.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import '../widgets/decor.dart';
import '../widgets/note_card.dart';
import 'calendar_view.dart';
import 'memory_player.dart';
import 'timeline_view.dart';

enum _Filter { all, pinned, favorite }

/// 列表的三种翻法：便签卡片 / 日期列表 / 日历表
enum ViewMode { cards, timeline, calendar }

class NoteListPanel extends StatefulWidget {
  const NoteListPanel({
    super.key,
    required this.selectedId,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onOpen,
    required this.onCreate,
    required this.onDelete,
  });

  final String? selectedId;
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final ValueChanged<Note> onOpen;
  final VoidCallback onCreate;
  final ValueChanged<Note> onDelete;

  @override
  State<NoteListPanel> createState() => _NoteListPanelState();
}

class _NoteListPanelState extends State<NoteListPanel> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _playAll(List<Note> notes) {
    if (notes.isEmpty) return;
    showMemoryPlayer(context, notes: chronologicalNotes(notes));
  }

  void _playDay(DayGroup group) {
    if (group.count == 0) return;
    showMemoryPlayer(context, notes: chronologicalNotes(group.notes));
  }

  List<Note> _visible(List<Note> source) {
    final q = _query.trim().toLowerCase();
    return source.where((n) {
      final matchFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.pinned => n.pinned,
        _Filter.favorite => n.favorite,
      };
      if (!matchFilter) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);
    final all = store.notes;
    final visible = _visible(all);
    final searching = _query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(store),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: _searchField(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FilterChip(
                        label: '全部',
                        count: all.length,
                        active: _filter == _Filter.all,
                        onTap: () => setState(() => _filter = _Filter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '置顶',
                        count: store.pinnedCount,
                        active: _filter == _Filter.pinned,
                        onTap: () => setState(() => _filter = _Filter.pinned),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '收藏',
                        count: store.favorites,
                        active: _filter == _Filter.favorite,
                        onTap: () => setState(() => _filter = _Filter.favorite),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _viewSwitch(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(child: _content(visible, searching, store)),
      ],
    );
  }

  Widget _content(List<Note> visible, bool searching, NoteStore store) {
    if (visible.isEmpty) {
      return searching || _filter != _Filter.all
          ? _NoResult(query: _query, onClear: _clear)
          : _EmptyState(onCreate: widget.onCreate);
    }

    return switch (widget.viewMode) {
      ViewMode.cards => Scrollbar(
        controller: _scrollController,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final note = visible[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: NoteCard(
                  key: ValueKey(note.id),
                  note: note,
                  index: index,
                  selected: note.id == widget.selectedId,
                  onOpen: widget.onOpen,
                  onTogglePin: store.togglePin,
                  onDelete: widget.onDelete,
                ),
              ),
            );
          },
        ),
      ),
      ViewMode.timeline => TimelineView(
        groups: groupNotesByDay(visible),
        selectedId: widget.selectedId,
        onOpen: widget.onOpen,
        onPlayDay: _playDay,
        onPlayAll: () => _playAll(visible),
      ),
      ViewMode.calendar => CalendarView(
        notes: visible,
        selectedId: widget.selectedId,
        onOpen: widget.onOpen,
        onPlayDay: _playAll,
      ),
    };
  }

  Widget _viewSwitch() {
    final (icon, tip) = switch (widget.viewMode) {
      ViewMode.cards => (Icons.view_timeline_outlined, '切换为日期列表'),
      ViewMode.timeline => (Icons.calendar_month_outlined, '切换为日历表'),
      ViewMode.calendar => (Icons.view_agenda_outlined, '切换为便签卡片'),
    };
    final next = switch (widget.viewMode) {
      ViewMode.cards => ViewMode.timeline,
      ViewMode.timeline => ViewMode.calendar,
      ViewMode.calendar => ViewMode.cards,
    };

    return InkButton(
      icon: icon,
      tooltip: tip,
      size: 27,
      onPressed: () => widget.onViewModeChanged(next),
    );
  }

  void _clear() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = _Filter.all;
    });
  }

  Widget _header(NoteStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SakuraGlyph(
                size: 14,
                color: Palette.sakuraDeep,
                stroke: 1.2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'YOZAKURA NOTE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    9.5,
                    color: Palette.lapis.withValues(alpha: 0.7),
                    spacing: 3.2,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkButton(
                icon: Icons.play_circle_outline,
                tooltip: '回顾播放',
                size: 30,
                onPressed: store.isEmpty ? null : () => _playAll(store.notes),
              ),
              const SizedBox(width: 6),
              InkButton(
                icon: Icons.edit_outlined,
                tooltip: '新建手记',
                active: true,
                size: 30,
                onPressed: widget.onCreate,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '夜樱手账',
            style: AppText.display(32, weight: FontWeight.w700, spacing: 3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 18,
                height: 1,
                color: Palette.ink.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 8),
              Text(
                headerDate(DateTime.now()),
                style: AppText.label(10, color: Palette.inkGhost, spacing: 1.6),
              ),
              const SizedBox(width: 8),
              Text(
                '· 共 ${store.total} 篇',
                style: AppText.label(10, color: Palette.inkGhost, spacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Palette.card.withValues(alpha: 0.7),
        border: Border.all(color: Palette.hairline, width: 1.2),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 15,
            color: Palette.inkGhost.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              cursorWidth: 1.2,
              cursorColor: Palette.lapis,
              style: AppText.body(12.5, color: Palette.ink, height: 1.4),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '搜索手记…',
                hintStyle: AppText.body(
                  12.5,
                  color: Palette.inkGhost,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            PressScale(
              onTap: _clear,
              scale: 0.85,
              child: Icon(Icons.close, size: 14, color: Palette.inkGhost),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: widget.onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? Palette.lapis
                : (_hover
                      ? Palette.lapis.withValues(alpha: 0.07)
                      : Colors.transparent),
            border: Border.all(
              color: active
                  ? Palette.lapis
                  : Palette.ink.withValues(alpha: 0.16),
              width: 1.1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: AppText.label(
                  10.5,
                  color: active ? Palette.card : Palette.inkSoft,
                  spacing: 1.4,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.count}',
                style: AppText.label(
                  9.5,
                  color: active
                      ? Palette.card.withValues(alpha: 0.75)
                      : Palette.inkGhost.withValues(alpha: 0.9),
                  spacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 132,
              height: 118,
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 6,
                    child: Transform.rotate(
                      angle: -0.13,
                      child: const Sheet(
                        padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
                        radius: 2,
                        child: _PaperLines(),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 4,
                    bottom: 0,
                    child: SakuraGlyph(
                      size: 62,
                      color: Palette.sakuraDeep,
                      stroke: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              '第一页，还空着',
              style: AppText.display(21, weight: FontWeight.w600, spacing: 1.6),
            ),
            const SizedBox(height: 10),
            Text(
              '哪怕只有一句「今天好累」，\n也值得被记下来。',
              textAlign: TextAlign.center,
              style: AppText.body(
                12.5,
                color: Palette.inkSoft,
                height: 1.9,
                spacing: 0.4,
              ),
            ),
            const SizedBox(height: 24),
            InkButton(
              icon: Icons.edit_outlined,
              label: '写第一页',
              active: true,
              size: 36,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SakuraGlyph(size: 44, color: Palette.inkGhost, stroke: 1.1),
            const SizedBox(height: 20),
            Text(
              query.trim().isEmpty ? '这里还没有手记' : '没有找到「${query.trim()}」',
              style: AppText.display(17, weight: FontWeight.w600, spacing: 1),
            ),
            const SizedBox(height: 10),
            PressScale(
              onTap: onClear,
              child: Text(
                '清空筛选，重新看看',
                style: AppText.label(11, color: Palette.lapis, spacing: 1.4)
                    .copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: Palette.lapis.withValues(alpha: 0.4),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperLines extends StatelessWidget {
  const _PaperLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in const [46.0, 38.0, 42.0, 26.0])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: w,
              height: 2,
              color: Palette.ink.withValues(alpha: 0.16),
            ),
          ),
      ],
    );
  }
}
