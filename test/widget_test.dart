import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/task_card.dart';

void main() {
  testWidgets('task card displays task and reports completion changes', (
    tester,
  ) async {
    bool? completedValue;
    const task = TaskModel(
      id: 'task-1',
      title: 'Review project plan',
      description: 'Add the final comments',
      tag: 'Work',
      priority: 'High',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TaskCard(
            task: task,
            onChanged: (value) => completedValue = value,
          ),
        ),
      ),
    );

    expect(find.text('Review project plan'), findsOneWidget);
    expect(find.text('Add the final comments'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    expect(completedValue, isTrue);
  });
}
