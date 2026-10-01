import 'package:flutter/material.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/screens/tasks/add_edit_task_screen.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _firestore = FirestoreService();
  late final Stream<List<TaskModel>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = _firestore.watchTasks();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<TaskModel>>(
    stream: _tasksStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _message('Could not load tasks. ${snapshot.error}');
      }
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }
      final tasks = snapshot.data!;
      return CustomScrollView(
        key: const PageStorageKey('all-tasks'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 115),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'All tasks',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${tasks.length} total',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                if (tasks.isEmpty)
                  _message('No tasks yet. Use + to add your first task.')
                else
                  ...tasks.map(_taskRow),
              ]),
            ),
          ),
        ],
      );
    },
  );

  Widget _taskRow(TaskModel task) => Padding(
    key: ValueKey('task-list-${task.id}'),
    padding: const EdgeInsets.only(bottom: 9),
    child: Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(
        color: const Color(0xFF319B71),
        icon: Icons.check_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        color: const Color(0xFFD85C68),
        icon: Icons.delete_outline_rounded,
        alignment: Alignment.centerRight,
      ),
      onDismissed: (direction) async {
        try {
          if (direction == DismissDirection.startToEnd) {
            await _firestore.setTaskCompleted(task.id, true);
          } else {
            await _firestore.deleteTask(task.id);
          }
        } catch (error) {
          _showError('Could not update this task: $error');
        }
      },
      child: TaskCard(
        task: task,
        onChanged: (value) async {
          try {
            await _firestore.setTaskCompleted(task.id, value ?? false);
          } catch (error) {
            _showError('Could not update this task: $error');
          }
        },
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
        ),
      ),
    ),
  );

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: Colors.white),
  );

  Widget _message(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.muted),
      ),
    ),
  );

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
