import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo_squares/core/auth/password_policy_service.dart';

// Dark theme constants mirroring login_screen.dart's _kBg / _kAccent -- kept
// as a local private copy since Dart doesn't allow importing another
// library's private declarations. Keep these in sync with login_screen.dart.
const _kBg = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF4CAF50);

/// Lets a signed-in user with an email/password provider change their
/// password: reauthenticate with the current password, then update to a
/// new one that passes the live Firebase password policy.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordPolicyService = PasswordPolicyService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  PasswordPolicyState _passwordPolicy = const PasswordPolicyState();
  bool _submitting = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadPasswordPolicy();
  }

  Future<void> _loadPasswordPolicy() async {
    final policy = await _passwordPolicyService.loadPolicy();
    if (!mounted) return;
    setState(() => _passwordPolicy = policy);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_submitting) return;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    // Checked before touching FirebaseAuth at all, so this path never
    // depends on Firebase being initialized/reachable.
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Current and new password are required.';
        _success = false;
      });
      return;
    }

    final quickCheckError = _passwordPolicyService.quickCheck(
      newPassword,
      _passwordPolicy,
    );
    if (quickCheckError != null) {
      setState(() {
        _errorMessage = quickCheckError;
        _success = false;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        setState(() {
          _errorMessage = 'No email is associated with this account.';
          _success = false;
        });
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Authoritative check against the live Firebase policy -- catches
      // drift between the cached policy and the real one before spending a
      // round-trip on the update itself.
      final status = await _passwordPolicyService.checkPassword(newPassword);
      if (!status.isValid) {
        setState(() {
          _errorMessage = _passwordPolicyService.describeFailure(
            status,
            _passwordPolicy,
          );
          _success = false;
        });
        return;
      }

      await user.updatePassword(newPassword);
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      setState(() {
        _success = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      String message;
      if (kDebugMode) {
        if (e is FirebaseAuthException) {
          message = '${e.message ?? e.code}\n\n(code: ${e.code})';
        } else {
          message = e.toString();
        }
      } else if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
          case 'invalid-credential':
            message = 'Current password is incorrect.';
          case 'too-many-requests':
            message =
                'Too many attempts. Please wait a moment and try again.';
          case 'network-request-failed':
            message =
                'No internet connection. Please check your network and try again.';
          case 'requires-recent-login':
            message = 'Please sign out and back in, then try again.';
          default:
            message = 'Unable to change password. Please try again.';
        }
      } else {
        message = 'Unable to change password. Please try again.';
      }
      setState(() {
        _errorMessage = message;
        _success = false;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _passwordPolicyService.hint(_passwordPolicy),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              if (_success) ...[
                const Text(
                  'Password changed successfully.',
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
                onPressed: _submitting ? null : _changePassword,
                child: Text(_submitting ? 'Changing...' : 'Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
