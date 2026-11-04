import 'package:flutter/material.dart';

import '../data/note_store.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/decor.dart';
import '../widgets/delete_dialog.dart';
import 'note_editor.dart';
import 'note_list_panel.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String? _selectedId;
  ViewMode _viewMode = ViewMode.cards;

  void _open(Note note, {required bool wide}) {
    if (wide) {
      setState(() => _selectedId = note.id);
    } else {
      _pushEditor(note);
    }
  }

  void _create({required bool wide}) {
    final store = NotesScope.read(context);
    final note = store.create(paper: store.total % Palette.notePapers.length);
    if (wide) {
      setState(() => _selectedId = note.id);
    } else {
      _pushEditor(note);
    }
  }

  void _pushEditor(Note note) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _EditorPage(noteId: note.id),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final store = NotesScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Palette.ink.withValues(alpha: 0.28),
      builder: (_) => DeleteDialog(title: note.displayTitle),
    );
    if (ok != true || !mounted) return;
    if (_selectedId == note.id) setState(() => _selectedId = null);
    store.remove(note.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);
    final selected = store.byId(_selectedId);

    return Scaffold(
      backgroundColor: Palette.paper,
      body: PaperBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              if (!wide) {
                return NoteListPanel(
                  selectedId: null,
                  viewMode: _viewMode,
                  onViewModeChanged: (mode) => setState(() => _viewMode = mode),
                  onOpen: (note) => _open(note, wide: false),
                  onCreate: () => _create(wide: false),
                  onDelete: _confirmDelete,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 400,
                    child: NoteListPanel(
                      selectedId: _selectedId,
                      viewMode: _viewMode,
                      onViewModeChanged: (mode) =>
                          setState(() => _viewMode = mode),
                      onOpen: (note) => _open(note, wide: true),
                      onCreate: () => _create(wide: true),
                      onDelete: _confirmDelete,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Palette.ink.withValues(alpha: 0.10),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeOutQuart,
                      child: selected == null
                          ? _WelcomePanel(
                              key: const ValueKey('welcome'),
                              onCreate: () => _create(wide: true),
                            )
                          : NoteEditor(
                              key: ValueKey(selected.id),
                              note: selected,
                              onDeleted: () =>
                                  setState(() => _selectedId = null),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditorPage extends StatefulWidget {
  const _EditorPage({required this.noteId});

  final String noteId;

  @override
  State<_EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<_EditorPage> {
  Note? _lastSeen;

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);
    final note = store.byId(widget.noteId) ?? _lastSeen;
    if (note != null) _lastSeen = note;

    return Scaffold(
      backgroundColor: Palette.paper,
      body: PaperBackdrop(
        child: SafeArea(
          child: note == null
              ? const SizedBox.shrink()
              : NoteEditor(
                  note: note,
                  onBack: () => Navigator.of(context).maybePop(),
                  onDeleted: () => Navigator.of(context).maybePop(),
                ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SlowSpin(
                child: SakuraGlyph(
                  size: 76,
                  color: Palette.sakuraDeep,
                  stroke: 1.1,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'W E L C O M E   B A C K',
                style: AppText.label(
                  9.5,
                  color: Palette.lapis.withValues(alpha: 0.75),
                  spacing: 3,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '今天，想留下什么呢',
                textAlign: TextAlign.center,
                style: AppText.display(27, weight: FontWeight.w700, spacing: 2),
              ),
              const SizedBox(height: 16),
              Text(
                '手记只保存在这台设备上。\n安静、离线，像一本真正放在床头的本子。',
                textAlign: TextAlign.center,
                style: AppText.body(
                  12.5,
                  color: Palette.inkSoft,
                  height: 2.0,
                  spacing: 0.4,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat(value: '${store.total}', label: '手记'),
                  _statDivider(),
                  _Stat(value: '${store.favorites}', label: '收藏'),
                  _statDivider(),
                  _Stat(value: '${store.pinnedCount}', label: '置顶'),
                ],
              ),
              const SizedBox(height: 32),
              InkButton(
                icon: Icons.edit_outlined,
                label: '写新的一页',
                size: 40,
                active: true,
                onPressed: onCreate,
              ),
              const SizedBox(height: 18),
              Text(
                '也可以从左侧挑一篇继续写',
                style: AppText.label(
                  9.5,
                  color: Palette.inkGhost,
                  spacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Palette.ink.withValues(alpha: 0.12),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppText.display(
            24,
            color: Palette.lapis,
            weight: FontWeight.w700,
            spacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppText.label(9.5, color: Palette.inkGhost, spacing: 2.2),
        ),
      ],
    );
  }
}

class _SlowSpin extends StatefulWidget {
  const _SlowSpin({required this.child});

  final Widget child;

  @override
  State<_SlowSpin> createState() => _SlowSpinState();
}

class _SlowSpinState extends State<_SlowSpin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 44),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.rotate(
        angle: _controller.value * 6.28318530718,
        child: child,
      ),
      child: widget.child,
    );
  }
}
