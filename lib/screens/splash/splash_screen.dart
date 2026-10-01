import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gradient_animation_text/flutter_gradient_animation_text.dart';
import 'package:todo_app/screens/auth/auth_wrapper.dart';
import 'package:todo_app/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFDAD8E7),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 110),
              child: Image.asset('assets/images/task_logo.png'),
            ),
            GradientAnimationText(
              text: const Text(
                'PlanIt',
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
              colors: const [
                Color(0xFF662D91),
                AppTheme.primary,
                Color(0xDC5A67DC),
                Color(0x60F0F0F3),
                Color(0xFF653CF4),
              ],
              duration: const Duration(seconds: 5),
              transform: GradientRotation(math.pi / 12),
            ),
          ],
        ),
      ),
    ),
  );
}
