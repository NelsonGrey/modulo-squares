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
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
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
    }
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
            onPressed: () => _signInWithGoogle(context),
            child: const Text('Sign in with Google'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _signInWithApple(context),
            child: const Text('Sign in with Apple'),
          ),
        ],
      ),
    );
  }
}
