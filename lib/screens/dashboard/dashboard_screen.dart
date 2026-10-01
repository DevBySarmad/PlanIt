import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/models/note_model.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/screens/auth/sign_in_screen.dart';
import 'package:todo_app/screens/notes/add_edit_note_screen.dart';
import 'package:todo_app/screens/tasks/add_edit_task_screen.dart';
import 'package:todo_app/screens/notes/note_list_screen.dart';
import 'package:todo_app/screens/tasks/task_list_screen.dart';
import 'package:todo_app/services/auth_service.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/category_chip.dart';
import 'package:todo_app/widgets/note_card.dart';
import 'package:todo_app/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestore = FirestoreService();
  final _auth = AuthService();
  late final Stream<List<TaskModel>> _tasksStream;
  late final Stream<List<NoteModel>> _notesStream;
  static const _categories = ['All', 'Tasks', 'Notes', 'High Priority'];
  int _selectedCategory = 0;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tasksStream = _firestore.watchTasks();
    _notesStream = _firestore.watchNotes();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _selectedTab,
        children: [
          _buildDashboard(),
          const TaskListScreen(),
          const NoteListScreen(),
          _buildProfile(),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showQuickActions,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: const Icon(Icons.add_rounded, size: 28),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) => setState(() => _selectedTab = index),
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.lilac,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.sticky_note_2_outlined),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profile',
        ),
      ],
    ),
  );

  Widget _buildDashboard() => StreamBuilder<List<TaskModel>>(
    stream: _tasksStream,
    builder: (context, taskSnapshot) {
      if (taskSnapshot.hasError) return _loadError(taskSnapshot.error);
      if (!taskSnapshot.hasData) return _loading();
      final tasks = taskSnapshot.data!;
      return StreamBuilder<List<NoteModel>>(
        stream: _notesStream,
        builder: (context, noteSnapshot) {
          if (noteSnapshot.hasError) return _loadError(noteSnapshot.error);
          if (!noteSnapshot.hasData) return _loading();
          return _dashboardContent(tasks, noteSnapshot.data!);
        },
      );
    },
  );

  Widget _dashboardContent(List<TaskModel> tasks, List<NoteModel> notes) {
    final pending = tasks.where((task) => !task.isCompleted).toList();
    final completed = tasks.length - pending.length;
    final highPriority = pending
        .where((task) => task.priority.toLowerCase() == 'high')
        .toList();
    final todayFocus = [...pending]
      ..sort((a, b) {
        final priorityOrder =
            _priorityRank(b.priority) - _priorityRank(a.priority);
        if (priorityOrder != 0) return priorityOrder;
        return (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999));
      });
    final selectedTasks = _selectedCategory == 3
        ? highPriority
        : todayFocus.take(4).toList();
    final showTasks =
        _selectedCategory == 0 ||
        _selectedCategory == 1 ||
        _selectedCategory == 3;
    final showNotes = _selectedCategory == 0 || _selectedCategory == 2;

    return CustomScrollView(
      key: const PageStorageKey('planit-dashboard'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 115),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 22),
              _buildOverview(pending.length, completed, notes.length),
              const SizedBox(height: 24),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => CategoryChip(
                    label: _categories[index],
                    selected: _selectedCategory == index,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = index),
                  ),
                ),
              ),
              if (showTasks) ...[
                const SizedBox(height: 25),
                _sectionTitle(
                  _selectedCategory == 3 ? 'High priority' : 'Today\'s focus',
                  '${pending.length} pending',
                  onAction: () => setState(() => _selectedTab = 1),
                ),
                const SizedBox(height: 11),
                if (selectedTasks.isEmpty)
                  _emptyState(
                    'You\'re all caught up',
                    'Add a task with the + button to get started.',
                    Icons.task_alt_rounded,
                  )
                else
                  ...selectedTasks.map(_taskRow),
              ],
              if (showNotes) ...[
                const SizedBox(height: 25),
                _sectionTitle(
                  'Recent notes',
                  'See all',
                  onAction: () => setState(() => _selectedTab = 2),
                ),
                const SizedBox(height: 11),
                if (notes.isEmpty)
                  _emptyState(
                    'No notes yet',
                    'Save an idea with the + button.',
                    Icons.sticky_note_2_outlined,
                  )
                else
                  _noteGrid(notes.take(4).toList()),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim().split(' ').first
        : 'there';
    final now = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $name!  👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: () => setState(() => _selectedTab = 3),
          icon: const Icon(Icons.account_circle_outlined),
          color: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildOverview(int pending, int completed, int notes) {
    final totalTasks = pending + completed;
    final progress = totalTasks == 0 ? 0.0 : completed / totalTasks;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your day, at a glance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _statItem('$pending', 'Pending'),
              _statDivider(),
              _statItem('$completed', 'Completed'),
              _statDivider(),
              _statItem('$notes', 'Notes'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            totalTasks == 0
                ? 'Your task progress will appear here'
                : '${(progress * 100).round()}% of your tasks complete',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .84),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .82),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _statDivider() => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withValues(alpha: .28),
  );

  Widget _taskRow(TaskModel task) => Padding(
    key: ValueKey('dashboard-${task.id}'),
    padding: const EdgeInsets.only(bottom: 9),
    child: Dismissible(
      key: ValueKey('dismiss-${task.id}'),
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
      onDismissed: (direction) => _handleDismiss(task, direction),
      child: TaskCard(
        task: task,
        onChanged: (value) => _setCompleted(task, value ?? false),
        onTap: () => _openTask(task),
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

  Future<void> _handleDismiss(
    TaskModel task,
    DismissDirection direction,
  ) async {
    try {
      if (direction == DismissDirection.startToEnd) {
        await _firestore.setTaskCompleted(task.id, true);
      } else {
        await _firestore.deleteTask(task.id);
      }
    } catch (error) {
      _showError('Could not update this task: $error');
    }
  }

  Future<void> _setCompleted(TaskModel task, bool value) async {
    try {
      await _firestore.setTaskCompleted(task.id, value);
    } catch (error) {
      _showError('Could not update this task: $error');
    }
  }

  Widget _noteGrid(List<NoteModel> notes) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: constraints.maxWidth > 540 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 151,
      ),
      itemBuilder: (context, index) =>
          NoteCard(note: notes[index], onTap: () => _openNote(notes[index])),
    ),
  );

  Widget _sectionTitle(String title, String action, {VoidCallback? onAction}) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              action,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _emptyState(String title, String body, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 27),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 100),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.lilac,
                child: Icon(Icons.person_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'PlanIt user',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          leading: const Icon(Icons.logout_rounded, color: AppTheme.primary),
          title: const Text('Sign out'),
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator(color: AppTheme.primary));

  Widget _loadError(Object? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.primary,
            size: 34,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load your PlanIt data.',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Future<void> _showQuickActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lilac,
                  child: Icon(Icons.add_task_rounded, color: AppTheme.primary),
                ),
                title: const Text('Add task'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, 'task'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lilac,
                  child: Icon(Icons.edit_note_rounded, color: AppTheme.primary),
                ),
                title: const Text('Add note'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, 'note'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'task') {
      await _openTask(null);
    } else {
      await _openNote(null);
    }
  }

  Future<void> _openTask(TaskModel? task) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)));
  }

  Future<void> _openNote(NoteModel? note) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)));
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

int _priorityRank(String priority) => switch (priority.toLowerCase()) {
  'high' => 3,
  'medium' => 2,
  _ => 1,
};

String _month(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

String _weekday(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];
