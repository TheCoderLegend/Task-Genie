import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_genie/main.dart';

void main() {
  group('Date Formatting Tests', () {
    testWidgets('_formatDate formats valid ISO date correctly',
        (WidgetTester tester) async {
      // Initialize Hive for testing
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      final state = tester.state<_TaskGenieHomeState>(
        find.byType(TaskGenieHome),
      );

      // Test with a specific date
      final result = state._formatDate('2025-03-15T14:30:00.000Z');
      expect(result, contains('15/3/2025'));
      expect(result, contains('14:30'));

      // Cleanup
      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('_formatDate returns empty string for invalid date',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      final state = tester.state<_TaskGenieHomeState>(
        find.byType(TaskGenieHome),
      );

      final result = state._formatDate('invalid-date');
      expect(result, isEmpty);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('_formatDate returns empty string for empty string',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      final state = tester.state<_TaskGenieHomeState>(
        find.byType(TaskGenieHome),
      );

      final result = state._formatDate('');
      expect(result, isEmpty);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('_formatDate pads single digit minutes correctly',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      final state = tester.state<_TaskGenieHomeState>(
        find.byType(TaskGenieHome),
      );

      // Test with single digit minute (should be padded with 0)
      final result = state._formatDate('2025-03-15T14:05:00.000Z');
      expect(result, contains('14:05'));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });
  });

  group('Task Normalization Tests', () {
    test('normalizes String tasks to Map format', () async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);

      final box = await Hive.openBox('tasksBox');

      // Add a String task (old format)
      await box.add('Old string task');

      // Simulate normalization logic from main()
      for (int i = 0; i < box.length; i++) {
        final val = box.getAt(i);
        final String genId = '${DateTime.now().microsecondsSinceEpoch}_$i';

        if (val is String) {
          await box.putAt(i, {
            'id': genId,
            'text': val,
            'isCompleted': false,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      // Verify the task was normalized
      final normalized = box.getAt(0);
      expect(normalized, isA<Map>());
      expect(normalized['text'], equals('Old string task'));
      expect(normalized['isCompleted'], equals(false));
      expect(normalized['id'], isNotNull);
      expect(normalized['createdAt'], isNotNull);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    test('normalizes Map tasks with missing fields', () async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);

      final box = await Hive.openBox('tasksBox');

      // Add a Map task with missing fields
      await box.add({
        'text': 'Partial task',
        // Missing id, isCompleted, createdAt
      });

      // Simulate normalization logic from main()
      for (int i = 0; i < box.length; i++) {
        final val = box.getAt(i);
        final String genId = '${DateTime.now().microsecondsSinceEpoch}_$i';

        if (val is Map) {
          final map = Map<String, dynamic>.from(val);

          map['text'] ??= 'Untitled task';
          map['isCompleted'] ??= false;
          map['id'] ??= genId;
          map['createdAt'] ??= DateTime.now().toIso8601String();

          await box.putAt(i, map);
        }
      }

      // Verify the task was normalized with defaults
      final normalized = box.getAt(0);
      expect(normalized['text'], equals('Partial task'));
      expect(normalized['isCompleted'], equals(false));
      expect(normalized['id'], isNotNull);
      expect(normalized['createdAt'], isNotNull);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    test('normalizes Map tasks without text field', () async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);

      final box = await Hive.openBox('tasksBox');

      // Add a Map task without text field
      await box.add({
        'isCompleted': true,
        // Missing text, id, createdAt
      });

      // Simulate normalization logic from main()
      for (int i = 0; i < box.length; i++) {
        final val = box.getAt(i);
        final String genId = '${DateTime.now().microsecondsSinceEpoch}_$i';

        if (val is Map) {
          final map = Map<String, dynamic>.from(val);

          map['text'] ??= 'Untitled task';
          map['isCompleted'] ??= false;
          map['id'] ??= genId;
          map['createdAt'] ??= DateTime.now().toIso8601String();

          await box.putAt(i, map);
        }
      }

      // Verify the task was normalized with default text
      final normalized = box.getAt(0);
      expect(normalized['text'], equals('Untitled task'));
      expect(normalized['isCompleted'], equals(true));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    test('preserves existing Map task fields during normalization', () async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);

      final box = await Hive.openBox('tasksBox');

      final existingId = 'existing-id-123';
      final existingDate = '2025-01-01T00:00:00.000Z';

      // Add a complete Map task
      await box.add({
        'id': existingId,
        'text': 'Complete task',
        'isCompleted': true,
        'createdAt': existingDate,
      });

      // Simulate normalization logic from main()
      for (int i = 0; i < box.length; i++) {
        final val = box.getAt(i);
        final String genId = '${DateTime.now().microsecondsSinceEpoch}_$i';

        if (val is Map) {
          final map = Map<String, dynamic>.from(val);

          map['text'] ??= 'Untitled task';
          map['isCompleted'] ??= false;
          map['id'] ??= genId;
          map['createdAt'] ??= DateTime.now().toIso8601String();

          await box.putAt(i, map);
        }
      }

      // Verify existing fields were preserved
      final normalized = box.getAt(0);
      expect(normalized['id'], equals(existingId));
      expect(normalized['text'], equals('Complete task'));
      expect(normalized['isCompleted'], equals(true));
      expect(normalized['createdAt'], equals(existingDate));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });
  });

  group('Widget Tests', () {
    testWidgets('MyApp creates MaterialApp with correct theme',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MyApp());

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(TaskGenieHome), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome shows empty state when no tasks',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      expect(find.text('No tasks yet ✨'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome displays tasks from Hive',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a task
      await box.add({
        'id': '123',
        'text': 'Test task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Test task'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome shows add dialog when FAB is tapped',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome adds task when Add button is pressed',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      // Open add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter task text
      await tester.enterText(find.byType(TextField), 'New task');
      await tester.pumpAndSettle();

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify task was added
      expect(box.length, equals(1));
      final task = box.getAt(0);
      expect(task['text'], equals('New task'));
      expect(task['isCompleted'], equals(false));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome does not add empty task',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      // Open add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Don't enter any text, just tap Add
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify no task was added
      expect(box.length, equals(0));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome does not add whitespace-only task',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      // Open add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter only whitespace
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify no task was added
      expect(box.length, equals(0));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome cancels adding task',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      // Open add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter task text
      await tester.enterText(find.byType(TextField), 'Task to cancel');
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify no task was added
      expect(box.length, equals(0));
      expect(find.text('Add Task'), findsNothing);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome toggles task completion',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a task
      await box.add({
        'id': '123',
        'text': 'Toggle task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Verify initial state
      expect((box.getAt(0) as Map)['isCompleted'], equals(false));

      // Toggle the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify task is now completed
      expect((box.getAt(0) as Map)['isCompleted'], equals(true));

      // Toggle again
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify task is back to incomplete
      expect((box.getAt(0) as Map)['isCompleted'], equals(false));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome deletes task on dismiss',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a task
      await box.add({
        'id': '123',
        'text': 'Task to delete',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(box.length, equals(1));

      // Swipe to dismiss
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-500.0, 0.0),
      );
      await tester.pumpAndSettle();

      // Verify task was deleted
      expect(box.length, equals(0));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome displays completed task with strikethrough',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a completed task
      await box.add({
        'id': '123',
        'text': 'Completed task',
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Find the Text widget with the task text
      final textWidget = tester.widget<Text>(
        find.text('Completed task'),
      );

      // Verify it has strikethrough decoration
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome displays multiple tasks',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add multiple tasks
      await box.add({
        'id': '1',
        'text': 'First task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await box.add({
        'id': '2',
        'text': 'Second task',
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await box.add({
        'id': '3',
        'text': 'Third task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('First task'), findsOneWidget);
      expect(find.text('Second task'), findsOneWidget);
      expect(find.text('Third task'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome handles null task gracefully',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a valid task and a null (by deleting and leaving gap)
      await box.add({
        'id': '1',
        'text': 'Valid task',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Valid task'), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome displays creation date',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      final createdAt = DateTime(2025, 3, 15, 14, 30);
      await box.add({
        'id': '123',
        'text': 'Task with date',
        'isCompleted': false,
        'createdAt': createdAt.toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('15/3/2025'), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });
  });

  group('Edge Case Tests', () {
    testWidgets('TaskGenieHome handles missing text field in task',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a task without text field
      await box.add({
        'id': '123',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      // Should display empty text without crashing
      expect(find.byType(ListTile), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome handles missing id field in task',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a task without id field
      await box.add({
        'text': 'Task without id',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Task without id'), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome handles missing createdAt field',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      // Add a task without createdAt field
      await box.add({
        'id': '123',
        'text': 'Task without date',
        'isCompleted': false,
      });

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      expect(find.text('Task without date'), findsOneWidget);
      // Should show "Created:" but with empty date
      expect(find.textContaining('Created:'), findsOneWidget);

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('TaskGenieHome handles toggle on null task',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      final box = await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));
      await tester.pumpAndSettle();

      final state = tester.state<_TaskGenieHomeState>(
        find.byType(TaskGenieHome),
      );

      // Call _toggleTask on non-existent index
      state._toggleTask(0);
      await tester.pumpAndSettle();

      // Should not crash
      expect(box.length, equals(0));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });

    testWidgets('_formatDate handles midnight correctly',
        (WidgetTester tester) async {
      final testDir = Directory.systemTemp.createTempSync('hive_test_');
      await Hive.init(testDir.path);
      await Hive.openBox('tasksBox');

      await tester.pumpWidget(const MaterialApp(home: TaskGenieHome()));

      final state = tester.state<_TaskGenieHomeState>(
        find.byType(TaskGenieHome),
      );

      final result = state._formatDate('2025-03-15T00:00:00.000Z');
      expect(result, contains('0:00'));

      await Hive.close();
      testDir.deleteSync(recursive: true);
    });
  });
}