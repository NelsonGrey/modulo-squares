import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

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
      if (kDebugMode) {
        debugPrint('Google Sign-In initialization failed: $e');
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = googleUser.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        if (context.mounted) {
          ErrorHandler().showErrorSnackBar(
            context,
            'Failed to get authentication tokens',
          );
        }
        return;
      }

      final GoogleSignInClientAuthorization? authorization =
          await googleUser.authorizationClient.authorizationForScopes([]);

      if (authorization == null) {
        final authorized =
            await googleUser.authorizationClient.authorizeScopes([]);
        final credential = GoogleAuthProvider.credential(
          accessToken: authorized.accessToken,
          idToken: idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        final credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e, context),
        );
      }
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
        if (context.mounted) {
          ErrorHandler().showErrorSnackBar(
            context,
            'Apple sign-in failed: no identity token received.',
          );
        }
        return;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
      );
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } catch (e) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e, context),
        );
      }
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
      ErrorHandler().showErrorSnackBar(context, 'Email and password are required.');
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
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e, context),
        );
      }
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
                createAccount ? 'Create account with email' : 'Sign in with email',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e, context),
        );
      }
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/icons/icon.png', width: 88, height: 88),
              const SizedBox(height: 16),
              const Text(
                'Modulo Squares',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'The Modular Math Puzzle',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                'Sign in to save progress and compete on the leaderboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _authInProgress
                      ? null
                      : () => _signInWithGoogle(context),
                  icon: const Icon(Icons.g_mobiledata, size: 22),
                  label: const Text('Sign in with Google'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _authInProgress
                      ? null
                      : () => _signInWithApple(context),
                  icon: const Icon(Icons.apple, size: 22),
                  label: const Text('Sign in with Apple'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _authInProgress
                      ? null
                      : () => _openEmailSignInDialog(context),
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: const Text('Sign in with Email'),
                ),
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _authInProgress
                      ? null
                      : () => _signInAsGuest(context),
                  child: const Text('Continue as Guest'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guest progress is not backed up and may be lost if you uninstall the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
