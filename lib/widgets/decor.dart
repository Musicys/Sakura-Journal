import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 单枚樱花花瓣路径（尖端带缺口）
Path sakuraPetalPath(double r) {
  final p = Path()..moveTo(0, 0);
  p.cubicTo(-r * 0.64, -r * 0.26, -r * 0.56, -r * 0.84, -r * 0.13, -r * 0.98);
  p.quadraticBezierTo(0, -r * 0.78, r * 0.13, -r * 0.98);
  p.cubicTo(r * 0.56, -r * 0.84, r * 0.64, -r * 0.26, 0, 0);
  p.close();
  return p;
}

/// 五瓣樱花路径
Path sakuraPath(double r) {
  final path = Path();
  final petal = sakuraPetalPath(r);
  for (var i = 0; i < 5; i++) {
    final m = Matrix4.identity()..rotateZ(i * math.pi * 2 / 5);
    path.addPath(petal.transform(m.storage), Offset.zero);
  }
  return path;
}

/// 樱花图标
class SakuraGlyph extends StatelessWidget {
  const SakuraGlyph({
    super.key,
    this.size = 40,
    this.color = Palette.sakuraDeep,
    this.filled = false,
    this.stroke = 1.4,
    this.rotation = 0,
  });

  final double size;
  final Color color;
  final bool filled;
  final double stroke;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size.square(size),
        painter: _SakuraPainter(color: color, filled: filled, stroke: stroke),
      ),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  _SakuraPainter({
    required this.color,
    required this.filled,
    required this.stroke,
  });

  final Color color;
  final bool filled;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * 0.46;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..color = color;

    final path = sakuraPath(r);
    if (filled) {
      canvas.drawPath(path, fillPaint);
    } else {
      canvas.drawPath(path, outline);
      // 花蕊
      final hair = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.75
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: color.a * 0.7);
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * math.pi * 2 / 5;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(a), math.sin(a)) * r * 0.34,
          hair,
        );
      }
      canvas.drawCircle(Offset.zero, r * 0.1, fillPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SakuraPainter old) =>
      old.color != color || old.filled != filled || old.stroke != stroke;
}

/// 和纸底 + 网点 + 角落樱花 + 飘落花瓣
class PaperBackdrop extends StatelessWidget {
  const PaperBackdrop({super.key, required this.child, this.petals = true});

  final Widget child;
  final bool petals;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _PaperPainter())),
        ),
        if (petals)
          const Positioned.fill(
            child: IgnorePointer(child: RepaintBoundary(child: PetalRain())),
          ),
        child,
      ],
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.paper);

    // 漫画网点
    final dot = Paint()..color = Palette.ink.withValues(alpha: 0.030);
    const gap = 22.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        final shifted = ((y / gap).round().isEven) ? x : x + gap / 2;
        canvas.drawCircle(Offset(shifted, y), 0.9, dot);
      }
    }

    // 右上角淡樱花
    canvas.save();
    canvas.translate(size.width - 40, 26);
    canvas.rotate(0.42);
    canvas.drawPath(
      sakuraPath(168),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.sakuraDeep.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      sakuraPath(104),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Palette.lapis.withValues(alpha: 0.10),
    );
    canvas.restore();

    // 左下角冷色晕（多层同心圆做柔边）
    final bloom = Paint();
    const bloomLayers = <(double, double)>[
      (150, 0.14),
      (205, 0.10),
      (260, 0.06),
      (330, 0.03),
    ];
    for (final (radius, alpha) in bloomLayers) {
      bloom.color = Palette.lapisMist.withValues(alpha: alpha);
      canvas.drawCircle(Offset(10, size.height - 20), radius, bloom);
    }

    // 顶部一道极细墨线
    canvas.drawLine(
      Offset(0, 0.5),
      Offset(size.width, 0.5),
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.06)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 和纸质感底色（纯色 + 网点），用于编辑器纸页
class PaperTexture extends StatelessWidget {
  const PaperTexture({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _TexturePainter(color: color)),
        ),
        child,
      ],
    );
  }
}

class _TexturePainter extends CustomPainter {
  const _TexturePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final dot = Paint()..color = Palette.ink.withValues(alpha: 0.022);
    const gap = 20.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 0.7, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_TexturePainter old) => old.color != color;
}

/// 飘落的花瓣层
class PetalRain extends StatefulWidget {
  const PetalRain({super.key, this.count = 7, this.opacity = 0.4});

  final int count;
  final double opacity;

  @override
  State<PetalRain> createState() => _PetalRainState();
}

class _PetalRainState extends State<PetalRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
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
      builder: (context, _) => CustomPaint(
        painter: _PetalPainter(
          progress: _controller.value,
          count: widget.count,
          opacity: widget.opacity,
        ),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.progress,
    required this.count,
    required this.opacity,
  });

  final double progress;
  final int count;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final speed = 0.6 + (i % 3) * 0.22;
      final phase = (i * 0.31) % 1.0;
      final t = (progress * speed + phase) % 1.0;

      final baseX = size.width * (0.06 + ((i * 0.1417) % 0.86));
      final drift = math.sin(t * math.pi * 2.2 + i * 1.7) * 34;
      final y = -70 + t * (size.height + 140);

      canvas.save();
      canvas.translate(baseX + drift, y);
      canvas.rotate(t * math.pi * 2 * (1 + (i % 2) * 0.8) + i);
      paint.color = (i.isEven ? Palette.sakura : Palette.fuji).withValues(
        alpha: opacity * (0.55 + (i % 3) * 0.2),
      );
      canvas.drawPath(sakuraPetalPath(4.5 + (i % 4) * 1.7), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) =>
      old.progress != progress || old.count != count || old.opacity != opacity;
}

/// 和纸胶带
class WashiTape extends StatelessWidget {
  const WashiTape({
    super.key,
    this.width = 62,
    this.height = 18,
    this.color = Palette.sakura,
    this.angle = -0.06,
  });

  final double width;
  final double height;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, height),
        painter: _TapePainter(color: color),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  _TapePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const teeth = 4;
    final step = size.height / teeth;
    final p = Path()..moveTo(3, 0);
    p.lineTo(size.width - 3, 0);
    for (var i = 1; i <= teeth; i++) {
      p.lineTo(i.isEven ? size.width - 5 : size.width - 3, i * step);
    }
    p.lineTo(3, size.height);
    for (var i = teeth; i >= 1; i--) {
      p.lineTo(i.isOdd ? 5 : 3, (i - 1) * step);
    }
    p.close();

    canvas.drawPath(p, Paint()..color = color.withValues(alpha: 0.55));

    // 胶带上的纤维纹
    final fiber = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 8.0; x < size.width - 8; x += 7) {
      canvas.drawLine(Offset(x, 1.5), Offset(x - 2, size.height - 1.5), fiber);
    }
  }

  @override
  bool shouldRepaint(_TapePainter old) => old.color != color;
}

/// 印刷感卡片：细墨线描边 + 无模糊硬投影
class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    required this.child,
    this.color = Palette.card,
    this.borderColor,
    this.padding = EdgeInsets.zero,
    this.radius = 3,
    this.shadow = const Offset(3, 3),
    this.shadowColor,
  });

  final Widget child;
  final Color color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Offset shadow;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Palette.hairline, width: 1.2),
        boxShadow: shadow == Offset.zero
            ? null
            : [
                BoxShadow(
                  color: shadowColor ?? Palette.ink.withValues(alpha: 0.10),
                  offset: shadow,
                  blurRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// 按压微交互
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.965,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (!mounted || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: interactive ? (_) => _set(true) : null,
        onTapUp: interactive ? (_) => _set(false) : null,
        onTapCancel: interactive ? () => _set(false) : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutQuart,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 方形描边图标按钮（带 hover 反馈）
class InkButton extends StatefulWidget {
  const InkButton({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.tooltip,
    this.active = false,
    this.danger = false,
    this.size = 34,
    this.radius = 3,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;
  final bool danger;
  final double size;
  final double radius;

  @override
  State<InkButton> createState() => _InkButtonState();
}

class _InkButtonState extends State<InkButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.danger ? Palette.seal : Palette.lapis;
    final enabled = widget.onPressed != null;
    final tinted = widget.active || _hover;

    final button = PressScale(
      enabled: enabled,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutQuart,
        height: widget.size,
        width: widget.label == null ? widget.size : null,
        padding: widget.label == null
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: widget.active
              ? accent.withValues(alpha: 0.10)
              : (_hover ? accent.withValues(alpha: 0.06) : Colors.transparent),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: tinted ? accent.withValues(alpha: 0.55) : Palette.hairline,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: widget.size * 0.5,
              color: enabled
                  ? (tinted ? accent : Palette.inkSoft)
                  : Palette.inkGhost.withValues(alpha: 0.5),
            ),
            if (widget.label != null) ...[
              const SizedBox(width: 6),
              Text(
                widget.label!,
                style: AppText.label(
                  11.5,
                  color: enabled
                      ? (tinted ? accent : Palette.inkSoft)
                      : Palette.inkGhost,
                  spacing: 1.2,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.tooltip == null
          ? button
          : Tooltip(message: widget.tooltip!, child: button),
    );
  }
}

/// 虚线分隔（手账里的撕纸线）
class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.color,
    this.height = 1,
    this.dash = 4,
    this.gap = 4,
  });

  final Color? color;
  final double height;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashPainter(
          color: color ?? Palette.ink.withValues(alpha: 0.14),
          dash: dash,
          gap: gap,
          thickness: height,
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({
    required this.color,
    required this.dash,
    required this.gap,
    required this.thickness,
  });

  final Color color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.gap != gap;
}
