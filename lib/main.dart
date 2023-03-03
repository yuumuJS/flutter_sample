import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './notifiers/todo_notifier.dart';
import './../models/todo.dart';
import 'package:uuid/uuid.dart';

final searchTextProvider = StateProvider<String>((ref) => '');

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: const TopPage(),
    );
  }
}

final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final searchText = ref.watch(searchTextProvider);
  final todos = ref.watch(todoProvider);

  if (searchText == '') {
    return todos.toList();
  }
  return todos.where((t) => t.text.contains(searchText)).toList();
});

class TopPage extends ConsumerStatefulWidget {
  const TopPage({Key? key}) : super(key: key);

  @override
  TopPageState createState() => TopPageState();
}

class TopPageState extends ConsumerState<TopPage> {
  late TextEditingController _controller;

  bool _visible = false;

  @override
  void initState() {
    _controller = TextEditingController(text: ref.read(searchTextProvider));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Todo> todos = ref.watch(todoProvider);
    final filterTodos = ref.watch(filteredTodosProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (todos.isEmpty)
              Align(
                alignment: const Alignment(0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Image.asset('images/empty.png'),
                    ),
                    const Text('Add reminder!'),
                  ],
                ),
              ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  padding: const EdgeInsets.all(6),
                  children: [
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Visibility(
                              visible: _visible,
                              maintainAnimation: true,
                              maintainState: true,
                              maintainSize: true,
                              child: TextField(
                                cursorColor: Colors.deepPurpleAccent,
                                decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.deepPurple),
                                )),
                                autofocus: true,
                                controller: _controller,
                                // 入力されたテキストの値を受け取る（valueが入力されたテキスト）
                                onChanged: (value) => {
                                  ref.watch(searchTextProvider.notifier).state =
                                      value,
                                },
                              )),
                        ),
                        IconButton(
                          padding: const EdgeInsets.all(0.0),
                          icon: const Icon(Icons.search,
                              color: Colors.deepPurple, size: 36),
                          onPressed: () {
                            setState(() {
                              _visible = !_visible;
                            });
                          },
                        ),
                      ],
                    ),
                    if (todos.length != filterTodos.length ||
                        ref.watch(searchTextProvider.notifier).state.isNotEmpty)
                      (filterTodos.isEmpty
                          ? const Text('検索結果に一致するものはありません')
                          : Text('${filterTodos.length}件表示中')),
                    for (final todo in filterTodos)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) {
                              // 遷移先の画面としてリスト追加画面を指定
                              return RemindEditPage(id: todo.id);
                            }),
                          );
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(todo.text),
                              Checkbox(
                                value: todo.done,
                                onChanged: (value) => ref
                                    .read(todoProvider.notifier)
                                    .toggleDone(todo.id),
                              ),
                            ]),
                      )
                  ],
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              // 遷移先の画面としてリスト追加画面を指定
              return const RemindEditPage();
            }),
          );
        },
      ),
    );
  }
}

class RemindEditPage extends ConsumerStatefulWidget {
  const RemindEditPage({Key? key, this.id}) : super(key: key);
  final String? id;

  @override
  RemindEditPageState createState() => RemindEditPageState();
}

class RemindEditPageState extends ConsumerState<RemindEditPage> {
  late String text;
  late String memo;
  late String label;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    List<Todo> todos = ref.watch(todoProvider);
    setState(() {
      text = widget.id != null
          ? todos.firstWhere((element) => element.id == widget.id).text
          : '';
      memo = (widget.id != null
          ? todos.firstWhere((element) => element.id == widget.id).memo
          : '')!;
      label = (widget.id != null
          ? todos.firstWhere((element) => element.id == widget.id).label
          : '')!;
    });
  }

  // データを元に表示するWidget
  @override
  Widget build(BuildContext context) {
    const uuid = Uuid();

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            // "pop"で前の画面に戻る
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('詳細'),
        centerTitle: true,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (widget.id == null) {
                final newTodo = Todo(
                    id: uuid.v4(),
                    text: text,
                    memo: memo,
                    label: label,
                    done: false);
                ref.read(todoProvider.notifier).add(newTodo);
              } else {
                final editTodo = Todo(
                    id: widget.id ?? '',
                    text: text,
                    memo: memo,
                    label: label,
                    done: false);
                ref.read(todoProvider.notifier).edit(editTodo);
              }

              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0),
            ),
            child: const Text(
              '完了',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SizedBox(height: 8),
          // テキスト入力
          const Text('タイトル'),
          TextField(
            controller: TextEditingController(text: text),
            // 入力されたテキストの値を受け取る（valueが入力されたテキスト）
            onChanged: (String value) {
              text = value;
            },
          ),
          const SizedBox(height: 8),
          const Text('メモ'),
          TextField(
            controller: TextEditingController(text: memo),
            // 入力されたテキストの値を受け取る（valueが入力されたテキスト）
            onChanged: (String value) {
              memo = value;
            },
          ),
          const SizedBox(height: 8),
          const Text('ラベル'),
          TextField(
            controller: TextEditingController(text: label),
            // 入力されたテキストの値を受け取る（valueが入力されたテキスト）
            onChanged: (String value) {
              label = value;
            },
          ),
          SizedBox(
            width: double.infinity,
            child: widget.id != null
                ? ElevatedButton(
                    onPressed: () {
                      if (widget.id == null) return;
                      ref.read(todoProvider.notifier).remove(widget.id ?? '');
                      Navigator.of(context).pop();
                    },
                    child:
                        const Text('削除', style: TextStyle(color: Colors.white)),
                  )
                : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
