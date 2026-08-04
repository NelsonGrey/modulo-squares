import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show AutofillHints, PlatformException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:modulo_squares/core/auth/apple_sign_in_nonce.dart';

// Dark background matching the app icon's background colour.
const _kBg = Color(0xFF1A1A2E);
const _kAccent = Color(0xFF4CAF50);

// Android's play-services-auth SDK throws IllegalArgumentException
// ("requestedScopes cannot be null or empty") if this list is empty --
// 'email' is enough to obtain the accessToken passed to
// GoogleAuthProvider.credential below.
const _kGoogleAuthScopes = ['email'];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initializeGoogleSignIn = true});

  final bool initializeGoogleSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _authInProgress = false;

  // Populated from the live Firebase password policy (see
  // _loadPasswordPolicy). These defaults match today's enforced policy so
  // the signup dialog is still usable if the fetch fails (e.g. offline);
  // the authoritative check in _authenticateWithEmailPassword() re-verifies
  // against the real policy regardless of whether this fetch succeeded.
  int _policyMinLength = 8;
  bool _policyRequiresUpper = true;
  bool _policyRequiresLower = true;
  bool _policyRequiresDigit = true;
  bool _policyRequiresSymbol = true;

  @override
  void initState() {
    super.initState();
    if (widget.initializeGoogleSignIn &&
        defaultTargetPlatform == TargetPlatform.android) {
      _initializeGoogleSignIn();
    }
    _loadPasswordPolicy();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('Google Sign-In init failed: $e');
    }
  }

  Future<void> _loadPasswordPolicy() async {
    try {
      final status = await FirebaseAuth.instance.validatePassword(
        FirebaseAuth.instance,
        ' ',
      );
      final policy = status.passwordPolicy;
      if (!mounted) return;
      setState(() {
        _policyMinLength = policy.minPasswordLength;
        // A null field means Firebase doesn't enforce that character class
        // for this policy -- default to not-required, or the client would
        // reject passwords the server actually accepts.
        _policyRequiresUpper = policy.containsUppercaseCharacter ?? false;
        _policyRequiresLower = policy.containsLowercaseCharacter ?? false;
        _policyRequiresDigit = policy.containsNumericCharacter ?? false;
        _policyRequiresSymbol =
            policy.containsNonAlphanumericCharacter ?? false;
      });
    } catch (_) {
      // Keep the defaults above -- _authenticateWithEmailPassword() still
      // authoritatively re-checks the real password against the live policy.
    }
  }

  String _passwordRequirementsHint() {
    final requirements = <String>[
      if (_policyRequiresUpper) 'uppercase letter',
      if (_policyRequiresLower) 'lowercase letter',
      if (_policyRequiresDigit) 'number',
      if (_policyRequiresSymbol) 'special character',
    ];
    if (requirements.isEmpty) {
      return 'Password must be $_policyMinLength+ characters.';
    }
    return 'Password must be $_policyMinLength+ characters with '
        '${requirements.join(', ')}.';
  }

  // Quick pass using the cached live policy, so users get immediate
  // feedback without a network round-trip. _authenticateWithEmailPassword()
  // re-validates authoritatively against Firebase itself before submitting,
  // so this never needs to be the last word on whether a password is
  // accepted.
  String? _quickPasswordCheck(String password) {
    if (password.length < _policyMinLength) {
      return 'Password must be at least $_policyMinLength characters.';
    }
    if (_policyRequiresUpper && !password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must include an uppercase letter.';
    }
    if (_policyRequiresLower && !password.contains(RegExp(r'[a-z]'))) {
      return 'Password must include a lowercase letter.';
    }
    if (_policyRequiresDigit && !password.contains(RegExp(r'[0-9]'))) {
      return 'Password must include a number.';
    }
    if (_policyRequiresSymbol && !password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Password must include a special character.';
    }
    return null;
  }

  String _describePasswordPolicyFailure(PasswordValidationStatus status) {
    final missing = <String>[
      if (!status.meetsMinPasswordLength)
        'be at least $_policyMinLength characters',
      if (!status.meetsUppercaseRequirement) 'include an uppercase letter',
      if (!status.meetsLowercaseRequirement) 'include a lowercase letter',
      if (!status.meetsDigitsRequirement) 'include a number',
      if (!status.meetsSymbolsRequirement) 'include a special character',
    ];
    if (missing.isEmpty) {
      return 'Password does not meet the requirements for this account.';
    }
    return 'Password must ${missing.join(', ')}.';
  }

  void _showAuthError(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    // Raw error in debug builds only; friendly message in production.
    String message;
    if (error is String) {
      message = error;
    } else if (kDebugMode) {
      if (error is FirebaseAuthException) {
        message = '${error.message ?? error.code}\n\n(code: ${error.code})';
      } else {
        message = error.toString();
      }
    } else {
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'user-disabled':
            message = 'This account has been disabled. Please contact support.';
          case 'too-many-requests':
            message = 'Too many attempts. Please wait a moment and try again.';
          case 'network-request-failed':
            message = 'No internet connection. Please check your network and try again.';
          default:
            message = 'Sign in failed. Please try again.';
        }
      } else {
        message = 'Sign in failed. Please try again.';
      }
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

      final GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes(_kGoogleAuthScopes);

      if (authorization == null) {
        final authorized = await googleUser.authorizationClient
            .authorizeScopes(_kGoogleAuthScopes);
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
      if (e is PlatformException && e.code == 'sign_in_canceled') { return; }
      _showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    try {
      final rawNonce = generateAppleSignInNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256OfString(rawNonce),
      );
      if (appleCredential.identityToken == null) {
        _showAuthError(context, 'Apple did not return an identity token.');
        return;
      }
      await FirebaseAuth.instance.signInWithCredential(
        OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        ),
      );
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) { return; }
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
        final quickCheckError = _quickPasswordCheck(password);
        if (quickCheckError != null) {
          _showAuthError(context, quickCheckError);
          return;
        }

        // Authoritative check against the live Firebase policy -- catches
        // drift between this dialog's cached copy and the real policy
        // (e.g. it changed after this screen loaded, or the initial fetch
        // failed) before spending a round-trip on account creation.
        final status = await FirebaseAuth.instance.validatePassword(
          FirebaseAuth.instance,
          password,
        );
        if (!status.isValid) {
          _showAuthError(context, _describePasswordPolicyFailure(status));
          return;
        }

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
                    // Android's Autofill Framework hint -- this is also what
                    // Firebase Test Lab / Play Console pre-launch report Robo
                    // crawls use to auto-detect the login field, since a
                    // Flutter TextField has no native Android resource-id for
                    // Robo's "resource name" login-credential setting to
                    // target directly.
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (createAccount) ...[
                    const SizedBox(height: 8),
                    Text(
                      _passwordRequirementsHint(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
              // Google Sign-In is Android-only and Apple Sign-In is iOS-only --
              // no cross-platform sign-in options (Apple doesn't allow signing
              // in with Apple on Android, and there's no reason to offer
              // Google Sign-In to iOS users when Apple's own option covers it).
              if (defaultTargetPlatform == TargetPlatform.android) ...[
                _AuthButton(
                  label: 'Sign in with Google',
                  icon: Icons.g_mobiledata,
                  onPressed: _authInProgress
                      ? null
                      : () => _signInWithGoogle(context),
                ),
                const SizedBox(height: 12),
              ],
              if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                _AuthButton(
                  label: 'Sign in with Apple',
                  icon: Icons.apple,
                  onPressed: _authInProgress
                      ? null
                      : () => _signInWithApple(context),
                ),
                const SizedBox(height: 12),
              ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: outlined ? Colors.white70 : Colors.white),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: outlined ? Colors.white70 : Colors.white,
                  fontSize: 15)),
        ),
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
