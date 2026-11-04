// 本机图片存储：有文件系统时走真实文件，Web 等平台退化为不支持。
export 'media_store_stub.dart' if (dart.library.io) 'media_store_io.dart';
