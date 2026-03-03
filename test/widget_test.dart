import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_genie/main.dart';

void main() {
  group('TaskGenieHome Widget Tests', () {
    late Box tasksBox;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      // Delete box if it exists and create fresh one for each test
      if (Hive.isBoxOpen('tasksBox')) {
        await Hive.box('tasksBox').clear();
        await Hive.box('tasksBox').close();
      }

      tasksBox = await Hive.openBox('tasksBox');
    });

    tearDown(() async {
      await tasksBox.clear();
      await tasksBox.close();
    });

    testWidgets('MyApp creates MaterialApp with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'Task Genie');
      expect(app.debugShowCheckedModeBanner, false);
    });

    testWidgets('Shows empty state when no tasks exist', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet ✨'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Shows app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('🧞 Task Genie'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Shows floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Opens add task dialog when FAB is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Can cancel add task dialog', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Task'), findsNothing);
    });

    testWidgets('Adding a task creates new task in list', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter task text
      await tester.enterText(find.byType(TextField), 'Test Task');
      await tester.pumpAndSettle();

      // Add task
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify task appears
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('No tasks yet ✨'), findsNothing);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Does not add empty task', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to add empty task
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should still show empty state
      expect(find.text('No tasks yet ✨'), findsOneWidget);
      expect(tasksBox.length, 0);
    });

    testWidgets('Does not add whitespace-only task', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet ✨'), findsOneWidget);
      expect(tasksBox.length, 0);
    });

    testWidgets('Can toggle task completion status', (WidgetTester tester) async {
      // Pre-populate with a task
      await tasksBox.add({
        'id': '123',
        'text': 'Test Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Find and tap checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      Checkbox checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, false);

      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify task is now completed
      checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, true);

      final task = tasksBox.getAt(0);
      expect(task['isCompleted'], true);
    });

    testWidgets('Completed tasks show strikethrough text', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Completed Task',
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(
        find.text('Completed Task'),
      );
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('Incomplete tasks have no text decoration', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Incomplete Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(
        find.text('Incomplete Task'),
      );
      expect(textWidget.style?.decoration, TextDecoration.none);
    });

    testWidgets('Can delete task by swiping', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Task to Delete',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Task to Delete'), findsOneWidget);

      // Swipe to dismiss
      await tester.drag(find.byType(Dismissible), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(find.text('Task to Delete'), findsNothing);
      expect(find.text('No tasks yet ✨'), findsOneWidget);
      expect(tasksBox.length, 0);
    });

    testWidgets('Displays multiple tasks', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '1',
        'text': 'First Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await tasksBox.add({
        'id': '2',
        'text': 'Second Task',
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await tasksBox.add({
        'id': '3',
        'text': 'Third Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('First Task'), findsOneWidget);
      expect(find.text('Second Task'), findsOneWidget);
      expect(find.text('Third Task'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('Shows creation date for tasks', (WidgetTester tester) async {
      final testDate = DateTime(2024, 3, 15, 14, 30);
      await tasksBox.add({
        'id': '123',
        'text': 'Test Task',
        'isCompleted': false,
        'createdAt': testDate.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('15/3/2024'), findsOneWidget);
      expect(find.textContaining('14:30'), findsOneWidget);
    });

    testWidgets('Handles null task gracefully', (WidgetTester tester) async {
      // Manually add null to box
      await tasksBox.add(null);

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Should show empty state since null task is hidden
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Handles task with missing text field', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Should display empty text
      expect(find.text(''), findsWidgets);
    });

    testWidgets('Handles task with missing createdAt field', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Task without date',
        'isCompleted': false,
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Task without date'), findsOneWidget);
      expect(find.textContaining('Created:'), findsOneWidget);
    });

    testWidgets('Toggle updates correct task in multi-task list', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '1',
        'text': 'First Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await tasksBox.add({
        'id': '2',
        'text': 'Second Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Toggle second task
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Verify only second task is completed
      final task1 = tasksBox.getAt(0);
      final task2 = tasksBox.getAt(1);
      expect(task1['isCompleted'], false);
      expect(task2['isCompleted'], true);
    });

    testWidgets('Can toggle task from completed back to incomplete', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Test Task',
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final task = tasksBox.getAt(0);
      expect(task['isCompleted'], false);
    });

    testWidgets('Dismissible has correct background color', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Test Task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      final background = dismissible.background as Container;
      expect(background.color, Colors.red);
    });

    testWidgets('Added task has all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Task');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final task = tasksBox.getAt(0);
      expect(task['id'], isNotNull);
      expect(task['text'], 'New Task');
      expect(task['isCompleted'], false);
      expect(task['createdAt'], isNotNull);

      // Verify createdAt is valid ISO8601
      final parsedDate = DateTime.tryParse(task['createdAt']);
      expect(parsedDate, isNotNull);
    });

    testWidgets('Task IDs are unique', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Add first task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Task 1');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Small delay to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 10));

      // Add second task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Task 2');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final task1 = tasksBox.getAt(0);
      final task2 = tasksBox.getAt(1);
      expect(task1['id'], isNot(equals(task2['id'])));
    });

    testWidgets('Long task text is displayed correctly', (WidgetTester tester) async {
      const longText = 'This is a very long task description that should be displayed properly in the list tile without causing any overflow issues';

      await tasksBox.add({
        'id': '123',
        'text': longText,
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('TextField clears after adding task', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test Task');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Open dialog again
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // TextField should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Handles rapid task additions', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Task $i');
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
      }

      expect(tasksBox.length, 5);
      expect(find.text('Task 0'), findsOneWidget);
      expect(find.text('Task 4'), findsOneWidget);
    });
  });

  group('Date Formatting Tests', () {
    testWidgets('Formats valid date correctly', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      if (Hive.isBoxOpen('tasksBox')) {
        await Hive.box('tasksBox').clear();
        await Hive.box('tasksBox').close();
      }

      final box = await Hive.openBox('tasksBox');

      final testDate = DateTime(2024, 12, 25, 9, 5);
      await box.add({
        'id': '123',
        'text': 'Test',
        'isCompleted': false,
        'createdAt': testDate.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('25/12/2024'), findsOneWidget);
      expect(find.textContaining('9:05'), findsOneWidget);

      await box.clear();
      await box.close();
    });

    testWidgets('Handles invalid date string', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      if (Hive.isBoxOpen('tasksBox')) {
        await Hive.box('tasksBox').clear();
        await Hive.box('tasksBox').close();
      }

      final box = await Hive.openBox('tasksBox');

      await box.add({
        'id': '123',
        'text': 'Test',
        'isCompleted': false,
        'createdAt': 'invalid-date',
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Should display task but with empty date
      expect(find.text('Test'), findsOneWidget);

      await box.clear();
      await box.close();
    });

    testWidgets('Formats single-digit minutes with leading zero', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      if (Hive.isBoxOpen('tasksBox')) {
        await Hive.box('tasksBox').clear();
        await Hive.box('tasksBox').close();
      }

      final box = await Hive.openBox('tasksBox');

      final testDate = DateTime(2024, 1, 1, 23, 7);
      await box.add({
        'id': '123',
        'text': 'Test',
        'isCompleted': false,
        'createdAt': testDate.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('23:07'), findsOneWidget);

      await box.clear();
      await box.close();
    });

    testWidgets('Formats midnight correctly', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      if (Hive.isBoxOpen('tasksBox')) {
        await Hive.box('tasksBox').clear();
        await Hive.box('tasksBox').close();
      }

      final box = await Hive.openBox('tasksBox');

      final testDate = DateTime(2024, 6, 15, 0, 0);
      await box.add({
        'id': '123',
        'text': 'Test',
        'isCompleted': false,
        'createdAt': testDate.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('0:00'), findsOneWidget);

      await box.clear();
      await box.close();
    });
  });

  group('Edge Cases and Regression Tests', () {
    late Box tasksBox;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      if (Hive.isBoxOpen('tasksBox')) {
        await Hive.box('tasksBox').clear();
        await Hive.box('tasksBox').close();
      }

      tasksBox = await Hive.openBox('tasksBox');
    });

    tearDown(() async {
      await tasksBox.clear();
      await tasksBox.close();
    });

    testWidgets('Special characters in task text are displayed correctly', (WidgetTester tester) async {
      const specialText = 'Test @#\$%^&*()_+-=[]{}|;\':",.<>?/~`';

      await tasksBox.add({
        'id': '123',
        'text': specialText,
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text(specialText), findsOneWidget);
    });

    testWidgets('Unicode and emoji in task text work correctly', (WidgetTester tester) async {
      const emojiText = '🎉 Celebrate! 你好 مرحبا';

      await tasksBox.add({
        'id': '123',
        'text': emojiText,
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text(emojiText), findsOneWidget);
    });

    testWidgets('Handles task with isCompleted as non-boolean', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': 'Test',
        'isCompleted': 'true', // String instead of bool
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Should handle gracefully without crashing
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('Task with very old date is formatted correctly', (WidgetTester tester) async {
      final oldDate = DateTime(2000, 1, 1, 0, 0);
      await tasksBox.add({
        'id': '123',
        'text': 'Old Task',
        'isCompleted': false,
        'createdAt': oldDate.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('1/1/2000'), findsOneWidget);
    });

    testWidgets('Task with future date is formatted correctly', (WidgetTester tester) async {
      final futureDate = DateTime(2030, 12, 31, 23, 59);
      await tasksBox.add({
        'id': '123',
        'text': 'Future Task',
        'isCompleted': false,
        'createdAt': futureDate.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('31/12/2030'), findsOneWidget);
      expect(find.textContaining('23:59'), findsOneWidget);
    });

    testWidgets('Empty string task text is handled', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '123',
        'text': '',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Task should be displayed even with empty text
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('Deleting middle task from list maintains correct order', (WidgetTester tester) async {
      await tasksBox.add({
        'id': '1',
        'text': 'First',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await tasksBox.add({
        'id': '2',
        'text': 'Second',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await tasksBox.add({
        'id': '3',
        'text': 'Third',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Delete second task
      final dismissibles = find.byType(Dismissible);
      await tester.drag(dismissibles.at(1), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      expect(find.text('Third'), findsOneWidget);
      expect(tasksBox.length, 2);
    });

    testWidgets('Widget disposes controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // No assertion errors should occur
    });

    testWidgets('Handles task ID as null', (WidgetTester tester) async {
      await tasksBox.add({
        'id': null,
        'text': 'Task without ID',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Task without ID'), findsOneWidget);
    });

    testWidgets('Handles task ID as number instead of string', (WidgetTester tester) async {
      await tasksBox.add({
        'id': 12345,
        'text': 'Task with numeric ID',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Task with numeric ID'), findsOneWidget);
    });
  });
}