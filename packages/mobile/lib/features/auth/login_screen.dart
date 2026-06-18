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
    if (_authInProgress) {
      return;
    }

    setState(() {
      _authInProgress = true;
    });

    try {
      // First authenticate the user
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Get the ID token from authentication
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

      // Then get authorization for the required scopes (empty list for basic profile)
      final GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes([]);

      if (authorization == null) {
        // If not authorized, request authorization
        final auth = await googleUser.authorizationClient.authorizeScopes([]);
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        // Already authorized
        final AuthCredential credential = GoogleAuthProvider.credential(
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
      if (mounted) {
        setState(() {
          _authInProgress = false;
        });
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_authInProgress) {
      return;
    }

    setState(() {
      _authInProgress = true;
    });

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.identityToken == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apple sign-in failed: No identity token'),
            ),
          );
        }
        return;
      }

      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken);
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } catch (e) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e, context),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _authInProgress = false;
        });
      }
    }
  }

  Future<void> _authenticateWithEmailPassword(
    BuildContext context, {
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    if (_authInProgress) {
      return;
    }

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      ErrorHandler().showErrorSnackBar(
        context,
        'Email and password are required.',
      );
      return;
    }

    setState(() {
      _authInProgress = true;
    });

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
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e, context),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _authInProgress = false;
        });
      }
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
                createAccount
                    ? 'Create account with email'
                    : 'Sign in with email',
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
                    onPressed: () {
                      setLocalState(() {
                        createAccount = !createAccount;
                      });
                    },
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
                  onPressed:
                      _authInProgress
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Sign in to continue. An account is required to play and sync progress.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed:
                _authInProgress ? null : () => _signInWithGoogle(context),
            child: const Text('Sign in with Google'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                _authInProgress ? null : () => _openEmailSignInDialog(context),
            child: const Text('Sign in with Email'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _authInProgress ? null : () => _signInWithApple(context),
            child: const Text('Sign in with Apple'),
          ),
        ],
      ),
    );
  }
}
