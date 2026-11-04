import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';
import '../utils/journal_date.dart';
import 'media_store.dart';

/// 时间轴上的一天
class DayGroup {
  const DayGroup({required this.day, required this.notes});

  final DateTime day;
  final List<Note> notes;

  int get count => notes.length;
}

/// 按「写下那天」分组：日期倒序，组内新写的在前
List<DayGroup> groupNotesByDay(List<Note> source) {
  final buckets = <String, List<Note>>{};
  for (final note in source) {
    buckets.putIfAbsent(dayKey(note.createdAt), () => <Note>[]).add(note);
  }

  final groups = <DayGroup>[];
  for (final items in buckets.values) {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final first = items.first.createdAt;
    groups.add(
      DayGroup(day: DateTime(first.year, first.month, first.day), notes: items),
    );
  }
  groups.sort((a, b) => b.day.compareTo(a.day));
  return groups;
}

/// 回顾播放顺序：从最早的一篇翻到今天
List<Note> chronologicalNotes(Iterable<Note> source) {
  return List<Note>.of(source)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

/// 笔记仓库：内存列表 + 防抖写入本地缓存。
///
/// 所有数据都只来自本机缓存（shared_preferences），首次启动是一本空手账。
class NoteStore extends ChangeNotifier {
  NoteStore(this._prefs, this._notes);

  static const _storageKey = 'yozakura.notes.v1';

  final SharedPreferences _prefs;
  final List<Note> _notes;
  Timer? _flushTimer;

  static Future<NoteStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    final notes = <Note>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        notes.addAll(list.map((e) => Note.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // 缓存损坏时以空手账启动，不影响继续使用
        notes.clear();
      }
    }

    return NoteStore(prefs, notes);
  }

  /// 置顶优先，其次按更新时间倒序
  List<Note> get notes {
    final copy = List<Note>.from(_notes);
    copy.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return copy;
  }

  int get total => _notes.length;
  int get favorites => _notes.where((n) => n.favorite).length;
  int get pinnedCount => _notes.where((n) => n.pinned).length;
  bool get isEmpty => _notes.isEmpty;

  Note? byId(String? id) {
    if (id == null) return null;
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// 新增
  Note create({
    int paper = 0,
    int mood = 0,
    String title = '',
    String body = '',
  }) {
    final now = DateTime.now();
    final note = Note(
      id: 'n${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      paper: paper,
      mood: mood,
    );
    _notes.add(note);
    _flush();
    notifyListeners();
    return note;
  }

  /// 修改：编辑后提交，刷新时间戳并写入缓存
  void commit(Note note) {
    note.updatedAt = DateTime.now();
    _flush();
    notifyListeners();
  }

  void togglePin(Note note) {
    note.pinned = !note.pinned;
    note.updatedAt = DateTime.now();
    _flush();
    notifyListeners();
  }

  void toggleFavorite(Note note) {
    note.favorite = !note.favorite;
    _flush();
    notifyListeners();
  }

  void setPaper(Note note, int paper) {
    note.paper = paper % PaletteLength.notePapers;
    _flush();
    notifyListeners();
  }

  void setMood(Note note, int mood) {
    note.mood = mood % PaletteLength.moods;
    _flush();
    notifyListeners();
  }

  /// 删除（同时清掉这篇手记引用的本机图片）
  void remove(String id) {
    final target = byId(id);
    if (target != null) {
      for (final name in target.images) {
        MediaStore.remove(name);
      }
    }
    _notes.removeWhere((n) => n.id == id);
    _flush();
    notifyListeners();
  }

  void _flush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 300), _persistNow);
  }

  Future<void> _persistNow() async {
    try {
      await _prefs.setString(
        _storageKey,
        jsonEncode(_notes.map((n) => n.toJson()).toList()),
      );
    } catch (_) {
      // 存储失败不影响当前会话
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}

/// 与主题中的调色板长度保持同步（避免 store 依赖 UI 层的 Color 常量）
abstract final class PaletteLength {
  static const notePapers = 6;
  static const moods = 5;
}

class NotesScope extends InheritedNotifier<NoteStore> {
  const NotesScope({super.key, required NoteStore store, required super.child})
    : super(notifier: store);

  static NoteStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NotesScope>();
    assert(scope?.notifier != null, 'NotesScope 未找到');
    return scope!.notifier!;
  }

  /// 不建立依赖（用于回调里取仓库，避免不必要重建）
  static NoteStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<NotesScope>();
    assert(scope?.notifier != null, 'NotesScope 未找到');
    return scope!.notifier!;
  }
}
