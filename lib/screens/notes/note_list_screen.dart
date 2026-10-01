import 'package:flutter/material.dart';
import 'package:todo_app/models/note_model.dart';
import 'package:todo_app/screens/notes/add_edit_note_screen.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/note_card.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final _firestore = FirestoreService();
  late final Stream<List<NoteModel>> _notesStream;

  @override
  void initState() {
    super.initState();
    _notesStream = _firestore.watchNotes();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<NoteModel>>(
    stream: _notesStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _message('Could not load notes. ${snapshot.error}');
      }
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }
      final notes = snapshot.data!;
      return CustomScrollView(
        key: const PageStorageKey('all-notes'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 115),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Notes vault',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${notes.length} saved',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (notes.isEmpty)
                  _message('No notes yet. Use + to capture an idea.')
                else
                  LayoutBuilder(
                    builder: (context, constraints) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notes.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 540 ? 3 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 166,
                      ),
                      itemBuilder: (context, index) => _noteTile(notes[index]),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      );
    },
  );

  Widget _noteTile(NoteModel note) => Dismissible(
    key: ValueKey('note-${note.id}'),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFD85C68),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    ),
    confirmDismiss: (_) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ),
    onDismissed: (_) async {
      try {
        await _firestore.deleteNote(note.id);
      } catch (error) {
        _showError('Could not delete note: $error');
      }
    },
    child: NoteCard(
      note: note,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note))),
    ),
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
