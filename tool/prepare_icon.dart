// 把 image.png（原图）加工成打包用的图标，整幅铺满，不留边框：
//   assets/icon/app_icon.png             方形主图标（Windows / iOS / Web / 传统 mipmap）
//   assets/icon/app_icon_foreground.png  安卓自适应前景（原图放大溢出画布，抵消生成器的 inset）
//
// 背景层用图角落的纯色（见 flutter_launcher_icons.yaml），遮罩圆内看不到任何边界。
//
// 用法：dart run tool/prepare_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final file = File('image.png');
  if (!file.existsSync()) {
    stderr.writeln('找不到 image.png');
    exitCode = 1;
    return;
  }

  final src = img.decodePng(file.readAsBytesSync());
  if (src == null) {
    stderr.writeln('无法解码 image.png');
    exitCode = 1;
    return;
  }
  stdout.writeln('source: ${src.width}x${src.height}');

  // 居中裁成正方形（铺满，不留边）
  final side = math.min(src.width, src.height);
  final square = img.copyCrop(
    src,
    x: (src.width - side) ~/ 2,
    y: (src.height - side) ~/ 2,
    width: side,
    height: side,
  );

  // 取角落色，作为自适应图标的纯色背景
  final corner = src.getPixel(0, 0);
  final hex =
      '#${corner.r.toInt().toRadixString(16).padLeft(2, '0')}'
              '${corner.g.toInt().toRadixString(16).padLeft(2, '0')}'
              '${corner.b.toInt().toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
  stdout.writeln('corner color: $hex (alpha ${corner.a.toInt()})');

  Directory('assets/icon').createSync(recursive: true);

  // 主图标：1024 方形，原图铺满
  const size = 1024;
  final icon = img.copyResize(
    square,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(icon));

  // 自适应前景：flutter_launcher_icons 会给前景加 inset(16%)。
  // 内容按 72% 比例呈现（inset 抵消后），文字两端刚好落在系统圆形遮罩内；
  // 内容边缘是原图自身的深蓝渐变，与纯色背景同色融合，因此不会出现方形边框。
  const insetRatio = 0.16;
  const contentRatio = 0.72;
  final drawSize = (size * contentRatio / (1 - 2 * insetRatio)).round();
  final big = img.copyResize(
    square,
    width: drawSize,
    height: drawSize,
    interpolation: img.Interpolation.cubic,
  );
  // 取放大图的中心区域作为前景 drawable
  final foreground = img.copyCrop(
    big,
    x: (drawSize - size) ~/ 2,
    y: (drawSize - size) ~/ 2,
    width: size,
    height: size,
  );
  File(
    'assets/icon/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  // 清理旧方案残留
  final stale = File('assets/icon/app_icon_background.png');
  if (stale.existsSync()) stale.deleteSync();

  stdout.writeln('written: assets/icon/app_icon.png');
  stdout.writeln('written: assets/icon/app_icon_foreground.png');
}
