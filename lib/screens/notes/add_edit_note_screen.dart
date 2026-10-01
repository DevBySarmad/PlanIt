import 'package:flutter/material.dart';
import 'package:todo_app/models/note_model.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/custom_button.dart';
import 'package:todo_app/widgets/custom_textfield.dart';

class AddEditNoteScreen extends StatefulWidget {
  const AddEditNoteScreen({super.key, this.note});

  final NoteModel? note;

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _firestore = FirestoreService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _tagController.text = note.tag;
    } else {
      _tagController.text = 'Ideas';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final note = NoteModel(
      id: widget.note?.id ?? '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tag: _tagController.text.trim().isEmpty
          ? 'Ideas'
          : _tagController.text.trim(),
      createdAt: widget.note?.createdAt,
    );
    try {
      if (widget.note == null) {
        await _firestore.createNote(note);
      } else {
        await _firestore.updateNote(note);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save note: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.note == null ? 'New note' : 'Edit note')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter a note title.'
                  : null,
            ),
            const SizedBox(height: 13),
            CustomTextField(
              controller: _contentController,
              label: 'Note',
              hint: 'Markdown text is saved as written.',
              minLines: 8,
              maxLines: 16,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Write something in your note.'
                  : null,
            ),
            const SizedBox(height: 13),
            CustomTextField(controller: _tagController, label: 'Category tag'),
            const SizedBox(height: 25),
            CustomButton(
              label: widget.note == null ? 'Save note' : 'Save changes',
              isLoading: _isSaving,
              onPressed: _save,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your notes are private to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
