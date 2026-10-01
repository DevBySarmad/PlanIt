import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:todo_app/screens/splash/splash_screen.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    const expectedProjectId = 'planit-d7d7b';
    const expectedProjectNumber = '68333046302';
    final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
    if (firebaseOptions.projectId != expectedProjectId ||
        firebaseOptions.messagingSenderId != expectedProjectNumber) {
      throw StateError(
        'PlanIt expected Firebase project $expectedProjectId '
        '($expectedProjectNumber), but options target '
        '${firebaseOptions.projectId} (${firebaseOptions.messagingSenderId}).',
      );
    }
    final app = await Firebase.initializeApp(options: firebaseOptions);
    if (app.options.projectId != expectedProjectId ||
        app.options.messagingSenderId != expectedProjectNumber) {
      throw StateError(
        'Firebase initialized for ${app.options.projectId} '
        '(${app.options.messagingSenderId}), not '
        '$expectedProjectId ($expectedProjectNumber).',
      );
    }
    debugPrint(
      'PlanIt connected to Firebase project $expectedProjectId '
      '(number $expectedProjectNumber).',
    );
  } catch (error, stackTrace) {
    debugPrint('PlanIt Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'PlanIt',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
