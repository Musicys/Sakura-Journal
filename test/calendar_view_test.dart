import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_test/data/note_store.dart';
import 'package:my_test/main.dart';
import 'package:my_test/screens/calendar_view.dart';
import 'package:my_test/screens/memory_player.dart';
import 'package:my_test/utils/journal_date.dart';

void main() {
  Future<NoteStore> boot() async {
    SharedPreferences.setMockInitialValues({});
    return NoteStore.open();
  }

  void expectClean(WidgetTester tester) {
    final error = tester.takeException();
    if (error is FlutterError) debugPrint(error.toStringDeep());
    expect(error, isNull, reason: '不应出现布局溢出或渲染异常');
  }

  testWidgets('日历表按天显示手记数量，点一天看那天', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    final now = DateTime.now();
    // 今天两篇
    for (final hour in [9, 20]) {
      final note = store.create();
      note.title = '今天第 $hour 点';
      note.body = '今天写的第 $hour 点的那一页。';
      note.createdAt = DateTime(now.year, now.month, now.day, hour);
      store.commit(note);
    }
    // 本月另一天一篇
    final other = now.day > 1
        ? DateTime(now.year, now.month, now.day - 1)
        : DateTime(now.year, now.month, now.day + 1);
    final side = store.create();
    side.title = '另一天的记录';
    side.body = '这一天也写了一点点。';
    side.createdAt = DateTime(other.year, other.month, other.day, 12);
    store.commit(side);

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    // cards → timeline → calendar
    await tester.tap(find.byTooltip('切换为日期列表'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('切换为日历表'));
    await tester.pump(const Duration(milliseconds: 400));

    final calendar = find.byType(CalendarView);
    expect(find.text('${now.year} 年 ${now.month} 月'), findsOneWidget);
    // 默认选中最近有手记的那天（今天），面板显示两篇
    expect(
      find.descendant(
        of: calendar,
        matching: find.text('${dayLabel(now)} · ${weekdayLabel(now)}'),
      ),
      findsOneWidget,
    );
    expect(find.text('今天第 9 点'), findsOneWidget);
    expect(find.text('今天第 20 点'), findsOneWidget);
    expectClean(tester);

    // 切到另一天
    await tester.tap(find.text('${other.day}'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('${dayLabel(other)} · ${weekdayLabel(other)}'),
      findsOneWidget,
    );
    expect(find.text('另一天的记录'), findsOneWidget);
    expect(find.text('今天第 9 点'), findsNothing);
    expectClean(tester);

    // 播放这一天
    await tester.tap(find.byTooltip('播放这一天'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(MemoryPlayer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MemoryPlayer),
        matching: find.text('另一天的记录'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('第 1 / 1 篇'), findsOneWidget);
    expectClean(tester);

    await tester.tap(find.byTooltip('结束回顾'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MemoryPlayer), findsNothing);
  });

  testWidgets('日历表：月份切换与回到今天', (tester) async {
    tester.view.physicalSize = const Size(430, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    final now = DateTime.now();

    for (final offset in [0, 40]) {
      final stamp = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      final note = store.create();
      note.title = '$offset 天前';
      note.body = '内容';
      note.createdAt = stamp;
      store.commit(note);
    }

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.byTooltip('切换为日期列表'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('切换为日历表'));
    await tester.pump(const Duration(milliseconds: 400));

    // 上个月（最早那篇引导进入的月份可能不同，这里回到今天再往前）
    await tester.tap(find.byTooltip('回到今天'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('${now.year} 年 ${now.month} 月'), findsOneWidget);

    final prev = DateTime(now.year, now.month - 1);
    await tester.tap(find.byTooltip('上个月'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('${prev.year} 年 ${prev.month} 月'), findsOneWidget);

    await tester.tap(find.byTooltip('下个月'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('${now.year} 年 ${now.month} 月'), findsOneWidget);
    expectClean(tester);
  });
}
