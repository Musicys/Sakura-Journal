import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_test/data/note_store.dart';
import 'package:my_test/main.dart';

void main() {
  testWidgets('首次启动是一本空手账', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await NoteStore.open();

    await tester.pumpWidget(YozakuraApp(store: store));
    await tester.pump(const Duration(milliseconds: 700));

    expect(store.total, 0);
    expect(find.text('夜樱手账'), findsOneWidget);
    expect(find.text('第一页，还空着'), findsOneWidget);
  });

  test('新增、修改、删除都会落盘，重启后从缓存读回', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await NoteStore.open();
    expect(store.total, 0);

    // 增
    final note = store.create(paper: 2, mood: 1);
    note.title = '第一篇';
    note.body = '内容';
    store.commit(note);
    await Future<void>.delayed(const Duration(milliseconds: 420));

    final reopened = await NoteStore.open();
    expect(reopened.total, 1);
    expect(reopened.notes.first.title, '第一篇');

    // 改
    final target = reopened.notes.first;
    target.title = '改过了';
    reopened.commit(target);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    expect((await NoteStore.open()).notes.first.title, '改过了');

    // 删
    reopened.remove(target.id);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final cleared = await NoteStore.open();
    expect(cleared.total, 0);
    expect(cleared.isEmpty, isTrue);
  });
}
