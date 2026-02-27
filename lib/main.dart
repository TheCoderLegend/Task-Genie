import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
  // Normalize existing stored tasks so the app can safely assume
  // each entry is a Map with keys: 'id', 'text', 'isCompleted'.
  final Box tasksBox = Hive.box('tasksBox');
  for (int i = 0; i < tasksBox.length; i++) {
    final val = tasksBox.getAt(i);
    // Generate a per-iteration unique id using microseconds + index
    final String genId = '${DateTime.now().microsecondsSinceEpoch}_$i';
    if (val is String) {
      tasksBox.putAt(i, {
        'id': genId,
        'text': val,
        'isCompleted': false,false
      });
    } else if (val is Map) {
      final map = Map<String, dynamic>.from(val);
      if (!map.containsKey('text') || map['text'] == null) map['text'] = 'Untitled task';
      if (!map.containsKey('isCompleted')) map['isCompleted'] = false;
      if (!map.containsKey('id') || map['id'] == null) map['id'] = genId;
      tasksBox.putAt(i, map);
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Genie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TaskGenieHome(),
    );
  }
}

class TaskGenieHome extends StatefulWidget {
  const TaskGenieHome({super.key});

  @override
  State<TaskGenieHome> createState() => _TaskGenieHomeState();
}

class _TaskGenieHomeState extends State<TaskGenieHome> {
  final Box tasksBox = Hive.box('tasksBox');
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTask(String task) {
    if (task.trim().isEmpty) return;

    tasksBox.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': task,
      'isCompleted': false,
    });

    _controller.clear();
    Navigator.pop(context);
  }

  void _toggleTask(int index) {
    final task = tasksBox.getAt(index);
    if (task == null) return;

    final currentText = task['text'] ?? '';
    final currentCompleted = task['isCompleted'] == true;

    tasksBox.putAt(index, {
      'id': task['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'text': currentText,
      'isCompleted': !currentCompleted,
    });
  }

  void _deleteTask(int index) {
    tasksBox.deleteAt(index);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Task"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: "Enter your task...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _addTask(_controller.text),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧞 Task Genie"),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: tasksBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                "No tasks yet ✨",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final task = box.getAt(index);
              if (task == null) return const SizedBox.shrink();
              final bool isCompleted = task['isCompleted'] == true;
              final String text = task['text'] ?? '';
              final String id = task['id']?.toString() ?? index.toString();

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteTask(index),
                child: Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: isCompleted,
                      onChanged: (_) => _toggleTask(index),
                    ),
                    title: Text(
                      text,
                      style: TextStyle(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isCompleted
                            ? Theme.of(context).disabledColor
                            : (DefaultTextStyle.of(context).style.color ?? Colors.black),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}