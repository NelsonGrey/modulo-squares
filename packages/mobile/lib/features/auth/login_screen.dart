import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Dark background matching the app icon's background colour.
const _kBg = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF4CAF50);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initializeGoogleSignIn = true});

  final bool initializeGoogleSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initializeGoogleSignIn) {
      _initializeGoogleSignIn();
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('Google Sign-In init failed: $e');
    }
  }

  // Shows a dialog with the exact error so nothing is missed.
  void _showAuthError(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    String message;
    if (error is FirebaseAuthException) {
      message = '${error.message ?? error.code}\n\n(code: ${error.code})';
    } else {
      message = error.toString();
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign-in failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = googleUser.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _showAuthError(context, 'No ID token returned from Google.');
        return;
      }

      final GoogleSignInClientAuthorization? authorization =
          await googleUser.authorizationClient.authorizationForScopes([]);

      if (authorization == null) {
        final authorized =
            await googleUser.authorizationClient.authorizeScopes([]);
        await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
              accessToken: authorized.accessToken, idToken: idToken),
        );
      } else {
        await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
              accessToken: authorization.accessToken, idToken: idToken),
        );
      }
    } catch (e) {
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (appleCredential.identityToken == null) {
        _showAuthError(context, 'Apple did not return an identity token.');
        return;
      }
      await FirebaseAuth.instance.signInWithCredential(
        OAuthProvider('apple.com')
            .credential(idToken: appleCredential.identityToken),
      );
    } catch (e) {
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _authenticateWithEmailPassword(
    BuildContext context, {
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    if (_authInProgress) return;

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      _showAuthError(context, 'Email and password are required.');
      return;
    }

    setState(() => _authInProgress = true);
    try {
      if (createAccount) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      }
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _openEmailSignInDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var createAccount = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setLocalState) {
            return AlertDialog(
              title: Text(
                createAccount ? 'Create account' : 'Sign in with email',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (createAccount) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Password must be 8+ characters with uppercase, '
                      'lowercase, a number, and a special character.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setLocalState(() {
                      createAccount = !createAccount;
                    }),
                    child: Text(
                      createAccount
                          ? 'Already have an account? Sign in'
                          : 'Need an account? Create one',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _authInProgress
                      ? null
                      : () => _authenticateWithEmailPassword(
                            dialogContext,
                            email: emailController.text,
                            password: passwordController.text,
                            createAccount: createAccount,
                          ),
                  child: Text(createAccount ? 'Create account' : 'Sign in'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _signInAsGuest(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icons/icon.png',
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Modulo Squares',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The Modular Math Puzzle',
                style: TextStyle(fontSize: 15, color: Colors.white54),
              ),
              const SizedBox(height: 48),
              const Text(
                'Sign in to save progress and compete on the leaderboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 28),
              _AuthButton(
                label: 'Sign in with Google',
                icon: Icons.g_mobiledata,
                onPressed: _authInProgress
                    ? null
                    : () => _signInWithGoogle(context),
              ),
              const SizedBox(height: 12),
              _AuthButton(
                label: 'Sign in with Apple',
                icon: Icons.apple,
                onPressed: _authInProgress
                    ? null
                    : () => _signInWithApple(context),
              ),
              const SizedBox(height: 12),
              _AuthButton(
                label: 'Sign in with Email',
                icon: Icons.email_outlined,
                outlined: true,
                onPressed: _authInProgress
                    ? null
                    : () => _openEmailSignInDialog(context),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                  ),
                  onPressed: _authInProgress
                      ? null
                      : () => _signInAsGuest(context),
                  child: const Text('Continue as Guest'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guest progress is not backed up and may be lost if you uninstall.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white30),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: outlined ? Colors.white70 : Colors.white),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: outlined ? Colors.white70 : Colors.white,
                fontSize: 15)),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onPressed,
              child: content,
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onPressed,
              child: content,
            ),
    );
  }
}
