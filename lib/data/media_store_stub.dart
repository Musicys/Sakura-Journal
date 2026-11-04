import 'package:flutter/widgets.dart';

/// Web 等没有本机文件系统的平台上的占位实现：不支持插入本机图片。
class MediaStore {
  static bool get isSupported => false;

  static bool get isReady => false;

  static Future<void> init() async {}

  static Future<String?> save(List<int> bytes, String originalName) async =>
      null;

  static Future<void> remove(String name) async {}

  static ImageProvider? provider(String name) => null;
}
