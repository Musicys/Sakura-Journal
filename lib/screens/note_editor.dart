import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/media_store.dart';
import '../data/note_store.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/journal_date.dart';
import '../widgets/decor.dart';
import '../widgets/delete_dialog.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.note,
    this.onBack,
    this.onDeleted,
  });

  final Note note;
  final VoidCallback? onBack;
  final VoidCallback? onDeleted;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.note.title,
  );
  late final TextEditingController _bodyController = TextEditingController(
    text: widget.note.body,
  );

  final _bodyScrollController = ScrollController();
  Timer? _saveTimer;
  bool _saving = false;
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    _savedAt = widget.note.updatedAt;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body(12.5, color: Palette.card)),
        backgroundColor: Palette.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 从系统相册挑选本机图片，复制到应用私有目录后再引用
  Future<void> _pickImages() async {
    if (!MediaStore.isReady) {
      _toast('图片目录还没准备好，稍后再试');
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2200,
        imageQuality: 88,
      );
      if (files.isEmpty || !mounted) return;

      var added = 0;
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final saved = await MediaStore.save(bytes, file.name);
        if (saved != null) {
          widget.note.images.add(saved);
          added++;
        }
      }
      if (!mounted) return;
      if (added == 0) {
        _toast('没能读取这张图片');
        return;
      }
      _onChanged();
    } catch (_) {
      if (mounted) _toast('没能读取这张图片');
    }
  }

  void _removeImage(String name) {
    widget.note.images.remove(name);
    MediaStore.remove(name);
    _onChanged();
  }

  void _onChanged() {
    widget.note.title = _titleController.text;
    widget.note.body = _bodyController.text;
    setState(() => _saving = true);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      NotesScope.read(context).commit(widget.note);
      setState(() {
        _saving = false;
        _savedAt = DateTime.now();
      });
    });
  }

  Future<void> _confirmDelete() async {
    final store = NotesScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Palette.ink.withValues(alpha: 0.28),
      builder: (_) => DeleteDialog(title: widget.note.displayTitle),
    );
    if (confirmed != true || !mounted) return;
    store.remove(widget.note.id);
    widget.onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);
    final note = widget.note;
    final paper =
        Palette.notePapers[note.paper.clamp(0, Palette.notePapers.length - 1)];
    final moodColor =
        Palette.moodColors[note.mood.clamp(0, Palette.moodColors.length - 1)];

    return PaperTexture(
      color: paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(note, store),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: const DashedDivider(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 18, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('note-title'),
                    controller: _titleController,
                    onChanged: (_) => _onChanged(),
                    cursorWidth: 1.6,
                    cursorColor: Palette.lapis,
                    style: AppText.display(
                      29,
                      weight: FontWeight.w700,
                      height: 1.35,
                      spacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '标题',
                      hintStyle: AppText.display(
                        29,
                        color: Palette.inkGhost.withValues(alpha: 0.5),
                        weight: FontWeight.w700,
                        spacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _metaRow(note, store, moodColor),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Palette.sakuraDeep.withValues(alpha: 0.22),
                            width: 1.4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 18, top: 6),
                      child: Scrollbar(
                        controller: _bodyScrollController,
                        child: SingleChildScrollView(
                          controller: _bodyScrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 220,
                                ),
                                child: TextField(
                                  key: const ValueKey('note-body'),
                                  controller: _bodyController,
                                  onChanged: (_) => _onChanged(),
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  cursorWidth: 1.6,
                                  cursorColor: Palette.lapis,
                                  style: AppText.body(
                                    14.5,
                                    color: Palette.ink,
                                    height: 1.95,
                                    spacing: 0.45,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                      bottom: 24,
                                    ),
                                    hintText: '写点什么。\n不必完整，不必正确。',
                                    hintStyle: AppText.body(
                                      14.5,
                                      color: Palette.inkGhost.withValues(
                                        alpha: 0.65,
                                      ),
                                      height: 1.95,
                                      spacing: 0.45,
                                    ),
                                  ),
                                ),
                              ),
                              if (note.images.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 16,
                                  children: [
                                    for (var i = 0; i < note.images.length; i++)
                                      NotePhoto(
                                        key: ValueKey(note.images[i]),
                                        name: note.images[i],
                                        index: i,
                                        onRemove: () =>
                                            _removeImage(note.images[i]),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _statusBar(note),
        ],
      ),
    );
  }

  Widget _toolbar(Note note, NoteStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            InkButton(
              icon: Icons.arrow_back,
              tooltip: '返回',
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NOTE · ${journalDate(note.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    9,
                    color: Palette.inkGhost,
                    spacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${note.charCount} 字 / ${Palette.paperNames[note.paper.clamp(0, 5)]}纸',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    9.5,
                    color: Palette.inkSoft,
                    spacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (MediaStore.isSupported) ...[
            InkButton(
              icon: Icons.add_photo_alternate_outlined,
              tooltip: '插入本机图片',
              onPressed: _pickImages,
            ),
            const SizedBox(width: 8),
          ],
          InkButton(
            icon: note.favorite ? Icons.favorite : Icons.favorite_border,
            tooltip: note.favorite ? '取消收藏' : '收藏',
            active: note.favorite,
            onPressed: () => store.toggleFavorite(note),
          ),
          const SizedBox(width: 8),
          InkButton(
            icon: note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            tooltip: note.pinned ? '取消置顶' : '置顶',
            active: note.pinned,
            onPressed: () => store.togglePin(note),
          ),
          const SizedBox(width: 8),
          InkButton(
            icon: Icons.delete_outline,
            tooltip: '删除这一页',
            danger: true,
            onPressed: _confirmDelete,
          ),
        ],
      ),
    );
  }

  Widget _metaRow(Note note, NoteStore store, Color moodColor) {
    return Row(
      children: [
        for (var i = 0; i < Palette.moodGlyphs.length; i++) ...[
          _MoodDot(
            glyph: Palette.moodGlyphs[i],
            color: Palette.moodColors[i],
            selected: note.mood == i,
            onTap: () => store.setMood(note, i),
          ),
          const SizedBox(width: 5),
        ],
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            Palette.moodNames[note.mood.clamp(0, 4)],
            key: ValueKey(note.mood),
            style: AppText.label(
              10,
              color: moodColor,
              spacing: 1.6,
              weight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        for (var i = 0; i < Palette.notePapers.length; i++) ...[
          _PaperSwatch(
            color: Palette.notePapers[i],
            selected: note.paper == i,
            onTap: () => store.setPaper(note, i),
          ),
          if (i != Palette.notePapers.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }

  Widget _statusBar(Note note) {
    final saved = _savedAt;
    final label = _saving
        ? '编辑中…'
        : (saved == null
              ? '尚未保存'
              : '已保存 ${saved.hour.toString().padLeft(2, '0')}:${saved.minute.toString().padLeft(2, '0')}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 8, 26, 14),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 11,
            color: Palette.inkGhost.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '本地保存 · 最后编辑 ${journalDate(note.updatedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(9.5, color: Palette.inkGhost, spacing: 1.2),
            ),
          ),
          const SizedBox(width: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              label,
              key: ValueKey(label),
              style: AppText.label(
                9.5,
                color: _saving ? Palette.sakuraDeep : Palette.inkGhost,
                spacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 拍立得样式的本机图片
class NotePhoto extends StatefulWidget {
  const NotePhoto({
    super.key,
    required this.name,
    required this.index,
    required this.onRemove,
  });

  final String name;
  final int index;
  final VoidCallback onRemove;

  @override
  State<NotePhoto> createState() => _NotePhotoState();
}

class _NotePhotoState extends State<NotePhoto> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final provider = MediaStore.provider(widget.name);
    final tilt = (widget.index.isEven ? 1 : -1) * 0.02;

    Widget fallback() => Container(
      color: Palette.paperDeep,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 18,
        color: Palette.inkGhost,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Transform.rotate(
        angle: _hover ? 0 : tilt,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          decoration: BoxDecoration(
            color: Palette.card,
            border: Border.all(
              color: Palette.ink.withValues(alpha: 0.14),
              width: 1.2,
            ),
            boxShadow: inkShadow(
              opacity: _hover ? 0.18 : 0.10,
              offset: Offset(_hover ? 5 : 3, _hover ? 6 : 4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 134,
                height: 134,
                child: provider == null
                    ? fallback()
                    : Image(
                        image: provider,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => fallback(),
                      ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 134,
                child: Row(
                  children: [
                    Text(
                      'NO.${widget.index + 1}',
                      style: AppText.label(
                        8.5,
                        color: Palette.inkGhost,
                        spacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    PressScale(
                      onTap: widget.onRemove,
                      scale: 0.82,
                      child: Tooltip(
                        message: '移出这张图',
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Palette.seal.withValues(
                            alpha: _hover ? 0.95 : 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodDot extends StatefulWidget {
  const _MoodDot({
    required this.glyph,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String glyph;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MoodDot> createState() => _MoodDotState();
}

class _MoodDotState extends State<_MoodDot> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: widget.onTap,
        scale: 0.9,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutQuart,
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.selected
                ? widget.color.withValues(alpha: 0.14)
                : (_hover
                      ? widget.color.withValues(alpha: 0.07)
                      : Colors.transparent),
            border: Border.all(
              color: active
                  ? widget.color.withValues(alpha: 0.7)
                  : Palette.ink.withValues(alpha: 0.14),
              width: 1.1,
            ),
          ),
          child: Text(
            widget.glyph,
            style: AppText.display(
              11.5,
              color: active ? widget.color : Palette.inkGhost,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperSwatch extends StatefulWidget {
  const _PaperSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PaperSwatch> createState() => _PaperSwatchState();
}

class _PaperSwatchState extends State<_PaperSwatch> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: Palette.paperNames[Palette.notePapers.indexOf(widget.color)],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: PressScale(
          onTap: widget.onTap,
          scale: 0.86,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1.5),
              border: Border.all(
                color: widget.selected
                    ? Palette.ink.withValues(alpha: 0.75)
                    : Palette.ink.withValues(alpha: _hover ? 0.35 : 0.16),
                width: widget.selected ? 1.4 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
