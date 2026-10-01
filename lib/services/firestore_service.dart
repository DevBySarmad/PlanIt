import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_app/models/note_model.dart';
import 'package:todo_app/models/task_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to access your PlanIt data.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('users').doc(_userId).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection('users').doc(_userId).collection('notes');

  Stream<List<TaskModel>> watchTasks() => _tasks
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
            .toList(growable: false),
      );

  Future<String> createTask(TaskModel task) async {
    final reference = _tasks.doc();
    await reference.set(task.toMap());
    return reference.id;
  }

  Future<void> updateTask(TaskModel task) async {
    if (task.id.isEmpty) throw ArgumentError('Task id is required.');
    final data = task.toMap()..remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tasks.doc(task.id).update(data);
  }

  Future<void> setTaskCompleted(String taskId, bool isCompleted) =>
      _tasks.doc(taskId).update({'isCompleted': isCompleted});

  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();

  Stream<List<NoteModel>> watchNotes() => _notes
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromMap(doc.id, doc.data()))
            .toList(growable: false),
      );

  Future<String> createNote(NoteModel note) async {
    final reference = _notes.doc();
    await reference.set(note.toMap());
    return reference.id;
  }

  Future<void> updateNote(NoteModel note) async {
    if (note.id.isEmpty) throw ArgumentError('Note id is required.');
    final data = note.toMap()..remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _notes.doc(note.id).update(data);
  }

  Future<void> deleteNote(String noteId) => _notes.doc(noteId).delete();

  Future<void> saveUserProfile({required String fullName}) =>
      _firestore.collection('users').doc(_userId).set({
        'fullName': fullName.trim(),
        'email': _auth.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
