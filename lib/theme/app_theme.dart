import 'package:flutter/material.dart';

/// 「夜樱手账」配色
///
/// 一切都围绕三种材料：和纸（暖白）、墨（冷黑）、印花（瑠璃 + 樱花）。
/// 不使用纯黑纯白，避免廉价对比。
abstract final class Palette {
  // 纸
  static const paper = Color(0xFFF6F0E4);
  static const paperDeep = Color(0xFFEDE1CE);
  static const card = Color(0xFFFDFAF2);

  // 墨
  static const ink = Color(0xFF221E1B);
  static const inkSoft = Color(0xFF6C6259);
  static const inkGhost = Color(0xFFA2968A);
  static const hairline = Color(0x24221E1B);

  // 瑠璃（群青）—— 主色
  static const lapis = Color(0xFF2C3A8E);
  static const lapisDeep = Color(0xFF1A2260);
  static const lapisMist = Color(0xFFE6E9F7);

  // 樱花
  static const sakura = Color(0xFFF5AEC0);
  static const sakuraDeep = Color(0xFFE06D8C);
  static const sakuraMist = Color(0xFFFCEBF0);

  // 点缀
  static const seal = Color(0xFFCB4739);
  static const matcha = Color(0xFF78996F);
  static const yamabuki = Color(0xFFE0A93C);
  static const fuji = Color(0xFF968AC4);

  /// 便签纸色（右滑切换）
  static const notePapers = <Color>[
    Color(0xFFFEFAF0), // 生成
    Color(0xFFFDEFF3), // 桜
    Color(0xFFEDF2FB), // 空
    Color(0xFFEFF6EA), // 若葉
    Color(0xFFFDF5E2), // 山吹
    Color(0xFFF3EFFB), // 藤
  ];

  static const paperNames = <String>['生成', '桜', '空', '若葉', '山吹', '藤'];

  /// 心情贴纸：只用一个汉字，胜过大颗 emoji
  static const moodGlyphs = <String>['凪', '晴', '閃', '眠', '憂'];
  static const moodNames = <String>['平静', '愉快', '灵感', '疲惫', '低落'];
  static const moodColors = <Color>[lapis, yamabuki, sakuraDeep, fuji, inkSoft];
}

abstract final class AppText {
  static const serif = 'Noto Serif SC';
  static const sans = 'Noto Sans SC';

  static const serifFallback = <String>[
    'Source Han Serif SC',
    'Songti SC',
    'STSong',
    'SimSun',
    'Microsoft YaHei',
  ];

  static const sansFallback = <String>[
    'Source Han Sans SC',
    'PingFang SC',
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Segoe UI',
  ];

  static TextStyle display(
    double size, {
    Color color = Palette.ink,
    FontWeight weight = FontWeight.w700,
    double height = 1.28,
    double spacing = 1.2,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontFamilyFallback: serifFallback,
      fontSize: size,
      height: height,
      letterSpacing: spacing,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle body(
    double size, {
    Color color = Palette.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.8,
    double spacing = 0.2,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontFamilyFallback: sansFallback,
      fontSize: size,
      height: height,
      letterSpacing: spacing,
      fontWeight: weight,
      color: color,
    );
  }

  /// 小标签：日式手账里的细字注音
  static TextStyle label(
    double size, {
    Color color = Palette.inkGhost,
    double spacing = 2.0,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontFamilyFallback: sansFallback,
      fontSize: size,
      letterSpacing: spacing,
      height: 1.2,
      fontWeight: weight,
      color: color,
    );
  }
}

/// 印刷感阴影：模糊为 0 的硬投影，模拟油墨压印
List<BoxShadow> inkShadow({
  double opacity = 0.10,
  Offset offset = const Offset(3, 3),
}) {
  return <BoxShadow>[
    BoxShadow(
      color: Palette.ink.withValues(alpha: opacity),
      offset: offset,
      blurRadius: 0,
    ),
  ];
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.lapis,
        brightness: Brightness.light,
      ).copyWith(
        primary: Palette.lapis,
        onPrimary: Palette.card,
        secondary: Palette.sakuraDeep,
        surface: Palette.card,
        onSurface: Palette.ink,
        outline: Palette.hairline,
      );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: Palette.paper,
    canvasColor: Palette.paper,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Palette.lapis.withValues(alpha: 0.04),
    dividerTheme: const DividerThemeData(
      color: Palette.hairline,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.lapis,
      selectionColor: Palette.lapis.withValues(alpha: 0.18),
      selectionHandleColor: Palette.lapis,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(4),
      radius: const Radius.circular(2),
      thumbColor: WidgetStateProperty.all(Palette.ink.withValues(alpha: 0.14)),
      crossAxisMargin: 2,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(3),
      ),
      textStyle: AppText.label(11, color: Palette.card, spacing: 0.6),
      waitDuration: const Duration(milliseconds: 500),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: AppText.sans,
      fontFamilyFallback: AppText.sansFallback,
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
  );
}
