import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/screens/auth/sign_in_screen.dart';
import 'package:todo_app/screens/dashboard/dashboard_screen.dart';
import 'package:todo_app/services/auth_service.dart';
import 'package:todo_app/theme/app_theme.dart';
import 'package:todo_app/widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, this.initialCooldownSeconds = 0});

  final int initialCooldownSeconds;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  Timer? _cooldownTimer;
  Timer? _verificationPollTimer;
  late int _secondsRemaining;
  bool _isResending = false;
  bool _isChecking = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialCooldownSeconds;
    if (_secondsRemaining > 0) _startCooldown(_secondsRemaining);
    _verificationPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(showFeedback: false),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _verificationPollTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_secondsRemaining > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authService.resendEmailVerification();
      if (!mounted) return;
      _startCooldown(30);
      _showMessage('Verification email sent. Check your inbox.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_firebaseError(error));
    } catch (error) {
      _showMessage('Could not resend the email: $error');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerification({bool showFeedback = true}) async {
    if (_isChecking || _isNavigating) return;
    _isChecking = true;
    if (showFeedback) setState(() {});
    try {
      final user = await _authService.reloadCurrentUser();
      if (!mounted) return;
      if (user == null) {
        if (showFeedback) {
          _showMessage('Your session ended. Please sign in again.');
        }
        _goToSignIn();
      } else if (user.emailVerified) {
        _isNavigating = true;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder<void>(
            pageBuilder: (_, animation, _) => const DashboardScreen(),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
          (_) => false,
        );
      } else if (showFeedback) {
        _showMessage(
          'We have not received verification yet. Check your email and try again.',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (showFeedback) _showMessage(_firebaseError(error));
    } catch (error) {
      if (showFeedback) _showMessage('Could not check verification: $error');
    } finally {
      _isChecking = false;
      if (mounted && showFeedback) setState(() {});
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) _goToSignIn();
  }

  void _goToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? 'your email address';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Sign out',
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.lilac,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppTheme.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We sent a verification link to',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Open the message and follow its link. Then return here to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    label: 'I have verified',
                    isLoading: _isChecking,
                    onPressed: _checkVerification,
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _secondsRemaining > 0 || _isResending
                        ? null
                        : _resendEmail,
                    icon: _isResending
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_unread_outlined),
                    label: Text(
                      _secondsRemaining > 0
                          ? 'Resend email in ${_secondsRemaining}s'
                          : 'Resend verification email',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Check your spam or junk folder if the email does not appear.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _firebaseError(FirebaseAuthException error) => switch (error.code) {
  'too-many-requests' =>
    'Too many attempts. Wait a little before trying again.',
  'network-request-failed' => 'Check your internet connection and try again.',
  'user-disabled' => 'This account has been disabled.',
  _ => error.message ?? 'Firebase could not complete that request.',
};
