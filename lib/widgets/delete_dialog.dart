import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'decor.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Sheet(
          color: Palette.card,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          shadow: const Offset(5, 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SakuraGlyph(size: 15, color: Palette.seal, stroke: 1.2),
                  const SizedBox(width: 8),
                  Text(
                    '撕掉这一页？',
                    style: AppText.display(
                      18,
                      weight: FontWeight.w600,
                      spacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '「$title」删除之后就找不回来了。',
                style: AppText.body(
                  12.5,
                  color: Palette.inkSoft,
                  height: 1.8,
                  spacing: 0.3,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: PressScale(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Palette.ink.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '留下',
                          style: AppText.label(
                            11.5,
                            color: Palette.inkSoft,
                            spacing: 2,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressScale(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Palette.seal,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: inkShadow(
                            opacity: 0.18,
                            offset: const Offset(2, 2),
                          ),
                        ),
                        child: Text(
                          '删除',
                          style: AppText.label(
                            11.5,
                            color: Palette.card,
                            spacing: 2,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
