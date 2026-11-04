import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_test/data/note_store.dart';
import 'package:my_test/main.dart';
import 'package:my_test/screens/note_editor.dart';

void main() {
  Future<NoteStore> boot() async {
    SharedPreferences.setMockInitialValues({});
    return NoteStore.open();
  }

  void expectClean(WidgetTester tester) {
    final error = tester.takeException();
    if (error is FlutterError) {
      debugPrint(error.toStringDeep());
    } else if (error != null) {
      debugPrint('$error');
    }
    expect(error, isNull, reason: '不应出现布局溢出或渲染异常');
  }

  testWidgets('宽屏：空手账 → 新建 → 编辑 → 删除', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    // 空手账
    expect(store.total, 0);
    expect(find.text('第一页，还空着'), findsOneWidget);
    expect(find.text('今天，想留下什么呢'), findsOneWidget);
    expectClean(tester);

    // 新建
    await tester.tap(find.text('写新的一页'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(store.total, 1);
    expect(find.byKey(const ValueKey('note-title')), findsOneWidget);

    // 编辑
    await tester.enterText(find.byKey(const ValueKey('note-title')), '第一页手记');
    await tester.enterText(find.byKey(const ValueKey('note-body')), '今天开始写手账。');
    await tester.pump(const Duration(milliseconds: 700));
    expect(store.notes.first.title, '第一页手记');
    expect(find.text('第一页手记'), findsWidgets);

    // 换纸与心情
    await tester.tap(find.text('憂').first);
    await tester.pump(const Duration(milliseconds: 400));
    expectClean(tester);

    // 删除
    await tester.tap(find.byTooltip('删除这一页'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('删除'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.total, 0);
    expect(find.text('第一页，还空着'), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('窄屏：空状态 → 写第一页 → 返回列表', (tester) async {
    tester.view.physicalSize = const Size(420, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('第一页，还空着'), findsOneWidget);
    expectClean(tester);

    await tester.tap(find.text('写第一页'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('note-body')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('note-title')), '手机上的第一篇');
    await tester.pump(const Duration(milliseconds: 600));
    expect(store.total, 1);

    await tester.tap(find.byTooltip('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('手机上的第一篇'), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('带图片的手记在宽屏与窄屏都能正常排版', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    final note = store.create();
    note.title = '有图的一页';
    note.images.addAll(['a.jpg', 'b.jpg', 'c.jpg']);
    store.commit(note);

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('有图的一页').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(NotePhoto), findsNWidgets(3));
    expectClean(tester);

    // 窄屏重新进来一次，验证 Wrap 换行
    tester.view.physicalSize = const Size(400, 880);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('有图的一页').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(NotePhoto), findsNWidgets(3));
    expectClean(tester);
  });

  testWidgets('搜索无结果时显示提示', (tester) async {
    tester.view.physicalSize = const Size(420, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await boot();
    store.create(title: '樱花', body: '春天');
    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('樱花'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '不存在的关键词');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('没有找到'), findsOneWidget);
    expectClean(tester);
  });
}
