import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Dark theme constants mirroring login_screen.dart's _kBg / _kAccent -- kept
// as a local private copy since Dart doesn't allow importing another
// library's private declarations. Keep these in sync with login_screen.dart.
const _kBg = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF4CAF50);

/// Send-only "forgot password" screen: collects an email address and asks
/// Firebase to send a reset link. Firebase's own hosted action-handler page
/// takes over from there once the user taps the link, so there's no
/// new-password entry here.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_sending) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address.';
        _sent = false;
      });
      return;
    }

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      // 'user-not-found' must render the exact same success state as a real
      // account (not just a similarly-worded error) -- if Firebase's own
      // email-enumeration protection is off, showing a *different UI state*
      // (red failure vs. green sent) for unregistered addresses leaks
      // whether an account exists just as much as different wording would.
      if (!kDebugMode && e is FirebaseAuthException && e.code == 'user-not-found') {
        setState(() {
          _sent = true;
          _errorMessage = null;
        });
        return;
      }

      String message;
      if (kDebugMode) {
        if (e is FirebaseAuthException) {
          message = '${e.message ?? e.code}\n\n(code: ${e.code})';
        } else {
          message = e.toString();
        }
      } else if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            message = 'That email address looks invalid.';
          case 'too-many-requests':
            message =
                'Too many attempts. Please wait a moment and try again.';
          case 'network-request-failed':
            message =
                'No internet connection. Please check your network and try again.';
          default:
            // Deliberately generic rather than confirming/denying whether
            // the address is registered (avoids account enumeration).
            message = 'Unable to send reset email. Please try again.';
        }
      } else {
        message = 'Unable to send reset email. Please try again.';
      }
      setState(() {
        _errorMessage = message;
        _sent = false;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Enter the email address for your account and we'll send "
                'you a link to reset your password.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              if (_sent) ...[
                const Text(
                  'If an account exists for that email, a reset link is on '
                  'its way. Check your inbox (and spam folder).',
                  style: TextStyle(color: _kAccent, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _sending ? null : _sendResetEmail,
                child: Text(_sending ? 'Sending...' : 'Send Reset Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
