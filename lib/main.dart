import 'package:flutter/material.dart';

import 'data/media_store.dart';
import 'data/note_store.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStore.init();
  final store = await NoteStore.open();
  runApp(YozakuraApp(store: store));
}

class YozakuraApp extends StatelessWidget {
  const YozakuraApp({super.key, required this.store});

  final NoteStore store;

  @override
  Widget build(BuildContext context) {
    // 作用域必须在 MaterialApp 之上，push 出的编辑页才能取到仓库
    return NotesScope(
      store: store,
      child: MaterialApp(
        title: '夜樱手账',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
