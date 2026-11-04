import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// 本机图片的落盘管理。
///
/// 相册里选中的图片会被复制到应用私有目录（`<documents>/yozakura_media`），
/// 手记里只记录文件名。这样相册里的原图被删掉也不会让手记里的图失效。
class MediaStore {
  static const _folder = 'yozakura_media';
  static String? _root;
  static bool _started = false;

  static bool get isSupported => true;

  /// 私有目录是否已就绪
  static bool get isReady => _root != null;

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}${Platform.pathSeparator}$_folder');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _root = dir.path;
    } catch (_) {
      _root = null;
    }
  }

  /// 保存图片字节，返回内部文件名；失败返回 null
  static Future<String?> save(List<int> bytes, String originalName) async {
    final root = _root;
    if (root == null || bytes.isEmpty) return null;
    try {
      final name =
          'm${DateTime.now().microsecondsSinceEpoch}${_extension(originalName)}';
      final file = File('$root${Platform.pathSeparator}$name');
      await file.writeAsBytes(bytes, flush: true);
      return name;
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String name) async {
    final root = _root;
    if (root == null) return;
    try {
      final file = File('$root${Platform.pathSeparator}$name');
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 文件不存在或占用时忽略
    }
  }

  static ImageProvider? provider(String name) {
    final root = _root;
    if (root == null) return null;
    return FileImage(File('$root${Platform.pathSeparator}$name'));
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
    return allowed.contains(ext) ? ext : '.jpg';
  }
}
