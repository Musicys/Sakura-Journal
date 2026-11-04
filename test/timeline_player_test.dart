import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_test/data/note_store.dart';
import 'package:my_test/main.dart';
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

  /// 造三篇：前天、昨天、今天各一篇
  List<String> seed(NoteStore store) {
    final now = DateTime.now();
    final titles = ['前天的雨', '昨天的咖啡', '今天的花'];

    for (var i = 0; i < 3; i++) {
      final stamp = DateTime(
        now.year,
        now.month,
        now.day,
        10 + i,
      ).subtract(Duration(days: 2 - i));
      final note = store.create();
      note.title = titles[i];
      note.body = '${titles[i]}，写在手账里的一点点记录。';
      note.createdAt = stamp;
      store.commit(note);
    }
    return titles;
  }

  testWidgets('时间轴按日期分组，可点开某一天', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    final titles = seed(store);

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    // 切到日期列表
    await tester.tap(find.byTooltip('切换为日期列表'));
    await tester.pump(const Duration(milliseconds: 400));

    final today = DateTime.now();
    expect(find.text(dayLabel(today)), findsOneWidget);
    expect(
      find.text(dayLabel(today.subtract(const Duration(days: 2)))),
      findsOneWidget,
    );
    expect(find.textContaining('今天 · 1 篇'), findsOneWidget);
    for (final title in titles) {
      expect(find.text(title), findsOneWidget);
    }
    expectClean(tester);

    // 点条目进入编辑
    await tester.tap(find.text('昨天的咖啡'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('note-title')), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('回顾播放：自动翻页、手动切换、结束', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    seed(store);

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.byTooltip('回顾播放'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final player = find.byType(MemoryPlayer);
    expect(player, findsOneWidget);
    expect(
      find.descendant(of: player, matching: find.text('前天的雨')),
      findsOneWidget,
    );
    expect(find.textContaining('第 1 / 3 篇'), findsOneWidget);

    // 6 秒后自动翻到第二篇
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 420));
    expect(
      find.descendant(of: player, matching: find.text('昨天的咖啡')),
      findsOneWidget,
    );
    expect(find.textContaining('第 2 / 3 篇'), findsOneWidget);

    // 手动下一篇
    await tester.tap(find.byTooltip('下一篇'));
    await tester.pump(const Duration(milliseconds: 420));
    expect(
      find.descendant(of: player, matching: find.text('今天的花')),
      findsOneWidget,
    );

    // 最后一篇再往后 → 结束
    await tester.tap(find.byTooltip('下一篇'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('回顾到这里了'), findsOneWidget);
    expectClean(tester);

    // 关闭
    await tester.tap(find.byTooltip('结束回顾'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MemoryPlayer), findsNothing);
    expectClean(tester);
  });

  testWidgets('按下暂停后不再自动翻页', (tester) async {
    tester.view.physicalSize = const Size(420, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    seed(store);

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.byTooltip('回顾播放'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('暂停'));
    await tester.pump(const Duration(seconds: 8));

    expect(find.textContaining('第 1 / 3 篇'), findsOneWidget);
    expectClean(tester);
  });
}
