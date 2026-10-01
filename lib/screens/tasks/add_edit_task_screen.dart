import 'package:flutter/material.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/custom_button.dart';
import 'package:todo_app/widgets/custom_textfield.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, this.task});

  final TaskModel? task;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _subtasksController = TextEditingController();
  final _firestore = FirestoreService();
  String _priority = 'Medium';
  DateTime? _dueAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _tagController.text = task.tag;
      _subtasksController.text = task.subtasks.join(', ');
      _priority = task.priority;
      _dueAt = task.dueAt;
    } else {
      _tagController.text = 'Personal';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _subtasksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final task = TaskModel(
      id: widget.task?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tag: _tagController.text.trim().isEmpty
          ? 'Personal'
          : _tagController.text.trim(),
      priority: _priority,
      dueAt: _dueAt,
      subtasks: _subtasksController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      isCompleted: widget.task?.isCompleted ?? false,
      createdAt: widget.task?.createdAt,
    );
    try {
      if (widget.task == null) {
        await _firestore.createTask(task);
      } else {
        await _firestore.updateTask(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save task: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) setState(() => _dueAt = selected);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.task == null ? 'Add task' : 'Edit task')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Task name',
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Enter a task name.' : null,
            ),
            const SizedBox(height: 13),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 13),
            CustomTextField(controller: _tagController, label: 'Category tag'),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const ['Low', 'Medium', 'High']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _priority = value ?? 'Medium'),
            ),
            const SizedBox(height: 13),
            CustomTextField(
              controller: _subtasksController,
              label: 'Subtasks',
              hint: 'Separate subtasks with commas',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _dueAt == null ? 'Set due date' : _formatDate(_dueAt!),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_dueAt != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear due date',
                    onPressed: () => setState(() => _dueAt = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 25),
            CustomButton(
              label: widget.task == null ? 'Create task' : 'Save changes',
              isLoading: _isSaving,
              onPressed: _save,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
