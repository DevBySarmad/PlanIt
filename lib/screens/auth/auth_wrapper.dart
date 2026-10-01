import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/screens/auth/email_verification_screen.dart';
import 'package:todo_app/screens/auth/sign_in_screen.dart';
import 'package:todo_app/screens/dashboard/dashboard_screen.dart';
import 'package:todo_app/services/auth_service.dart';
import 'package:todo_app/theme/app_theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  static final _auth = AuthService();

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _auth.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        );
      }
      final user = snapshot.data;
      if (user == null) return const SignInScreen();
      if (!user.emailVerified) return const EmailVerificationScreen();
      return const DashboardScreen();
    },
  );
}
