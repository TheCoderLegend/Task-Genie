import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
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

  void _addTask(String task) {
    if (task.trim().isEmpty) return;

    tasksBox.add(task);
    _controller.clear();
    Navigator.pop(context);
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

              return Dismissible(
                key: Key(task.toString() + index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteTask(index),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(task.toString()),
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